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

# Check config before any side effects
hook_enabled "$KB_ROOT" "context_injection" "true" || { echo '{}'; exit 0; }

# Resolve active task
RESOLVE_JSON=$(GITKB_ROOT="$KB_ROOT" git-kb resolve --auto --fallback-recent --json 2>/dev/null) || RESOLVE_JSON='{}'
TASK=$(echo "$RESOLVE_JSON" | jq -r '.slug // empty' 2>/dev/null) || TASK=""

TASK_TITLE=""
TASK_CONTENT=""
if [ -n "$TASK" ]; then
  TASK_JSON=$(GITKB_ROOT="$KB_ROOT" git-kb show "$TASK" --json 2>/dev/null) || TASK_JSON=""
  if [ -n "$TASK_JSON" ]; then
    TASK_TITLE=$(echo "$TASK_JSON" | jq -r '.documents[0].title // empty' 2>/dev/null) || TASK_TITLE=""
    TASK_CONTENT=$(GITKB_ROOT="$KB_ROOT" git-kb show "$TASK" 2>/dev/null) || TASK_CONTENT=""
  fi
fi

# Assemble context markdown
NL=$'\n'
CONTEXT=""

# Board summary (bounded output — full board can dominate context on busy KBs)
BOARD=$(GITKB_ROOT="$KB_ROOT" git-kb board --summary 2>/dev/null) || BOARD=""
if [ -n "$BOARD" ]; then
  CONTEXT="## KB Board${NL}${BOARD}${NL}"
fi

# Active task
if [ -n "$TASK" ] && [ -n "$TASK_CONTENT" ]; then
  TASK_LABEL="${TASK}"
  [ -n "$TASK_TITLE" ] && TASK_LABEL="${TASK} — ${TASK_TITLE}"
  CONTEXT="${CONTEXT}${NL}## Active Task: ${TASK_LABEL}${NL}${NL}${TASK_CONTENT}${NL}"
fi

# For compact source, keep it tighter — only task + board
if [ "$SOURCE" = "compact" ] && [ -n "$CONTEXT" ]; then
  CONTEXT="# GitKB Context (post-compaction)${NL}${NL}${CONTEXT}"
elif [ -n "$CONTEXT" ]; then
  CONTEXT="# GitKB Context${NL}${NL}${CONTEXT}"
fi

if [ -z "$CONTEXT" ]; then
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
