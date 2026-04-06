#!/usr/bin/env bash
# WorktreeCreate hook — bind new worktrees to matching KB tasks.
# Matches branch name patterns to task slugs via git kb resolve --branch.
# Runs async (background).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || exit 0

KB_ROOT=$(find_kb_root "$CWD") || exit 0

hook_enabled "$KB_ROOT" "auto_worktree_bind" "true" || exit 0

# Read worktree path from hook input
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.hookSpecificOutput.worktreePath // empty' 2>/dev/null) || exit 0
[ -z "$WORKTREE_PATH" ] && exit 0

# Read the actual branch checked out in the worktree, not the directory name
BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null) || BRANCH=$(basename "$WORKTREE_PATH")

# Resolve branch to task slug (resolve outputs plain slug text)
TASK=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb resolve --branch "$BRANCH" 2>/dev/null) || exit 0
TASK=$(echo "$TASK" | tr -d '[:space:]')
[ -z "$TASK" ] && exit 0

# Set task active and commit
GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb set "$TASK" status=active 2>/dev/null || exit 0
GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb commit -m "Set active (worktree: $BRANCH)" "$TASK" 2>/dev/null || true
