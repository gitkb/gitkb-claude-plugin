#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook — track file changes against active task.
# Runs async (background).
# No CLI equivalent for file-change tracking.
# Placeholder for future daemon-side acceptance criteria checking.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INPUT=$(cat)
CWD=$(resolve_cwd "$INPUT") || exit 0

KB_ROOT=$(find_kb_root "$CWD") || exit 0

exit 0
