#!/usr/bin/env bats

setup() {
  load helpers/setup
  setup_test_kb
}

teardown() {
  teardown_test_kb
}

@test "on-file-change: exits gracefully with no KB" {
  local no_kb_dir
  no_kb_dir=$(mktemp -d)

  local input
  input=$(build_hook_input "PostToolUse" "$no_kb_dir" \
    "tool_name=Edit")

  echo "$input" | "$SCRIPTS_DIR/on-file-change.sh" 2>/dev/null
  [ $? -eq 0 ]

  rm -rf "$no_kb_dir"
}

@test "on-file-change: exits gracefully with empty cwd" {
  local input
  input=$(jq -n '{
    hook_event_name: "PostToolUse",
    tool_name: "Edit"
  }')

  echo "$input" | "$SCRIPTS_DIR/on-file-change.sh" 2>/dev/null
  [ $? -eq 0 ]
}
