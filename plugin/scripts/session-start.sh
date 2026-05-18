#!/usr/bin/env bash
# SessionStart hook — inject lightweight GitKB bootstrap guidance.
# Fires on: startup, resume, clear, compact
# Returns: additionalContext with install/setup/code-intel guidance
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./plugin/scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || { echo '{}'; exit 0; }

NL=$'\n'
CONTEXT=""

if ! command_exists git-kb; then
  CONTEXT="# GitKB Setup${NL}${NL}The GitKB CLI is not installed, so GitKB code intelligence is unavailable in this session.${NL}${NL}Install it with:${NL}${NL}\`\`\`bash${NL}brew install gitkb/tap/gitkb${NL}# or${NL}curl -fsSL https://get.gitkb.com/install.sh | bash${NL}\`\`\`${NL}${NL}After installing, use \`git-kb code doctor\`, \`git-kb code index\`, and related \`git-kb code ...\` commands in any Git repo. Full persistent KB setup is optional via \`git-kb init && git-kb init claude\`."
elif find_kb_root "$CWD" >/dev/null; then
  CONTEXT="# GitKB Ready${NL}${NL}This project has a full \`.kb\` setup. For durable tasks, knowledge, sync, or full Claude integration, use the canonical assets installed by \`git-kb init claude\`. If setup appears stale or missing, ask the user before running \`git-kb init claude --dry-run\` or \`git-kb doctor --check repos,code,kb\`."
elif find_git_root "$CWD" >/dev/null; then
  CONTEXT="# GitKB Code Intelligence${NL}${NL}This Git repo does not have a full \`.kb\` yet, but GitKB code intelligence works without initialization.${NL}${NL}For code questions, prefer these local CLI commands:${NL}${NL}- \`git-kb code doctor\` to inspect language/index health.${NL}- \`git-kb code index\` before first analysis or after large changes.${NL}- \`git-kb code symbols\`, \`git-kb code callers\`, \`git-kb code callees\`, \`git-kb code impact\`, \`git-kb code dead\`, and \`git-kb code query\` for code intelligence.${NL}${NL}Do not require \`git-kb init\` for code intelligence. If the user wants durable tasks, knowledge, sync, or full Claude integration, guide them through:${NL}${NL}\`\`\`bash${NL}git-kb init${NL}git-kb init claude${NL}\`\`\`${NL}${NL}MCP is supported after full KB setup today; use CLI fallback when MCP is unavailable."
else
  CONTEXT="# GitKB Setup${NL}${NL}GitKB is installed, but this directory is not inside a Git repo and does not have a full \`.kb\` project.${NL}${NL}For immediate code intelligence, open a Git repo and run \`git-kb code doctor\` or \`git-kb code index\`. For persistent project memory, initialize GitKB with:${NL}${NL}\`\`\`bash${NL}git-kb init${NL}git-kb init claude${NL}\`\`\`"
fi

CONTEXT_JSON=$(json_escape "$CONTEXT")

if [ -z "$CONTEXT" ]; then
  echo '{}'
  exit 0
fi

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s","watchPaths":[]}}\n' \
  "$CONTEXT_JSON"
