#!/usr/bin/env bash
# Stop hook — extract progress from the assistant's last message and
# auto-commit it to the active task. Runs async (background).
set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')

[ -z "$CWD" ] && exit 0
[ -z "$LAST_MSG" ] && exit 0

find_kb_root() {
  local dir="$1"
  while [ "$dir" != "/" ]; do
    [ -d "$dir/.kb" ] && echo "$dir" && return 0
    dir=$(dirname "$dir")
  done
  return 1
}

KB_ROOT=$(find_kb_root "$CWD") || exit 0

# Try daemon first
SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/on-stop \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null || true
fi

# No daemon fallback — CLI-based extraction would be too slow for async hook
exit 0
