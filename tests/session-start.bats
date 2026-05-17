#!/usr/bin/env bats

setup() {
  load helpers/setup
  setup_test_kb
}

teardown() {
  teardown_test_kb
}

@test "session-start: full KB returns canonical setup guidance" {
  local input
  input=$(build_hook_input "SessionStart" "$TEST_KB_ROOT" "source=startup")

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"GitKB Ready"* ]]
  [[ "$ctx" == *"git-kb init claude"* ]]
  [[ "$ctx" != *"tasks/test-1"* ]]

  local wp
  wp=$(echo "$output" | jq -r '.hookSpecificOutput.watchPaths | length')
  [ "$wp" -eq 0 ]
}

@test "session-start: compact source does not inject active task context" {
  local input
  input=$(build_hook_input "SessionStart" "$TEST_KB_ROOT" "source=compact")

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"GitKB Ready"* ]]
  [[ "$ctx" != *"post-compaction"* ]]
  [[ "$ctx" != *"tasks/test-1"* ]]

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

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"GitKB Ready"* ]]
  [[ "$ctx" != *"tasks/test-1"* ]]
}

@test "session-start: no KB and no git repo returns setup guidance" {
  local no_kb_dir
  no_kb_dir=$(mktemp -d)

  local input
  input=$(build_hook_input "SessionStart" "$no_kb_dir" "source=startup")

  local output
  # Force GITKB_ROOT="" so the script won't walk up past the temp dir
  output=$(echo "$input" | GITKB_ROOT="" "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"not inside a Git repo"* ]]
  [[ "$ctx" == *"git-kb init"* ]]

  rm -rf "$no_kb_dir"
}

@test "session-start: plain git repo returns init-free code-intel guidance" {
  local repo
  repo=$(mktemp -d)
  git -C "$repo" init --quiet

  local input
  input=$(build_hook_input "SessionStart" "$repo" "source=startup")

  local output
  output=$(echo "$input" | GITKB_ROOT="" "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"GitKB Code Intelligence"* ]]
  [[ "$ctx" == *"works without initialization"* ]]
  [[ "$ctx" == *"git-kb code doctor"* ]]
  [[ "$ctx" == *"git-kb code index"* ]]
  [[ "$ctx" == *"Do not require \`git-kb init\` for code intelligence"* ]]

  local wp
  wp=$(echo "$output" | jq -r '.hookSpecificOutput.watchPaths | length')
  [ "$wp" -eq 0 ]

  rm -rf "$repo"
}

@test "session-start: missing git-kb returns install guidance" {
  local repo tmpbin
  repo=$(mktemp -d)
  tmpbin=$(mktemp -d)
  git -C "$repo" init --quiet

  ln -s "$(command -v awk)" "$tmpbin/awk"
  ln -s "$(command -v bash)" "$tmpbin/bash"
  ln -s "$(command -v cat)" "$tmpbin/cat"
  ln -s "$(command -v dirname)" "$tmpbin/dirname"

  local input
  input=$(build_hook_input "SessionStart" "$repo" "source=startup")

  local output
  output=$(echo "$input" | PATH="$tmpbin" GITKB_ROOT="" "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"GitKB CLI is not installed"* ]]
  [[ "$ctx" == *"brew install gitkb/tap/gitkb"* ]]
  [[ "$ctx" == *"curl -fsSL https://get.gitkb.com/install.sh | bash"* ]]

  rm -rf "$repo" "$tmpbin"
}

@test "session-start: no active task still returns setup guidance only" {
  # Complete the test task so nothing is active
  GITKB_ROOT="$TEST_KB_ROOT" git-kb set tasks/test-1 status=completed 2>/dev/null
  GITKB_ROOT="$TEST_KB_ROOT" git-kb commit -m "complete" tasks/test-1 2>/dev/null

  local input
  input=$(build_hook_input "SessionStart" "$TEST_KB_ROOT" "source=startup")

  local output
  output=$(echo "$input" | "$SCRIPTS_DIR/session-start.sh" 2>/dev/null)

  assert_hook_output_valid "$output" "SessionStart"

  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"GitKB Ready"* ]]
  [[ "$ctx" != *"Active Task"* ]]
}
