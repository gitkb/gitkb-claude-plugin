#!/usr/bin/env bats

setup() {
  load helpers/setup
  setup_test_kb
}

teardown() {
  teardown_test_kb
}

@test "on-agent-spawn: injects active task context" {
  local input
  input=$(build_hook_input "PreToolUse" "$TEST_KB_ROOT" \
    "tool_name=Agent" \
    'tool_input={"prompt":"Fix the bug","subagent_type":"general-purpose"}')

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/on-agent-spawn.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "PreToolUse"

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"tasks/test-1"* ]]
  [[ "$ctx" == *"Test Task"* ]]
}

@test "on-agent-spawn: no KB returns empty JSON" {
  local no_kb_dir
  no_kb_dir=$(mktemp -d)

  local input
  input=$(build_hook_input "PreToolUse" "$no_kb_dir" "tool_name=Agent")

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/on-agent-spawn.sh" 2>/dev/null)

  assert_hook_noop "$output"

  rm -rf "$no_kb_dir"
}

@test "on-agent-spawn: no active task returns empty JSON" {
  GITKB_ROOT="$TEST_KB_ROOT" git kb set tasks/test-1 status=completed 2>/dev/null
  GITKB_ROOT="$TEST_KB_ROOT" git kb commit -m "complete" tasks/test-1 2>/dev/null

  local input
  input=$(build_hook_input "PreToolUse" "$TEST_KB_ROOT" "tool_name=Agent")

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/on-agent-spawn.sh" 2>/dev/null)

  assert_hook_noop "$output"
}
