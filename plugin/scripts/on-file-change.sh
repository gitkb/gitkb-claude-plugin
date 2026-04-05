#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook — track file changes against active task.
# Runs async (background). When daemon is available, delegates to it
# for acceptance criteria checking.
# No CLI fallback — file change tracking requires daemon-side state
# (acceptance criteria matching, change aggregation) that has no CLI equivalent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || exit 0

KB_ROOT=$(find_kb_root "$CWD") || exit 0

SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/on-file-change \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null || true
fi

exit 0
