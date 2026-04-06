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

# Try daemon
SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  RESPONSE=$(echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/on-agent-spawn \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null) || RESPONSE=""

  if [ -n "$RESPONSE" ] && echo "$RESPONSE" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
    echo "$RESPONSE"
    exit 0
  fi
fi

# Fallback — inject active task context into the agent's prompt
ACTIVE_JSON=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb list --type task --status active --json 2>/dev/null) || { echo '{}'; exit 0; }
ACTIVE_TASK=$(echo "$ACTIVE_JSON" | jq -r '.[0].slug // empty' 2>/dev/null)
[ -z "$ACTIVE_TASK" ] && echo '{}' && exit 0

TASK_TITLE=$(echo "$ACTIVE_JSON" | jq -r '.[0].title // empty' 2>/dev/null)

# Inject task context as additional context (doesn't modify the agent's prompt)
CONTEXT="Active KB task: ${ACTIVE_TASK} — ${TASK_TITLE}. Use kb_show to load full task details before starting work."

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $ctx
  }
}'
