#!/usr/bin/env bash
# WorktreeCreate hook — bind new worktrees to matching KB tasks.
# Matches branch name patterns like "harmony-42-description" to task slugs.
# Runs async (background).
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

# Try daemon
SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/on-worktree \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null || true
  exit 0
fi

# Fallback — try to match branch to task
# WorktreeCreate input doesn't have a standard branch field in hookSpecificOutput,
# but the worktree path often contains the branch name
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.hookSpecificOutput.worktreePath // empty' 2>/dev/null) || exit 0
[ -z "$WORKTREE_PATH" ] && exit 0

BRANCH=$(basename "$WORKTREE_PATH")

# Match pattern: harmony-NNN or tasks-harmony-NNN
TASK_NUM=$(echo "$BRANCH" | grep -oE 'harmony-[0-9]+' | head -1) || exit 0
[ -z "$TASK_NUM" ] && exit 0

TASK_SLUG="tasks/$TASK_NUM"

# Check if task exists
GITKB_ROOT="$KB_ROOT" git kb show "$TASK_SLUG" >/dev/null 2>&1 || exit 0

# Set task active
GITKB_ROOT="$KB_ROOT" git kb set "$TASK_SLUG" status=active 2>/dev/null || exit 0
GITKB_ROOT="$KB_ROOT" git kb commit -m "Set active (worktree: $BRANCH)" "$TASK_SLUG" 2>/dev/null || true
