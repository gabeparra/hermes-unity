---
name: unity-mcp
description: "Build in a live Unity Editor through the MCP for Unity tools: scenes, GameObjects, components, C# scripts, console and compile errors, play mode, screenshots, builds."
version: 0.1.0
author: gabeparra
license: MIT
metadata:
  tags: "unity, unity6, gamedev, csharp, mcp, editor"
---

# Unity Editor (MCP for Unity)

The tools drive a **running Unity Editor**. They execute C# and edit assets with the user's privileges, and the
local endpoint has no password. Only act on the project the user named.

## Approvals

This plugin asks to run in `untrusted` mode: Hermes asks the user before each write-capable tool, per tool. Do not
try to avoid a prompt, batch around it or reword a request to get past it. A tool the user has set to "always"
is theirs to decide. `read_console`, `find_gameobjects` and `manage_editor` are not marked read-only upstream, so
they ask too.

## Rules

1. Never edit `.unity`, `.prefab` or `.meta` files with file tools, and never run `Unity -batchmode` on a project
   that is open. The Editor holds the live scene and overwrites files written behind its back. `.cs` files go
   through `manage_script` / `script_apply_edits`.
2. Do not install packages (`manage_packages`), run `execute_code` or `execute_menu_item`, or delete assets
   unless the user asked for it. Say what you are about to run first.
   **Never call `generate_image`, `generate_audio`, `generate_model` or `blender_bridge`, `import_model`** (Sketchfab, bring-your-own key): they can call paid
   providers or other apps. Ask first.
3. Do not run PlayMode tests (`run_tests` mode PlayMode) on Linux: upstream issue #1390 hangs the Editor.
   EditMode tests are fine.
4. Save the scene (`manage_scene` save) before entering play mode, so a crash loses nothing.

## Shared and live projects

- **One Editor per project.** Unity locks a project to a single Editor, and other agents may be running batchmode
  builds or tests on it. Run `scripts/preflight.sh <project>` first. If it reports LOCKED, or the project is
  someone else's live branch, do **not** open it: work in a separate clone or worktree and hand changes back as a
  branch or patch.
- **Read the project's own docs first** (CLAUDE.md, AGENTS.md, README, HANDOFF, CONTEXT or similar) and follow them.
  Where they name scripts for gates, builds, tests or clips, use those scripts. Do not reinvent them with
  `execute_code`.
- **Project profile.** If a skill named `unity-project-<project name>` (the repo or game name, not the generic folder name) exists, load it. It holds that
  project's layout, conventions, gates and no-go areas, and it wins over the generic habits here.
- Respect stop files (`STOP`, `HALT`) and any supervisor rules the project documents.
- Large, mostly-ignored art folders are not in git. Do not commit binaries unless the project says to.

## Before anything

0. **Guard flag.** Run `scripts/preflight.sh <project>` first. If it prints `GUARD` (exit 3), a flag the user set up
   (for example a game that has the GPU) is up: do not start an Editor, do not drive Unity, tell the user and wait.
   Hermes can still answer questions meanwhile. Never delete or ignore a guard flag.

1. Call `set_active_instance` if more than one Editor is open. It needs the `Name@hash` form, not just the name:
   read the `mcpforunity://instances` resource first. Only one Editor open means you can skip this.
2. Call `manage_editor` for editor state. If it says compiling or in play mode, wait or stop play first.
3. Call `read_console` (errors only) to see the starting state.

## Loop

1. Write or change a script with `manage_script` or `script_apply_edits`, then call `refresh_unity`.
2. **Wait for the compile to finish**, then `read_console` for errors. Fix every `error CS` before touching
   the scene. A script that does not compile cannot be added as a component.
3. Build the scene: `manage_scene`, `manage_gameobject`, `manage_components`, `manage_material`,
   `manage_prefabs`. Use `find_gameobjects` instead of guessing names, and read values back after setting them.
4. Check with a screenshot (`manage_camera`) and the console.
5. Enter play mode with `manage_editor`, wait, read the console, take a screenshot, leave play mode.
6. Builds go through `manage_build`, or the project's own build script if it has one. Confirm the target and
   output folder with the user first.
7. Prefer EditMode tests (`run_tests`, mode EditMode) as the check after a change. Report counts, not just "passed".

## Habits

- Batch related steps with `batch_execute` to cut round trips; stop at the first error.
- Pass numbers as quoted strings if a tool rejects them.
- When something fails twice, stop and report the exact error text instead of retrying variations.
- Report only what the tools returned. If a screenshot or console read failed, say so.

## Tool quirks (tested against v10.3.0 on Unity 6000.3)

- `create_script` fails if the file exists ("Use 'update'"). To change a script use `apply_text_edits`: it is a
  **two-step call**. The first call returns `precondition_required` with `current_sha256`; repeat the same edit
  with `precondition_sha256` set to it. Lines and columns are 1-indexed, taken from the compiler error
  (`File.cs(4,68)`).
- After any script change, `refresh_unity` with `compile: request` and `wait_for_ready: true`, then wait a few
  seconds more (domain reload) before calling tools. Adding a component whose script has not compiled fails with
  "Component type not found"; that means read the console, not retry.
- `read_console` returns compile errors with file, line and column. Clear it (`action: clear`) before a run so
  old errors do not confuse you.
- Screenshots (`manage_camera`, action `screenshot`) are RGBA and the background is **transparent**, so a viewer
  shows an empty white image. Add a Directional Light, give the camera an opaque background, and pass
  `view_target` (an object name) so the camera aims at what you built. Composite onto a dark background before
  judging an image. In batchmode `capture_source: scene_view` is unsupported; use `game_view`.
- A new scene has no light and no camera: create both.

## Starting an Editor for the bridge (headless)

The bridge does not start by itself in batchmode and defaults to HTTP. To run an Editor you can drive without
touching the user's saved Unity preferences, start it with:

    UNITY_MCP_ALLOW_BATCH=1 Unity -batchmode -projectPath <project> \
        -executeMethod MCPForUnity.Editor.McpCiBoot.StartStdioForCi

That pins stdio for the session only and listens on 127.0.0.1:6400. Set `UNITY_MCP_STATUS_DIR` (the same value
for the Editor and the server) to keep its status file out of the shared `~/.unity-mcp`. Stop it with SIGTERM
and wait for the process to exit before starting another on the same project.
