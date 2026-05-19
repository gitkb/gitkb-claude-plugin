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
