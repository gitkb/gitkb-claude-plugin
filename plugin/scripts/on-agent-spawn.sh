#!/usr/bin/env bash
# PreToolUse(Agent) hook — inject active task context into subagent prompts.
# Synchronous — modifies the Agent tool's input before the subagent spawns.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || { echo '{}'; exit 0; }
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

[ -z "$TOOL_INPUT" ] && echo '{}' && exit 0

KB_ROOT=$(find_kb_root "$CWD") || { echo '{}'; exit 0; }

hook_enabled "$KB_ROOT" "context_injection" "true" || { echo '{}'; exit 0; }

# Resolve active task
RESOLVE_JSON=$(GITKB_ROOT="$KB_ROOT" git-kb resolve --auto --fallback-recent --json 2>/dev/null) || RESOLVE_JSON='{}'
TASK=$(echo "$RESOLVE_JSON" | jq -r '.slug // empty' 2>/dev/null) || TASK=""
[ -z "$TASK" ] && { echo '{}'; exit 0; }

# Stamp agent binding for multi-agent coordination
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
AGENT_ID_VAL=$(echo "$INPUT" | jq -r '.agent_id // empty')
BIND_ID="${AGENT_ID_VAL:-$SESSION_ID}"

if [ -n "$BIND_ID" ]; then
  GITKB_ROOT="$KB_ROOT" git-kb set "$TASK" agent_id="$BIND_ID" >/dev/null 2>&1 || true
  GITKB_ROOT="$KB_ROOT" git-kb commit -m "Bind agent $BIND_ID" "$TASK" >/dev/null 2>&1 || true
fi

TASK_JSON=$(GITKB_ROOT="$KB_ROOT" git-kb show "$TASK" --json 2>/dev/null) || { echo '{}'; exit 0; }
TASK_TITLE=$(echo "$TASK_JSON" | jq -r '.documents[0].title // empty')

CONTEXT="Active KB task: ${TASK} — ${TASK_TITLE}. Use kb_show to load full task details before starting work."

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $ctx
  }
}'
