# Pinned upstream

| What | Pin |
|---|---|
| Upstream | CoplayDev/unity-mcp (MIT) |
| Release | v10.3.0 (2026-10-04) |
| Tag commit | `aa5fc638d623f56178d50329d9ad8c541a57fe66` |
| Unity package URL | `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#aa5fc638d623f56178d50329d9ad8c541a57fe66` |
| PyPI | `mcpforunityserver==10.3.0` |
| Wheel sha256 | `89d8cc1227f7ed253e36e817880cf521799c27d4b83f61d159e1776a04a6f6c7` |
| sdist sha256 | `3e580e682698d1727f292f851c492729f8cc337c8b569451d1114a0de1330cf6` |
| Transitive deps | frozen by `--exclude-newer 2026-10-05T00:00:00Z` in `mcp.json` |

Checked 2026-11-07: no GitHub security advisories, no PyPI vulnerabilities for 10.3.0, v10.3.0 is the latest
stable release. Known gaps: the Unity package is unsigned (upstream #867), PlayMode tests hang on Linux/Vulkan
(upstream #1390), and the local endpoint has no authentication.

To bump: change the version, tag commit, hashes and `--exclude-newer` date together, then re-run the smoke test.
If the Hermes host keeps a native `mcp_servers.unity` entry in its `config.yaml` (to exclude tools, see below), that
entry replaces this package's server entry, so update its `uvx` args (`mcpforunityserver==...`, `--exclude-newer`)
there too.

## Paid and out-of-scope tools

In the 10.3.0 smoke run the server listed 48 tools including `generate_image`, `generate_audio`, `generate_model`
and `blender_bridge` (the `asset_gen` group was enabled), and `manage_tools` can switch groups. A portable plugin
cannot filter tools, so a host that must never reach paid providers should use a native `mcp_servers.unity` entry
with `tools.exclude: [generate_image, generate_audio, generate_model, blender_bridge, import_model, manage_tools]`.
`plugin.json` sets the server to `untrusted`, so every write-capable tool also asks first.
