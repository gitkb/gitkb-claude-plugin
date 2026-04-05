#!/usr/bin/env bash
# Shared functions for GitKB hook scripts.

# Resolve CWD from hook JSON input. Returns empty and exits if invalid.
# Usage: CWD=$(resolve_cwd "$INPUT") || exit 0
resolve_cwd() {
  local raw
  raw=$(echo "$1" | jq -r '.cwd // empty')
  [ -z "$raw" ] && return 1
  # Resolve to absolute path to prevent infinite dirname loops on relative paths
  local resolved
  resolved=$(cd "$raw" 2>/dev/null && pwd) || return 1
  echo "$resolved"
}

# Walk up from a directory to find the nearest .kb/ root.
# Honors GITKB_ROOT env var override (empty = no KB).
# Usage: KB_ROOT=$(find_kb_root "$CWD") || exit 0
find_kb_root() {
  # If GITKB_ROOT is explicitly set, trust it (empty = no KB)
  if [ "${GITKB_ROOT+set}" = "set" ]; then
    if [ -n "$GITKB_ROOT" ] && [ -d "$GITKB_ROOT/.kb" ]; then
      echo "$GITKB_ROOT"
      return 0
    fi
    return 1
  fi
  local dir="$1"
  local prev=""
  while [ "$dir" != "/" ] && [ "$dir" != "$prev" ]; do
    [ -d "$dir/.kb" ] && echo "$dir" && return 0
    prev="$dir"
    dir=$(dirname "$dir")
  done
  return 1
}
