#!/usr/bin/env bash
# Shared functions for GitKB hook scripts.

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

json_get_string() {
  local input="$1" key="$2"
  awk -v key="$key" '
    BEGIN { RS = "\0" }
    {
      target = "\"" key "\""
      start = index($0, target)
      if (start == 0) {
        exit 1
      }
      i = start + length(target)
      len = length($0)
      while (i <= len && substr($0, i, 1) ~ /[ \t\r\n]/) {
        i++
      }
      if (substr($0, i, 1) != ":") {
        exit 1
      }
      i++
      while (i <= len && substr($0, i, 1) ~ /[ \t\r\n]/) {
        i++
      }
      if (substr($0, i, 1) != "\"") {
        exit 1
      }
      i++
      out = ""
      while (i <= len) {
        c = substr($0, i, 1)
        if (c == "\"") {
          print out
          exit 0
        }
        if (c == "\\") {
          i++
          esc = substr($0, i, 1)
          if (esc == "n") {
            out = out "\n"
          } else if (esc == "r") {
            out = out "\r"
          } else if (esc == "t") {
            out = out "\t"
          } else {
            out = out esc
          }
          i++
          continue
        }
        out = out c
        i++
      }
      exit 1
    }
  ' <<<"$input"
}

json_escape() {
  local value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

# Check if a hook feature is enabled via .kb/config.toml.
# Returns 0 (enabled) or 1 (disabled).
# When the key is missing from config, falls back to the provided default.
#
# Usage: hook_enabled "$KB_ROOT" "context_injection" "true" || exit 0
hook_enabled() {
  local kb_root="$1" key="$2" default="${3:-true}"
  local val
  val=$(GITKB_ROOT="$kb_root" git-kb config get "hooks.$key" 2>/dev/null) || val="$default"
  [ "$val" = "true" ]
}

# Resolve CWD from hook JSON input. Returns empty and exits if invalid.
# Usage: CWD=$(resolve_cwd "$INPUT") || exit 0
resolve_cwd() {
  local raw
  raw=$(json_get_string "$1" "cwd") || return 1
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

# Return the nearest git root for code-only GitKB flows.
# This is intentionally separate from find_kb_root so KB semantics stay strict.
find_git_root() {
  local cwd="$1"
  git -C "$cwd" rev-parse --show-toplevel 2>/dev/null
}
