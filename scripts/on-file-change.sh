#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook — track file changes against active task.
# Runs async (background). When daemon is available, delegates to it
# for acceptance criteria checking.
set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd')

find_kb_root() {
  local dir="$1"
  while [ "$dir" != "/" ]; do
    [ -d "$dir/.kb" ] && echo "$dir" && return 0
    dir=$(dirname "$dir")
  done
  return 1
}

KB_ROOT=$(find_kb_root "$CWD") || exit 0

SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/on-file-change \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null || true
fi

exit 0
