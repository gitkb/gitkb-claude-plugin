#!/usr/bin/env bash
# UserPromptSubmit hook — inject relevant KB context before each user prompt.
# Lightweight: only fires when there's an active task to provide context for.
set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd')

# Find KB root
find_kb_root() {
  local dir="$1"
  while [ "$dir" != "/" ]; do
    [ -d "$dir/.kb" ] && echo "$dir" && return 0
    dir=$(dirname "$dir")
  done
  return 1
}

KB_ROOT=$(find_kb_root "$CWD") || exit 0

# Check daemon
SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  RESPONSE=$(echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/user-prompt \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null) || RESPONSE=""

  if [ -n "$RESPONSE" ] && echo "$RESPONSE" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
    echo "$RESPONSE"
    exit 0
  fi
fi

# No daemon — no-op (we don't want to run expensive CLI on every prompt)
echo '{}'
