#!/usr/bin/env bats

setup() {
  load helpers/setup
  setup_test_kb
}

teardown() {
  teardown_test_kb
}

@test "session-start: startup source returns board + active task" {
  local input
  input=$(build_hook_input "SessionStart" "$TEST_KB_ROOT" "source=startup")

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"

  # Should contain board content
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"KB Board"* ]]
  [[ "$ctx" == *"tasks/test-1"* ]]

  # Should set watchPaths on startup
  local wp
  wp=$(echo "$output" | jq -r '.hookSpecificOutput.watchPaths | length')
  [ "$wp" -gt 0 ]
}

@test "session-start: compact source returns post-compaction header" {
  local input
  input=$(build_hook_input "SessionStart" "$TEST_KB_ROOT" "source=compact")

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"post-compaction"* ]]

  # No watchPaths on compact (already set from startup)
  local wp
  wp=$(echo "$output" | jq -r '.hookSpecificOutput.watchPaths | length')
  [ "$wp" -eq 0 ]
}

@test "session-start: resume source returns context" {
  local input
  input=$(build_hook_input "SessionStart" "$TEST_KB_ROOT" "source=resume")

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"
}

@test "session-start: no KB returns empty JSON" {
  local no_kb_dir
  no_kb_dir=$(mktemp -d)

  local input
  input=$(build_hook_input "SessionStart" "$no_kb_dir" "source=startup")

  local output
  # Force GITKB_ROOT="" so the script won't walk up past the temp dir
  output=$(echo "$input" | GITKB_ROOT="" "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  # Should exit 0 with no content (no KB found)
  assert_hook_noop "$output"

  rm -rf "$no_kb_dir"
}

@test "session-start: no active task returns board only" {
  # Complete the test task so nothing is active
  GITKB_ROOT="$TEST_KB_ROOT" git kb set tasks/test-1 status=completed 2>/dev/null
  GITKB_ROOT="$TEST_KB_ROOT" git kb commit -m "complete" tasks/test-1 2>/dev/null

  local input
  input=$(build_hook_input "SessionStart" "$TEST_KB_ROOT" "source=startup")

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"KB Board"* ]]
  # Should NOT have "Active Task" section
  [[ "$ctx" != *"Active Task"* ]]
}
