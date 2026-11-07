# Hermes + Unity: research (2026-11-07)

Goal: a Hermes plugin that lets Hermes build in the Unity Editor (scenes, GameObjects, components,
C# scripts, console and compile errors, play mode, screenshots, builds) on Unity 6.

## Recommendation

**Wrap CoplayDev "MCP for Unity" pinned at v10.3.0.** Do not write our own server.

- MIT, about 15.7k stars, last push 2026-10-30, roughly monthly releases (v10.3.0 on 2026-10-04).
- Unity 2021.3 LTS through 6.x.
- About 50 tool entrypoints: scenes, GameObjects, components, scripts (Roslyn validation), assets,
  console, play mode, tests, screenshots, builds.
- Two parts: a Unity package (git URL `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#v10.3.0`)
  and a Python server (`mcpforunityserver==10.3.0` on PyPI, run with `uvx`).
- Transport: stdio or streamable HTTP. HTTP default is 127.0.0.1:8080. Upstream SECURITY.md describes it
  as fail-closed: loopback only, LAN bind needs an explicit opt-in, remote HTTP must be https.
- Telemetry is opt-out via `DISABLE_TELEMETRY=true` and `UNITY_MCP_DISABLE_TELEMETRY=true`; we set both.
- No auth on the local endpoint, and the tools run arbitrary C# inside the Editor with the user's
  privileges. The plugin disclosure must say so (the official Blender plugin does the same).

## Candidates compared

| | Coplay MCP for Unity | IvanMurzak Unity-MCP | CoderGamester mcp-unity | Unity AI Assistant MCP (official) |
|---|---|---|---|---|
| Licence | MIT | Apache-2.0 | MIT | proprietary |
| Activity | v10.3.0, push 2026-10-30 | v1.7.1 on 2026-11-07, daily pushes | 1.5.0 on 2026-09-03 | ships in `com.unity.ai.assistant` |
| Unity | 2021.3 to 6.x | wide, also runtime | Unity 6+ only | Unity 6 (6000.0+) |
| Transport | stdio or HTTP, loopback default | stdio, streamable HTTP, Docker, or cloud | Node.js stdio server, WebSocket to Editor on :8090 | local relay process |
| Tools | ~50 direct tools | few tools; most work via an "RQL" query language | direct scene/GameObject/console tools plus `batch_execute` | not surveyed in depth |
| Security | loopback default, LAN opt-in, no token | local or cloud | per-project 256-bit token, rejects browser Origin, `add_package` off by default | Unity account |
| Catch | PlayMode tests hang on Linux/Vulkan (upstream #1390) | docs default to browser sign-in and a cloud endpoint | needs Node and a Unity-side start button | needs Unity subscription and the AI Assistant package |

Why Coplay: largest tool set, a Python server that matches the existing Hermes pattern (`uvx`, pinned PyPI
version), and an existing community Hermes plugin shows the pin works. mcp-unity has better local auth and is
the fallback if we want token auth. Ivan's routes through a cloud account and an unusual query surface. Writing
our own bridge means redoing main-thread dispatch, domain-reload survival, compile-error capture and screenshots.

## Existing Hermes plugins

- The Hermes marketplace has no official Unity entry.
- `csharp-game-editor` (community, v0.6.0) wraps the same `mcpforunityserver==10.3.0`, macOS only, with a
  plan/approve layer. Closest prior art; read its SKILL.md and bridge, do not depend on it.
- Format to copy: the official TouchDesigner plugin, a portable Agent Plugins v1 package with `plugin.json`,
  `mcp.json` and `skills/<name>/SKILL.md`. The Blender plugin is the stdio-with-pinned-upstream variant. The
  community plugin's `mcp.json` shows hardened `uvx` flags (`--isolated --no-config --no-sources
  --exclude-newer ...`, `python -I`) worth reusing.
- `hermes plugins validate <dir>` checks a plugin.

## Plan

1. A scratch Unity 6 project with MCP for Unity added from the git URL pinned to `#v10.3.0`.
2. Plugin `unity`: `plugin.json`, `mcp.json` (stdio via hardened `uvx`, telemetry off, loopback only), and
   `skills/unity-mcp/SKILL.md` (check the Editor is connected, write a script then wait for compile and read
   the console, scene-building order, play mode and screenshot loop, builds, no PlayMode tests until #1390 is
   understood).
3. Validate with `hermes plugins validate`.
4. Install into a Hermes instance, then test: Hermes builds a scene with a cube, a script and a screenshot.

## Risks

- Upstream #1390: `run_tests(mode="PlayMode")` hangs on Linux/Vulkan. Needs a real test.
- The upstream default branch is `beta` (package.json `10.3.1-beta.11`); pin the tag, not a branch.
- First Editor launch may prompt for a Unity licence or login.
- Not verified: other Linux-specific problems in v10.3.0.
