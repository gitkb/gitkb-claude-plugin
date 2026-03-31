#!/usr/bin/env bats

setup() {
  load helpers/setup
  setup_test_kb
}

teardown() {
  teardown_test_kb
}

@test "on-commit: links commit hash to active task" {
  local input
  input=$(build_hook_input "PostToolUse" "$TEST_KB_ROOT" \
    "tool_name=Bash" \
    "tool_response=[harmony-414 abc1234] feat: implement feature")

  echo "$input" | "$SCRIPTS_DIR/on-commit.sh" 2>/dev/null

  # Check the task was updated with commit reference
  local task_content
  task_content=$(GITKB_ROOT="$TEST_KB_ROOT" git kb show tasks/test-1 2>/dev/null)
  [[ "$task_content" == *"[[commit:abc1234]]"* ]]
}

@test "on-commit: no commit hash in output is a no-op" {
  local input
  input=$(build_hook_input "PostToolUse" "$TEST_KB_ROOT" \
    "tool_name=Bash" \
    "tool_response=Hello world")

  echo "$input" | "$SCRIPTS_DIR/on-commit.sh" 2>/dev/null

  # Task should not have progress log
  local task_content
  task_content=$(GITKB_ROOT="$TEST_KB_ROOT" git kb show tasks/test-1 2>/dev/null)
  [[ "$task_content" != *"Progress Log"* ]]
}

@test "on-commit: no active task is a no-op" {
  GITKB_ROOT="$TEST_KB_ROOT" git kb set tasks/test-1 status=completed 2>/dev/null
  GITKB_ROOT="$TEST_KB_ROOT" git kb commit -m "complete" tasks/test-1 2>/dev/null

  local input
  input=$(build_hook_input "PostToolUse" "$TEST_KB_ROOT" \
    "tool_name=Bash" \
    "tool_response=[main abc1234] feat: something")

  # Should exit 0 without error
  echo "$input" | "$SCRIPTS_DIR/on-commit.sh" 2>/dev/null
  [ $? -eq 0 ]
}

@test "on-commit: no KB is a no-op" {
  local no_kb_dir
  no_kb_dir=$(mktemp -d)

  local input
  input=$(build_hook_input "PostToolUse" "$no_kb_dir" \
    "tool_name=Bash" \
    "tool_response=[main abc1234] feat: something")

  echo "$input" | "$SCRIPTS_DIR/on-commit.sh" 2>/dev/null
  [ $? -eq 0 ]

  rm -rf "$no_kb_dir"
}
