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

## Rules

1. Never edit `.unity`, `.prefab` or `.meta` files with file tools, and never run `Unity -batchmode` on a project
   that is open. The Editor holds the live scene and overwrites files written behind its back. `.cs` files go
   through `manage_script` / `script_apply_edits`.
2. Do not install packages (`manage_packages`), run `execute_code` or `execute_menu_item`, or delete assets
   unless the user asked for it. Say what you are about to run first.
3. Do not run PlayMode tests (`run_tests` mode PlayMode) on Linux: upstream issue #1390 hangs the Editor.
   EditMode tests are fine.
4. Save the scene (`manage_scene` save) before entering play mode, so a crash loses nothing.

## Before anything

1. Call `set_active_instance` if more than one Editor is open; pick the project the user named.
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
6. Builds go through `manage_build`. Confirm the target and output folder with the user first.

## Habits

- Batch related steps with `batch_execute` to cut round trips; stop at the first error.
- Pass numbers as quoted strings if a tool rejects them.
- When something fails twice, stop and report the exact error text instead of retrying variations.
- Report only what the tools returned. If a screenshot or console read failed, say so.
