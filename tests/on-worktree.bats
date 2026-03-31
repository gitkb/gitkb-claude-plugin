#!/usr/bin/env bats

setup() {
  load helpers/setup
  setup_test_kb
}

teardown() {
  teardown_test_kb
}

@test "on-worktree: matches branch to task and sets active" {
  # Create a task with harmony-NNN naming (matches script pattern)
  GITKB_ROOT="$TEST_KB_ROOT" git kb create \
    --type task \
    --slug tasks/harmony-99 \
    --title "Worktree Test Task" 2>/dev/null
  GITKB_ROOT="$TEST_KB_ROOT" git kb commit -m "create" tasks/harmony-99 2>/dev/null

  local input
  input=$(jq -n \
    --arg cwd "$TEST_KB_ROOT" \
    '{
      hook_event_name: "WorktreeCreate",
      cwd: $cwd,
      hookSpecificOutput: { worktreePath: "/tmp/worktrees/harmony-99-feature" }
    }')

  echo "$input" | "$SCRIPTS_DIR/on-worktree.sh" 2>/dev/null

  # Task should now be active
  local status
  status=$(GITKB_ROOT="$TEST_KB_ROOT" git kb list --type task --json 2>/dev/null | jq -r '.[] | select(.slug == "tasks/harmony-99") | .status')
  [ "$status" = "active" ]
}

@test "on-worktree: non-matching branch is a no-op" {
  GITKB_ROOT="$TEST_KB_ROOT" git kb set tasks/test-1 status=draft 2>/dev/null
  GITKB_ROOT="$TEST_KB_ROOT" git kb commit -m "draft" tasks/test-1 2>/dev/null

  local input
  input=$(jq -n \
    --arg cwd "$TEST_KB_ROOT" \
    '{
      hook_event_name: "WorktreeCreate",
      cwd: $cwd,
      hookSpecificOutput: { worktreePath: "/tmp/worktrees/unrelated-branch" }
    }')

  echo "$input" | "$SCRIPTS_DIR/on-worktree.sh" 2>/dev/null

  # Task should still be draft
  local status
  status=$(GITKB_ROOT="$TEST_KB_ROOT" git kb list --type task --json 2>/dev/null | jq -r '.[] | select(.slug == "tasks/test-1") | .status')
  [ "$status" = "draft" ]
}
