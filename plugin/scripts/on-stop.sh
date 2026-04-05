#!/usr/bin/env bash
# Stop hook — extract progress from the assistant's last message and
# auto-commit it to the active task. Runs async (background).
# No CLI fallback — progress extraction requires daemon-side NLP that
# has no CLI equivalent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || exit 0
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')

[ -z "$LAST_MSG" ] && exit 0

KB_ROOT=$(find_kb_root "$CWD") || exit 0

# Try daemon — stale sockets fail silently (acceptable for async hook;
# the daemon auto-cleans its socket on clean shutdown)
SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/on-stop \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null || true
fi

exit 0
