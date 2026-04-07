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

# Resolve branch to task slug
RESOLVE_JSON=$(GITKB_ROOT="$KB_ROOT" git-kb resolve --branch "$BRANCH" --json 2>/dev/null) || exit 0
TASK=$(echo "$RESOLVE_JSON" | jq -r '.slug // empty' 2>/dev/null) || exit 0
[ -z "$TASK" ] && exit 0

# Set task active and stamp worktree for multi-agent coordination
GITKB_ROOT="$KB_ROOT" git-kb set "$TASK" status=active >/dev/null 2>&1 || exit 0
GITKB_ROOT="$KB_ROOT" git-kb set "$TASK" worktree="$BRANCH" >/dev/null 2>&1 || true
GITKB_ROOT="$KB_ROOT" git-kb commit -m "Set active (worktree: $BRANCH)" "$TASK" >/dev/null 2>&1 || true
