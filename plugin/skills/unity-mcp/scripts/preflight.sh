#!/usr/bin/env bash
# Preflight for a Unity project before driving it with the unity MCP tools.
# Usage: preflight.sh /path/to/UnityProject   (the folder that holds Assets/ and ProjectSettings/)
# Read-only. Exit 0 = safe to open, 1 = do not open, 2 = usage error, 3 = a user guard flag is up (stop and wait).
set -u
P="${1:-}"
[ -d "$P/Assets" ] && [ -f "$P/ProjectSettings/ProjectVersion.txt" ] || { echo "usage: preflight.sh <UnityProject>"; exit 2; }
P="$(cd "$P" && pwd)"
bad=0
# User-defined "do not use the GPU / do not start heavy work" flag files (for example a gaming guard).
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
holders="$(pgrep -ax Unity | grep -F -- "$P" | cut -c1-120)"
if [ -n "$holders" ]; then echo "LOCKED:   another Unity process uses this project:"; echo "$holders"; bad=1; fi
[ -f "$P/Temp/UnityLockfile" ] && ! [ -n "$holders" ] && echo "note:     Temp/UnityLockfile exists but no process holds it (stale after a crash)"

# Is the bridge package present?
if grep -q 'unity-mcp' "$P/Packages/manifest.json" 2>/dev/null; then
  echo "bridge:   MCP for Unity present in manifest"
else
  echo "bridge:   MISSING (add the pinned package from PINS.md first)"; bad=1
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
