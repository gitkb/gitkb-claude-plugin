#!/usr/bin/env bash
# Stop hook — add a progress breadcrumb to the active task.
# Runs async (background).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || exit 0
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')

[ -z "$LAST_MSG" ] && exit 0

KB_ROOT=$(find_kb_root "$CWD") || exit 0

hook_enabled "$KB_ROOT" "auto_progress" "false" || exit 0

# Resolve active task (resolve outputs plain slug text)
TASK=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb resolve --auto 2>/dev/null) || exit 0
TASK=$(echo "$TASK" | tr -d '[:space:]')
[ -z "$TASK" ] && exit 0

# Checkout, append breadcrumb, commit
GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb checkout "$TASK" 2>/dev/null || exit 0

WORKSPACE_DIR=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb status --json 2>/dev/null | jq -r '.workspace_path // empty' 2>/dev/null) || WORKSPACE_DIR=""
if [ -z "$WORKSPACE_DIR" ]; then
  WORKSPACE_DIR="$KB_ROOT/.kb/workspaces/main"
fi
WORKSPACE_FILE="$WORKSPACE_DIR/$TASK.md"
[ -f "$WORKSPACE_FILE" ] || exit 0

DATE=$(date +%Y-%m-%d)
if grep -q "## Progress Log" "$WORKSPACE_FILE" 2>/dev/null; then
  printf "\n- %s: session turn completed\n" "$DATE" >> "$WORKSPACE_FILE"
else
  printf "\n## Progress Log\n\n- %s: session turn completed\n" "$DATE" >> "$WORKSPACE_FILE"
fi

GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb commit -m "Progress breadcrumb" "$TASK" 2>/dev/null || true
