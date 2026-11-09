# hermes-unity

A [Hermes](https://hermes-agent.nousresearch.com) plugin that lets Hermes work in the Unity 6 Editor: create
scenes and GameObjects, add components, write and edit C# scripts, read the console and compile errors, enter and
leave play mode, take screenshots and make builds.

It does not contain a Unity bridge of its own. It runs [MCP for Unity](https://github.com/CoplayDev/unity-mcp)
(MIT, by CoplayDev, pinned to v10.3.0) as an MCP server and adds a skill that tells Hermes how to use it without
making a mess. This project is not affiliated with Unity Technologies or CoplayDev.

## Status

Tested on Linux with Unity 6000.3 and a headless Editor: the server starts from this plugin's config, a script
with a compile error is reported with file and line, gets fixed, and a scene with a cube and a screenshot comes
out the other end. The results are in [plugin/TESTED.md](plugin/TESTED.md).

Not tested: macOS and Windows, the Editor with a visible window, PlayMode tests (upstream reports a hang on
Linux/Vulkan, [issue 1390](https://github.com/CoplayDev/unity-mcp/issues/1390)), and player builds.

## Requirements

- Hermes (tested on 0.23.0)
- [uv](https://docs.astral.sh/uv/), which fetches the pinned Python server on first use
- git
- Unity 6 (tested on 6000.3.27f2). MCP for Unity itself supports 2021.3 and newer, but only Unity 6 was tried here.

## Install

1. Install the plugin. Portable plugins install disabled, so enable it after:

   ```
   hermes plugins install "gabeparra/hermes-unity#plugin"
   hermes plugins enable unity
   ```

   To pin an exact commit, add `--ref <40-character commit SHA>`.

2. Add the Unity side to your project. In Unity, open Window > Package Manager > Add package from git URL and
   use the commit-pinned URL from [plugin/PINS.md](plugin/PINS.md):

   ```
   https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#aa5fc638d623f56178d50329d9ad8c541a57fe66
   ```

3. Start the bridge so the Editor listens on 127.0.0.1:6400 over stdio. The reliable way I found is a headless
   Editor, which does not touch your saved Unity preferences:

   ```
   UNITY_MCP_ALLOW_BATCH=1 Unity -batchmode -projectPath <your project> \
       -executeMethod MCPForUnity.Editor.McpCiBoot.StartStdioForCi
   ```

   With a normal window, the MCP for Unity package has its own window where you choose the transport. This
   plugin's `mcp.json` uses stdio, so turn the HTTP option off there and start the bridge. I have not tried that
   path myself.

4. Ask Hermes for something small, for example: "Make a new scene with a cube that spins, check the console for
   errors, and take a screenshot."

## Safety model

This plugin makes an AI agent run code inside your Editor, so it is built to ask first.

- **Untrusted server.** `plugin.json` declares the server as `untrusted`. Hermes asks before every tool call
  that is not marked read-only, with the choice of once, for the session or always, per tool. Upstream marks
  only a handful of tools as read-only, so even `read_console` will ask until you say "always".
- **Pinned.** The server is `mcpforunityserver==10.3.0`, started through `uvx` with isolated, no-config,
  no-sources flags and an `--exclude-newer` date, so its dependencies are frozen to what existed on that date.
  The Unity package is pinned by commit. The release's tag commit and wheel hashes are in
  [plugin/PINS.md](plugin/PINS.md); they are recorded for checking by hand, not enforced by the config.
- **Telemetry off.** Both telemetry environment variables are set to true.
- **Local only, no password.** The bridge listens on 127.0.0.1. It has no authentication, so any program on your
  machine can use it while the Editor is open, and its tools run arbitrary C# with your privileges. Close the
  Editor when you are not using it.
- **Paid and external tools.** The server also offers tools that can reach paid providers or marketplaces
  (`generate_image`, `generate_audio`, `generate_model`, `blender_bridge`, `import_model`), and `manage_tools`
  can switch tool groups on. The skill tells the agent never to call them, but that is only text. A portable
  plugin cannot filter tools, so if you want them gone, define the server yourself in Hermes' `config.yaml`
  (this replaces the plugin's entry). Copy `command`, `args` and `env` from [plugin/mcp.json](plugin/mcp.json),
  replace `${PLUGIN_DATA}` with a real directory, and add:

  ```yaml
  mcp_servers:
    unity:
      # command, args, env: copied from plugin/mcp.json
      trust: untrusted
      tools:
        exclude: [generate_image, generate_audio, generate_model, blender_bridge, import_model, manage_tools]
  ```

  When you bump the pinned version, update both places.
- **Guard flag (optional).** `plugin/skills/unity-mcp/scripts/preflight.sh` stops the agent when a flag file you
  list in `~/.config/hermes-unity/guard-files` exists, for example a file your system creates while a game has
  the GPU. It also refuses to open a project another Editor already holds.

## What the skill covers

The skill in `plugin/skills/unity-mcp/` tells Hermes to:

- run the preflight check before touching a project, and work in a clone if the project is in use elsewhere
- read the project's own docs and use its own scripts for tests and builds
- never edit scene, prefab or meta files by hand while the Editor is open
- write a script, wait for the compile, read the console and fix errors before building the scene
- add a light and aim the camera before judging a screenshot (screenshots have a transparent background)
- use EditMode tests as the check, and skip PlayMode tests on Linux for now

It also lists the quirks I hit in testing, such as `apply_text_edits` needing a hash from a first call.

## Layout

```
plugin/                     the Hermes plugin (this is what gets installed)
  plugin.json               manifest, including the untrusted-server declaration
  mcp.json                  how the pinned server is started
  PINS.md                   what is pinned and how to bump it
  TESTED.md                 what was run and what passed
  skills/unity-mcp/         the workflow skill and scripts/preflight.sh
RESEARCH.md                 why MCP for Unity, compared with three other options
```

## License

MIT, see [LICENSE](LICENSE). MCP for Unity is MIT licensed and belongs to its authors.
