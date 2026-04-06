#!/usr/bin/env bash
# Shared functions for GitKB hook scripts.

# Check if a hook feature is enabled via .kb/config.toml.
# Returns 0 (enabled) or 1 (disabled).
# When the key is missing from config, falls back to the provided default.
#
# Usage: hook_enabled "$KB_ROOT" "context_injection" "true" || exit 0
hook_enabled() {
  local kb_root="$1" key="$2" default="${3:-true}"
  local val
  val=$(GITKB_ROOT="$kb_root" git kb config get "hooks.$key" 2>/dev/null) || val="$default"
  [ "$val" = "true" ]
}

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

# Detect which repo CWD is in by matching against git kb repo list.
# Falls back to git remote name for single-repo KBs.
# Usage: REPO=$(detect_repo "$KB_ROOT" "$CWD")
detect_repo() {
  local kb_root="$1" cwd="$2"
  local rel_path="${cwd#"$kb_root"/}"
  local repo_name
  repo_name=$(GITKB_ROOT="$kb_root" git kb repo list --json 2>/dev/null | \
    jq -r --arg rel "$rel_path" '.[] | select(.path != null) | select($rel | startswith(.path)) | .name' | head -1) || repo_name=""
  if [ -n "$repo_name" ]; then
    echo "$repo_name"
    return
  fi
  local remote_url
  remote_url=$(git -C "$cwd" remote get-url origin 2>/dev/null) || remote_url=""
  if [ -n "$remote_url" ]; then
    echo "$remote_url" | sed 's/.*\///' | sed 's/\.git$//'
    return
  fi
  basename "$cwd"
}
