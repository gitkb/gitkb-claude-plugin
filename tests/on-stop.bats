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

@test "on-stop: clears agent_id binding" {
  # Enable auto_progress so on-stop processes the task
  sed -i '' 's/auto_progress = false/auto_progress = true/' "$TEST_KB_ROOT/.kb/config.toml" 2>/dev/null || \
  sed -i 's/auto_progress = false/auto_progress = true/' "$TEST_KB_ROOT/.kb/config.toml"

  # Stamp agent_id
  GITKB_ROOT="$TEST_KB_ROOT" git -C "$TEST_KB_ROOT" kb set tasks/test-1 agent_id=test-agent
  GITKB_ROOT="$TEST_KB_ROOT" git -C "$TEST_KB_ROOT" kb commit -m "bind" tasks/test-1

  # Verify binding exists via resolve
  local before
  before=$(AGENT_ID=test-agent GITKB_ROOT="$TEST_KB_ROOT" git -C "$TEST_KB_ROOT" kb resolve --auto 2>/dev/null) || before=""
  [ "$before" = "tasks/test-1" ]

  local input
  input=$(build_hook_input "Stop" "$TEST_KB_ROOT" \
    "last_assistant_message=Session complete")

  echo "$input" | "$SCRIPTS_DIR/on-stop.sh" >/dev/null 2>&1

  # Binding should be cleared — resolve should return empty
  local after
  after=$(AGENT_ID=test-agent GITKB_ROOT="$TEST_KB_ROOT" git -C "$TEST_KB_ROOT" kb resolve --auto 2>/dev/null) || after=""
  [ -z "$after" ]
}
