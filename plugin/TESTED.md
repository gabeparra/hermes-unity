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

Not yet tested: install into Hermes itself (plugin loading, tool approval flow), play mode, builds.
