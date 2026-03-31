#!/usr/bin/env bash
# PostToolUse(Bash) hook — detect git commits and auto-link to active task.
# Only fires for Bash commands matching "git commit*" (via `if` filter).
# Runs async (background).
set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd')
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // empty')

[ -z "$TOOL_RESPONSE" ] && exit 0

find_kb_root() {
  local dir="$1"
  while [ "$dir" != "/" ]; do
    [ -d "$dir/.kb" ] && echo "$dir" && return 0
    dir=$(dirname "$dir")
  done
  return 1
}

KB_ROOT=$(find_kb_root "$CWD") || exit 0

# Try daemon
SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/on-commit \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null || true
  exit 0
fi

# Fallback — parse commit hash from tool output and add to active task
COMMIT_HASH=$(echo "$TOOL_RESPONSE" | grep -oE '\b[0-9a-f]{7,40}\b' | head -1) || exit 0
[ -z "$COMMIT_HASH" ] && exit 0

ACTIVE_TASK=$(GITKB_ROOT="$KB_ROOT" git kb list --type task --status active --json 2>/dev/null | jq -r '.[0].slug // empty' 2>/dev/null) || exit 0
[ -z "$ACTIVE_TASK" ] && exit 0

# Checkout, append commit ref, commit
GITKB_ROOT="$KB_ROOT" git kb checkout "$ACTIVE_TASK" 2>/dev/null || exit 0

WORKSPACE_FILE="$KB_ROOT/.kb/workspaces/main/$ACTIVE_TASK.md"
[ -f "$WORKSPACE_FILE" ] || exit 0

DATE=$(date +%Y-%m-%d)
if grep -q "## Progress Log" "$WORKSPACE_FILE" 2>/dev/null; then
  # Append under progress log
  printf "\n### %s\n- Commit: [[commit:%s]]\n" "$DATE" "$COMMIT_HASH" >> "$WORKSPACE_FILE"
else
  # Add progress log section
  printf "\n## Progress Log\n\n### %s\n- Commit: [[commit:%s]]\n" "$DATE" "$COMMIT_HASH" >> "$WORKSPACE_FILE"
fi

GITKB_ROOT="$KB_ROOT" git kb commit -m "Link commit $COMMIT_HASH" "$ACTIVE_TASK" 2>/dev/null || true
