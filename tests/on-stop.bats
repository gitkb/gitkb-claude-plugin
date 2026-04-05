#!/usr/bin/env bats

setup() {
  load helpers/setup
  setup_test_kb
}

teardown() {
  teardown_test_kb
}

@test "on-stop: exits gracefully with no last_assistant_message" {
  local input
  input=$(build_hook_input "Stop" "$TEST_KB_ROOT")

  echo "$input" | "$SCRIPTS_DIR/on-stop.sh" 2>/dev/null
  [ $? -eq 0 ]
}

@test "on-stop: exits gracefully with no KB" {
  local no_kb_dir
  no_kb_dir=$(mktemp -d)

  local input
  input=$(build_hook_input "Stop" "$no_kb_dir" \
    "last_assistant_message=I fixed the bug")

  echo "$input" | "$SCRIPTS_DIR/on-stop.sh" 2>/dev/null
  [ $? -eq 0 ]

  rm -rf "$no_kb_dir"
}

@test "on-stop: exits gracefully with empty cwd" {
  local input
  input=$(jq -n '{
    hook_event_name: "Stop",
    last_assistant_message: "Done"
  }')

  echo "$input" | "$SCRIPTS_DIR/on-stop.sh" 2>/dev/null
  [ $? -eq 0 ]
}
