---
name: unity-scene-building
description: "Recipes and verified quirks for building scenes, scripts, screenshots, textures and EditMode tests in a live Unity Editor through the unity plugin's tools. Load with unity:unity-mcp."
version: 0.2.0
author: gabeparra
license: MIT
metadata:
  tags: "unity, mcp, scenes, screenshots, textures, editmode-tests"
  related_skills: "unity:unity-mcp"
---

# Unity scene building (field notes for unity:unity-mcp)

Verified against MCP for Unity v10.3.0 and Unity 6000.3, driven by Hermes through the plugin. Load
`unity:unity-mcp` first and follow its rules: approvals, excluded and forbidden tools, preflight, one Editor per
project. This skill adds recipes and quirks and never overrides those rules. In particular:

- Make calls one at a time. Do not use `batch_execute`: it hides every command inside it from the user's approval
  prompts and from the exclude list.
- Do not call `generate_image`, `generate_audio`, `generate_model`, `blender_bridge`, `import_model` or
  `manage_tools`. For a texture use `manage_texture` (procedural), or ask the user to supply an image file.
- Do not delete superseded screenshots or assets unprompted. Name the stale file and offer to remove it.

## Procedure

1. **Preflight.** Run the unity-mcp skill's `scripts/preflight.sh <project>`.
   - `GUARD`: stop and tell the user.
   - `BRIDGE`: an Editor with the bridge already has the project. Connect to it.
   - `LOCKED`: someone else holds the project. Leave it alone.
   - Skim the project's README and any AGENTS.md or CLAUDE.md for rules.
2. **Connect.** Read `mcpforunity://instances`, then `set_active_instance` with the `Name@hash` id.
3. **State.** `manage_editor` has no state query: read the `mcpforunity://editor/state` resource. Ready means
   `activity.phase` is `idle`, `is_compiling` is false, and `last_domain_reload_after_unix_ms` is later than
   `last_compile_finished_unix_ms`. In a headless Editor, `advice.ready_for_tools: false` with `stale_status` is
   normal because the heartbeat is slow. Also run `manage_scene get_active` and check the target paths are free.
4. **Script.** `create_script`, `read_console` with action `clear`, `refresh_unity` (`compile: request`,
   `mode: force`), then wait 8 to 10 seconds because the compile is asynchronous. Re-read the state, then
   `read_console` for errors and warnings. If the Editor writes a log file, `grep -E "error CS" <log>` is a
   second check. A component can only be added after the compile and domain reload finish.
5. **Scene.** `manage_scene create` (name plus a folder path; the folder is created), then add objects one call at
   a time. A worked example is in `references/starter-scene.md`.
6. **Verify each step.** Read values back with the resource
   `mcpforunity://scene/gameobject/<instanceID>/component/<Type>`. A failed key fails only that key.
7. **Save**, then **screenshot** with the scene camera and `capture_source: game_view`. Look at the image yourself
   before reporting it, and check its alpha (see Pitfalls).
8. **Report** in plain text: files created (absolute paths), console errors versus package warnings, git status,
   and what was not verified (for example motion without play mode).

## EditMode tests (verified: 4 of 4 passed, Test Framework 1.6.0)

1. Check `Packages/packages-lock.json` for `com.unity.test-framework`. MCP for Unity pulls it in, so do not
   install it again.
2. `Update()` does not tick in EditMode and `Time.deltaTime` means nothing there. Move the behaviour into a public
   method that takes the delta, have `Update()` call it, and test that method.
3. Test assemblies cannot reference `Assembly-CSharp`. Give the runtime scripts their own asmdef
   (`autoReferenced: true`), then add an Editor-only test asmdef that references it plus `UnityEngine.TestRunner`
   and `UnityEditor.TestRunner`, with `overrideReferences: true`, `precompiledReferences: ["nunit.framework.dll"]`
   and `defineConstraints: ["UNITY_INCLUDE_TESTS"]`. Unity creates the `.meta` files. Scene components keep
   working because the script GUID does not change.
4. Clear the console, run `refresh_unity`, wait about 10 seconds, then check `Library/ScriptAssemblies/` for both
   DLLs and the console for errors.
5. Call `run_tests` (mode EditMode, `assembly_names` set to the test asmdef, `include_details: true`), then
   `get_test_job` with `wait_timeout: 60`. Report total, passed, failed and skipped counts. Never run PlayMode
   tests on Linux (upstream hang).
6. Afterwards check the hierarchy has no leftover test objects and `get_active` reports `isDirty: false`. The runner
   restores the open scene, so instance IDs change: look objects up again before reusing an ID.

## Pitfalls

- **Colors** for `set_property` must be objects, `{"r":..,"g":..,"b":..,"a":..}`. An array fails with "not an
  object". Enums take their names as strings (`"Directional"`, `"SolidColor"`).
- **Transparent screenshots** happen when the camera keeps its default skybox clear. Use clear flags `SolidColor`
  with an opaque dark `backgroundColor` and the alpha comes out 255. Otherwise composite onto a dark background
  before judging the image.
- **A flat white object with no face shading** is a lighting problem, not a broken material or pipeline. Aim the
  light so at least one visible face is in shade, intensity about 1.
- **Screenshot names are not guaranteed.** A repeat capture with the same file name came back timestamped. Report
  the `path` the tool returned and say which file is final.
- **Warnings that start with `MCP-FOR-UNITY` come from the package, not the project** (for example the batch-mode
  screenshot fallback and a transform serializer error). List them separately and do not try to fix them.
- **An Edit-mode screenshot does not prove a script runs.** Offer play mode (save first) and do not claim motion
  you did not observe.
- **Texture recipe (built-in render pipeline):** `manage_texture create` takes a pattern, a `palette`
  (`[[r,g,b,a],...]`, 0 to 255) and `pattern_size`, and creates its folder. `set_import_settings` needs
  snake_case keys (`filter_mode`, `wrap_mode`); camelCase is silently dropped. `manage_material create` fails with
  "Creating asset ... failed" if the folder is missing, so run `manage_asset` with action `create_folder` first.
  Then `set_material_shader_property` (`_MainTex`, the asset path) and `assign_material_to_renderer` (target id,
  `search_method: by_id`, mode `shared`).
- **Headless Editor housekeeping:** one started with the stdio bridge ignores SIGTERM (use KILL), and its
  AssetImportWorker processes can outlive it.

## References

- `references/starter-scene.md`: a primitive, a script, a light and a camera, built one call at a time, with
  lighting values that read well.
