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

# Resolve active task
RESOLVE_JSON=$(GITKB_ROOT="$KB_ROOT" git-kb resolve --auto --fallback-recent --json 2>/dev/null) || RESOLVE_JSON='{}'
TASK=$(echo "$RESOLVE_JSON" | jq -r '.slug // empty' 2>/dev/null) || TASK=""
[ -z "$TASK" ] && exit 0

# Checkout, append breadcrumb, commit
GITKB_ROOT="$KB_ROOT" git-kb checkout "$TASK" 2>/dev/null || exit 0

WORKSPACE_DIR=$(GITKB_ROOT="$KB_ROOT" git-kb status --json 2>/dev/null | jq -r '.workspace_path // empty' 2>/dev/null) || WORKSPACE_DIR=""
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

GITKB_ROOT="$KB_ROOT" git-kb commit -m "Progress breadcrumb" "$TASK" 2>/dev/null || true

# Clear agent bindings on session end — only if this session owns them
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null) || SESSION_ID=""
AGENT_ID_VAL=$(echo "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null) || AGENT_ID_VAL=""
MY_ID="${AGENT_ID_VAL:-$SESSION_ID}"

if [ -n "$TASK" ] && [ -n "$MY_ID" ]; then
  # Read the current binding from the workspace file to check ownership
  WORKSPACE_BINDING=$(grep "^agent_id:" "$WORKSPACE_FILE" 2>/dev/null | sed 's/agent_id: *//' | tr -d '[:space:]') || WORKSPACE_BINDING=""
  if [ "$WORKSPACE_BINDING" = "$MY_ID" ]; then
    GITKB_ROOT="$KB_ROOT" git-kb set "$TASK" agent_id= >/dev/null 2>&1 || true
    GITKB_ROOT="$KB_ROOT" git-kb set "$TASK" worktree= >/dev/null 2>&1 || true
    GITKB_ROOT="$KB_ROOT" git-kb commit -m "Unbind agent $MY_ID" "$TASK" >/dev/null 2>&1 || true
  fi
fi
