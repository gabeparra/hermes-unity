#!/usr/bin/env bash
# Preflight for a Unity project before driving it with the unity MCP tools.
# Usage: preflight.sh /path/to/UnityProject   (the folder that holds Assets/ and ProjectSettings/)
# Read-only. Exit 0 = safe to open (or an Editor with the bridge is already running: connect), 1 = do not open, 2 = usage error, 3 = a user guard flag is up (stop and wait).
set -u
P="${1:-}"
[ -d "$P/Assets" ] && [ -f "$P/ProjectSettings/ProjectVersion.txt" ] || { echo "usage: preflight.sh <UnityProject>"; exit 2; }
P="$(cd "$P" && pwd)"
bad=0
# User-defined "do not use the GPU / do not start heavy work" flag files (for example a flag set while a game is running).
# One path per line in ${XDG_CONFIG_HOME:-~/.config}/hermes-unity/guard-files, or colon-separated in UNITY_MCP_GUARD_FILES.
guards="${UNITY_MCP_GUARD_FILES:-}"
gf="${XDG_CONFIG_HOME:-$HOME/.config}/hermes-unity/guard-files"
[ -r "$gf" ] && guards="$guards:$(grep -v '^#' "$gf" | tr '\n' ':')"
IFS=: read -ra _g <<< "$guards"
for f in "${_g[@]}"; do
  [ -n "$f" ] && [ -e "$f" ] && { echo "GUARD:    $f exists: the user has asked for no heavy work right now. Do not start an Editor or drive Unity; tell the user and wait."; exit 3; }
done
ver="$(sed -n 's/^m_EditorVersion: //p' "$P/ProjectSettings/ProjectVersion.txt")"
echo "project:  $P"
echo "unity:    $ver"
for root in "$HOME/Unity/Hub/Editor" "/opt/unity/Editor"; do
  [ -x "$root/$ver/Editor/Unity" ] && { echo "editor:   $root/$ver/Editor/Unity"; found=1; }
done
[ "${found:-0}" = 1 ] || { echo "editor:   NOT INSTALLED for $ver"; bad=1; }

# Another Editor (or batchmode build) already holding this project?
holders_full="$(pgrep -ax Unity | grep -F -- "$P")"
holders="$(printf '%s\n' "$holders_full" | cut -c1-120)"
# An Editor that is running the MCP bridge for this project is the one to drive, not a conflict. Recognise it by
# the bridge start-up method on its command line, or by a recent status file for this project.
bridge_editor=0
if [ -n "$holders_full" ]; then
  if printf '%s' "$holders_full" | grep -q 'McpCiBoot.StartStdioForCi'; then bridge_editor=1; fi
  for d in "${UNITY_MCP_STATUS_DIR:-}" "$HOME/.unity-mcp"; do
    [ -n "$d" ] && [ -d "$d" ] && find "$d" -name 'unity-mcp-status-*.json' -mmin -10 2>/dev/null | while read -r f; do grep -q -F "\"$P/Assets\"" "$f" && echo hit; done | grep -q hit && bridge_editor=1
  done
fi
if [ "$bridge_editor" = 1 ]; then
  echo "BRIDGE:   an Editor with the MCP bridge already has this project open. Connect to it (read mcpforunity://instances); do not start another."
elif [ -n "$holders_full" ]; then
  echo "LOCKED:   another Unity process uses this project (not a bridge Editor):"; echo "$holders"; bad=1
fi
[ -f "$P/Temp/UnityLockfile" ] && ! [ -n "$holders" ] && echo "note:     Temp/UnityLockfile exists but no process holds it (stale after a crash)"

# Is the bridge package present?
if grep -q 'unity-mcp' "$P/Packages/manifest.json" 2>/dev/null; then
  echo "bridge:   MCP for Unity present in manifest"
else
  echo "bridge:   MISSING (add the pinned package from PINS.md first)"; bad=1
fi

# Dangerous tools still switched on in the Editor's saved settings? Hermes approves and filters only the outer
# batch_execute call; the Editor's own switch (Window > MCP for Unity > Tools) is the only one that holds inside a batch.
prefs="${XDG_DATA_HOME:-$HOME/.local/share}/unity3d/prefs"
if [ -r "$prefs" ]; then
  on=""
  for t in execute_code execute_menu_item manage_packages generate_image generate_audio generate_model import_model blender_bridge manage_tools; do
    v="$(grep -o "name=\"MCPForUnity.ToolEnabled.$t\" type=\"int\">[0-9]*" "$prefs" | sed 's/.*>//' | head -1)"
    [ "$v" = 0 ] || on="$on $t"
  done
  [ -n "$on" ] && echo "WARN:     not switched off in the Editor's saved tool settings:$on. A batch_execute call can still reach them. Disable them in Window > MCP for Unity > Tools (saved per user, all projects), and do not use batch_execute."
fi

# Version control state
if git -C "$P" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "git:      $(git -C "$P" rev-parse --abbrev-ref HEAD), $(git -C "$P" status --porcelain | wc -l) uncommitted paths"
fi
for f in STOP HALT PAUSE; do
  top="$(git -C "$P" rev-parse --show-toplevel 2>/dev/null || echo "$P")"
  [ -e "$top/$f" ] && echo "note:     $top/$f exists (a supervisor stop file; do not start work that fights it)"
done
exit $bad
