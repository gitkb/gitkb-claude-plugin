#!/usr/bin/env bash
# UserPromptSubmit hook — inject relevant KB context before each user prompt.
# Lightweight: only fires when there's an active task to provide context for.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || exit 0

KB_ROOT=$(find_kb_root "$CWD") || exit 0

hook_enabled "$KB_ROOT" "prompt_context" "false" || { echo '{}'; exit 0; }

# Resolve active task
RESOLVE_JSON=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb resolve --auto --json 2>/dev/null) || RESOLVE_JSON='{}'
TASK=$(echo "$RESOLVE_JSON" | jq -r '.slug // empty' 2>/dev/null) || TASK=""
[ -z "$TASK" ] && { echo '{}'; exit 0; }

TASK_CONTENT=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb show "$TASK" 2>/dev/null) || TASK_CONTENT=""

[ -z "$TASK_CONTENT" ] && { echo '{}'; exit 0; }

jq -n --arg ctx "## Active Task: $TASK\n\n$TASK_CONTENT" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'
