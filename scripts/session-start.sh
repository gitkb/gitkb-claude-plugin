#!/usr/bin/env bash
# SessionStart hook — inject KB context into the conversation.
# Fires on: startup, resume, clear, compact
# Returns: additionalContext with active task + board state + progress
set -euo pipefail

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')
CWD=$(echo "$INPUT" | jq -r '.cwd')

# Find GITKB_ROOT — honor env var override, then walk up from CWD
find_kb_root() {
  # If GITKB_ROOT is explicitly set, trust it (empty = no KB)
  if [ "${GITKB_ROOT+set}" = "set" ]; then
    if [ -n "$GITKB_ROOT" ] && [ -d "$GITKB_ROOT/.kb" ]; then
      echo "$GITKB_ROOT"
      return 0
    fi
    return 1
  fi
  local dir="$1"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.kb" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

KB_ROOT=$(find_kb_root "$CWD") || exit 0  # No KB = no-op

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
fi

# Fallback — assemble context via CLI
CONTEXT=""

# Active tasks
BOARD=$(GITKB_ROOT="$KB_ROOT" git kb board 2>/dev/null) || BOARD=""
if [ -n "$BOARD" ]; then
  CONTEXT="## KB Board\n\`\`\`\n${BOARD}\n\`\`\`\n"
fi

# Find active task
ACTIVE_TASK=$(GITKB_ROOT="$KB_ROOT" git kb list --type task --status active --json 2>/dev/null | jq -r '.[0].slug // empty' 2>/dev/null) || ACTIVE_TASK=""

if [ -n "$ACTIVE_TASK" ]; then
  TASK_CONTENT=$(GITKB_ROOT="$KB_ROOT" git kb show "$ACTIVE_TASK" 2>/dev/null) || TASK_CONTENT=""
  if [ -n "$TASK_CONTENT" ]; then
    CONTEXT="${CONTEXT}\n## Active Task: ${ACTIVE_TASK}\n\n${TASK_CONTENT}\n"
  fi
fi

# For compact source, keep it tighter — only task + board
if [ "$SOURCE" = "compact" ] && [ -n "$CONTEXT" ]; then
  CONTEXT="# GitKB Context (post-compaction)\n\n${CONTEXT}"
elif [ -n "$CONTEXT" ]; then
  CONTEXT="# GitKB Context\n\n${CONTEXT}"
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
