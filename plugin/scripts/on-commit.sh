#!/usr/bin/env bash
# PostToolUse(Bash) hook — detect git commits and auto-link to active task.
# Only fires for Bash commands matching "git commit*" (via `if` filter).
# Runs async (background).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || exit 0
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // empty')

[ -z "$TOOL_RESPONSE" ] && exit 0

KB_ROOT=$(find_kb_root "$CWD") || exit 0

hook_enabled "$KB_ROOT" "auto_commit_link" "true" || exit 0

# Parse commit hash from tool output
SHA=$(echo "$TOOL_RESPONSE" | grep -oE '\b[0-9a-f]{7,40}\b' | head -1) || exit 0
[ -z "$SHA" ] && exit 0

# Resolve active task (resolve outputs plain slug text)
TASK=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb resolve --auto 2>/dev/null) || exit 0
TASK=$(echo "$TASK" | tr -d '[:space:]')
[ -z "$TASK" ] && exit 0

# Detect repo and link commit, then persist
REPO=$(detect_repo "$KB_ROOT" "$CWD")
GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb link "$TASK" --repo "$REPO" --commit "$SHA" 2>/dev/null || exit 0
GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb commit -m "Link commit $SHA" "$TASK" 2>/dev/null || true
