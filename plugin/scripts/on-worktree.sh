#!/usr/bin/env bash
# WorktreeCreate hook — bind new worktrees to matching KB tasks.
# Matches branch name patterns like "harmony-42-description" to task slugs.
# Runs async (background).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || exit 0

KB_ROOT=$(find_kb_root "$CWD") || exit 0

# Try daemon — fall through to CLI on failure
SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  if echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/on-worktree \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null; then
    exit 0
  fi
  # Daemon failed — fall through to CLI
fi

# Fallback — try to match branch to task
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.hookSpecificOutput.worktreePath // empty' 2>/dev/null) || exit 0
[ -z "$WORKTREE_PATH" ] && exit 0

# Read the actual branch checked out in the worktree, not the directory name
BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null) || BRANCH=""
# Fall back to directory name if git command fails (worktree may not be ready yet)
[ -z "$BRANCH" ] && BRANCH=$(basename "$WORKTREE_PATH")

# Match pattern: harmony-NNN or tasks-harmony-NNN
TASK_NUM=$(echo "$BRANCH" | grep -oE 'harmony-[0-9]+' | head -1) || exit 0
[ -z "$TASK_NUM" ] && exit 0

TASK_SLUG="tasks/$TASK_NUM"

# Check if task exists
GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb show "$TASK_SLUG" >/dev/null 2>&1 || exit 0

# Set task active
GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb set "$TASK_SLUG" status=active 2>/dev/null || exit 0
GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb commit -m "Set active (worktree: $BRANCH)" "$TASK_SLUG" 2>/dev/null || true
