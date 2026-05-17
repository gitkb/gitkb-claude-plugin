#!/usr/bin/env bash
# SessionStart hook — inject GitKB onboarding or KB context into the conversation.
# Fires on: startup, resume, clear, compact
# Returns: additionalContext with code-intel bootstrap guidance or active KB context
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./plugin/scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
SOURCE=$(json_get_string "$INPUT" "source" 2>/dev/null) || SOURCE="startup"
CWD=$(resolve_cwd "$INPUT") || exit 0

NL=$'\n'
CONTEXT=""
WATCH_PATH=""

if ! command_exists git-kb; then
  CONTEXT="# GitKB Setup${NL}${NL}The GitKB CLI is not installed, so GitKB code intelligence is unavailable in this session.${NL}${NL}Install it with:${NL}${NL}\`\`\`bash${NL}brew install gitkb/tap/gitkb${NL}# or${NL}curl -fsSL https://get.gitkb.com/install.sh | bash${NL}\`\`\`${NL}${NL}After installing, use \`git-kb code doctor\`, \`git-kb code index\`, and related \`git-kb code ...\` commands in any Git repo. Full persistent KB setup is optional via \`git-kb init && git-kb init claude\`."
elif KB_ROOT=$(find_kb_root "$CWD"); then
  # Check config before any side effects in full-KB projects.
  hook_enabled "$KB_ROOT" "context_injection" "true" || { echo '{}'; exit 0; }

  # Resolve active task
  RESOLVE_JSON=$(GITKB_ROOT="$KB_ROOT" git-kb resolve --auto --fallback-recent --json 2>/dev/null) || RESOLVE_JSON='{}'
  TASK=$(json_get_string "$RESOLVE_JSON" "slug" 2>/dev/null) || TASK=""

  TASK_CONTENT=""
  if [ -n "$TASK" ]; then
    # Full document output (frontmatter + body) for context injection
    TASK_CONTENT=$(GITKB_ROOT="$KB_ROOT" git-kb show "$TASK" 2>/dev/null) || TASK_CONTENT=""
  fi

  # Board summary (bounded output — full board can dominate context on busy KBs)
  BOARD=$(GITKB_ROOT="$KB_ROOT" git-kb board --summary 2>/dev/null) || BOARD=""
  if [ -n "$BOARD" ]; then
    CONTEXT="## KB Board${NL}${BOARD}${NL}"
  fi

  # Active task
  if [ -n "$TASK" ] && [ -n "$TASK_CONTENT" ]; then
    CONTEXT="${CONTEXT}${NL}## Active Task: ${TASK}${NL}${NL}${TASK_CONTENT}${NL}"
  fi

  # For compact source, keep it tighter — only task + board
  if [ "$SOURCE" = "compact" ] && [ -n "$CONTEXT" ]; then
    CONTEXT="# GitKB Context (post-compaction)${NL}${NL}${CONTEXT}"
  elif [ -n "$CONTEXT" ]; then
    CONTEXT="# GitKB Context${NL}${NL}${CONTEXT}"
  fi

  if [ "$SOURCE" = "startup" ] || [ "$SOURCE" = "clear" ]; then
    WATCH_PATH="$KB_ROOT/.kb/workspaces/"
  fi
elif GIT_ROOT=$(find_git_root "$CWD"); then
  CONTEXT="# GitKB Code Intelligence${NL}${NL}This Git repo does not have a full \`.kb\` yet, but GitKB code intelligence works without initialization.${NL}${NL}Repository root: \`${GIT_ROOT}\`${NL}${NL}For code questions, prefer these local CLI commands:${NL}${NL}- \`git-kb code doctor\` to inspect language/index health.${NL}- \`git-kb code index\` before first analysis or after large changes.${NL}- \`git-kb code symbols\`, \`git-kb code callers\`, \`git-kb code callees\`, \`git-kb code impact\`, \`git-kb code dead\`, and \`git-kb code query\` for code intelligence.${NL}${NL}Do not require \`git-kb init\` for code intelligence. If the user wants durable tasks, knowledge, sync, or full Claude integration, guide them through:${NL}${NL}\`\`\`bash${NL}git-kb init${NL}git-kb init claude${NL}\`\`\`${NL}${NL}MCP is supported after full KB setup today; use CLI fallback when MCP is unavailable."
else
  CONTEXT="# GitKB Setup${NL}${NL}GitKB is installed, but this directory is not inside a Git repo and does not have a full \`.kb\` project.${NL}${NL}For immediate code intelligence, open a Git repo and run \`git-kb code doctor\` or \`git-kb code index\`. For persistent project memory, initialize GitKB with:${NL}${NL}\`\`\`bash${NL}git-kb init${NL}git-kb init claude${NL}\`\`\`"
fi

CONTEXT_JSON=$(json_escape "$CONTEXT")
WATCH_PATH_JSON=$(json_escape "$WATCH_PATH")

if [ -z "$CONTEXT" ]; then
  echo '{}'
  exit 0
fi

if [ -n "$WATCH_PATH" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s","watchPaths":["%s"]}}\n' \
    "$CONTEXT_JSON" \
    "$WATCH_PATH_JSON"
else
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s","watchPaths":[]}}\n' \
    "$CONTEXT_JSON"
fi
