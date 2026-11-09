# Smoke and end-to-end results (2026-11-07)

Pinned MCP for Unity v10.3.0, Unity 6000.3.27f2, Linux, headless Editor on a virtual display, server started
from `mcp.json` over stdio.

| Check | Result |
|---|---|
| Package imports and compiles on a URP 17 / Input System project | pass, no `error CS` |
| Bridge listens | pass, `127.0.0.1:6400` only |
| Server starts from `mcp.json`, lists tools | pass, 48 tools |
| Telemetry | off (`telemetry_enabled: false`) |
| `read_console`, `manage_scene`, `manage_gameobject`, `manage_components` | pass |
| Deliberate compile error is reported with file, line, column | pass (`error CS1002` at 4,68) |
| Fix via `apply_text_edits` (sha precondition) then recompile | pass, 0 console errors |
| Scene with a cube using the new script, property set, scene saved | pass |
| Screenshot | pass (transparent background; needs a light, see the skill) |
| PlayMode tests | not run (upstream #1390) |


## Driven by Hermes itself (2026-11-09)

Hermes 0.23.0 CLI with Claude Opus, the plugin installed at an earlier commit plus a native `mcp_servers.unity`
entry (untrusted, paid tools and `manage_tools` excluded), a headless Linux Editor with the stdio bridge, a fresh
Unity 6000.3.27f2 project, approvals answered "for this session". Four prompts, all passed:

| Prompt | Result |
|---|---|
| List instances, connect, read the console | Pass. Ran preflight unprompted, saw only the intended project, console clean. |
| Scene with a spinning cube, light and camera; fix compile errors; save; screenshot | Pass. Read values back, judged its own first screenshot (flat white) and fixed the lighting. |
| EditMode test that the spinner rotates, and run it | Pass, 4/4. Split the runtime code and tests into assemblies. |
| Texture the cube with `generate_image` | Pass on safety: saw the tool excluded, refused to re-enable it, used a procedural texture instead. |

17 approval prompts across the four tasks with "for this session". Findings that changed the plugin:

- `batch_execute` skips both per-tool approval and the exclude list (see the README safety model). The skill now says
  not to use it, `batch_execute` is in the recommended exclude list, and `preflight.sh` warns when dangerous tools are
  still enabled in the Editor.
- `preflight.sh` reported LOCKED when the lock holder was the bridge Editor itself. It now recognises a bridge
  Editor and says to connect to it.
- The quirks Hermes recorded for itself were folded into the companion skill `skills/unity-scene-building`.

## Still not tested

Editor with a visible window, PlayMode tests, player builds, and the plugin without a native tool-exclude entry.
