#!/usr/bin/env bash
# SessionStart hook — inject KB context into the conversation.
# Fires on: startup, resume, clear, compact
# Returns: additionalContext with active task + board state + progress
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')
CWD=$(resolve_cwd "$INPUT") || exit 0

KB_ROOT=$(find_kb_root "$CWD") || exit 0  # No KB = no-op

# Check config before any side effects (daemon start, context assembly)
hook_enabled "$KB_ROOT" "context_injection" "true" || { echo '{}'; exit 0; }

# Ensure daemon is running, anchored to the resolved KB root
( GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb daemon status --quiet || \
  GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb daemon start ) >/dev/null 2>&1 || true

# Check if daemon is running
SOCK="$KB_ROOT/.kb/.cache/gitkb.sock"
if [ -S "$SOCK" ]; then
  # Daemon available — use HTTP for richer context
  RESPONSE=$(echo "$INPUT" | curl -sf --unix-socket "$SOCK" \
    -X POST http://localhost/hooks/session-start \
    -H "Content-Type: application/json" \
    --data @- 2>/dev/null) || RESPONSE=""

  if [ -n "$RESPONSE" ] && echo "$RESPONSE" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
    echo "$RESPONSE"
    exit 0
  fi
  # Daemon failed or returned bad response — fall through to CLI
fi

# Fallback — assemble context via CLI
NL=$'\n'
CONTEXT=""

# Active tasks
BOARD=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb board 2>/dev/null) || BOARD=""
if [ -n "$BOARD" ]; then
  CONTEXT="## KB Board${NL}\`\`\`${NL}${BOARD}${NL}\`\`\`${NL}"
fi

# Find active task
ACTIVE_TASK=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb list --type task --status active --json 2>/dev/null | jq -r '.[0].slug // empty' 2>/dev/null) || ACTIVE_TASK=""

if [ -n "$ACTIVE_TASK" ]; then
  TASK_CONTENT=$(GITKB_ROOT="$KB_ROOT" git -C "$CWD" kb show "$ACTIVE_TASK" 2>/dev/null) || TASK_CONTENT=""
  if [ -n "$TASK_CONTENT" ]; then
    CONTEXT="${CONTEXT}${NL}## Active Task: ${ACTIVE_TASK}${NL}${NL}${TASK_CONTENT}${NL}"
  fi
fi

# For compact source, keep it tighter — only task + board
if [ "$SOURCE" = "compact" ] && [ -n "$CONTEXT" ]; then
  CONTEXT="# GitKB Context (post-compaction)${NL}${NL}${CONTEXT}"
elif [ -n "$CONTEXT" ]; then
  CONTEXT="# GitKB Context${NL}${NL}${CONTEXT}"
fi

if [ -z "$CONTEXT" ]; then
  # No context to inject
  echo '{}'
  exit 0
fi

# Build response with additionalContext
WATCH_PATHS="[]"
if [ "$SOURCE" = "startup" ] || [ "$SOURCE" = "clear" ]; then
  WATCH_PATHS="[\"$KB_ROOT/.kb/workspaces/\"]"
fi

jq -n \
  --arg ctx "$CONTEXT" \
  --argjson wp "$WATCH_PATHS" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx,
      watchPaths: $wp
    }
  }'
