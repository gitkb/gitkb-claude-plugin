#!/usr/bin/env bash
# Shared BATS helpers for hook script tests

# Create a temporary KB project for testing
setup_test_kb() {
  export TEST_DIR="$(mktemp -d)"
  export TEST_KB_ROOT="$TEST_DIR/project"
  mkdir -p "$TEST_KB_ROOT"

  # Initialize a minimal KB
  cd "$TEST_KB_ROOT"
  git init --quiet
  git commit --allow-empty -m "init" --quiet

  GITKB_ROOT="$TEST_KB_ROOT" git kb init --quiet 2>/dev/null || true

  # Create a test task
  GITKB_ROOT="$TEST_KB_ROOT" git kb create \
    --type task \
    --slug tasks/test-1 \
    --title "Test Task" 2>/dev/null

  GITKB_ROOT="$TEST_KB_ROOT" git kb commit -m "test task" tasks/test-1 2>/dev/null

  # Set it active
  GITKB_ROOT="$TEST_KB_ROOT" git kb set tasks/test-1 status=active 2>/dev/null
  GITKB_ROOT="$TEST_KB_ROOT" git kb commit -m "activate" tasks/test-1 2>/dev/null

  export SCRIPTS_DIR="${BATS_TEST_DIRNAME}/../scripts"
}

teardown_test_kb() {
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

# Build a hook input JSON payload
build_hook_input() {
  local event="$1"
  local cwd="${2:-$TEST_KB_ROOT}"
  shift 2 || true

  # Base fields
  local json
  json=$(jq -n \
    --arg event "$event" \
    --arg cwd "$cwd" \
    --arg sid "test-session-$(date +%s)" \
    '{
      hook_event_name: $event,
      session_id: $sid,
      cwd: $cwd,
      transcript_path: "/tmp/test-transcript.jsonl"
    }')

  # Merge extra fields from remaining args (key=value pairs)
  for arg in "$@"; do
    local key="${arg%%=*}"
    local val="${arg#*=}"
    json=$(echo "$json" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')
  done

  echo "$json"
}

# Assert JSON output has hookSpecificOutput with correct eventName
assert_hook_output_valid() {
  local output="$1"
  local expected_event="$2"

  # Must be valid JSON
  echo "$output" | jq empty 2>/dev/null
  [ $? -eq 0 ] || { echo "Output is not valid JSON: $output"; return 1; }

  # Must have hookSpecificOutput
  local event_name
  event_name=$(echo "$output" | jq -r '.hookSpecificOutput.hookEventName // empty')
  [ "$event_name" = "$expected_event" ] || {
    echo "Expected hookEventName=$expected_event, got: $event_name"
    return 1
  }
}

# Assert output is a no-op (empty output, empty JSON, or no hookSpecificOutput)
assert_hook_noop() {
  local output="$1"
  # Empty output is valid noop
  [ -z "$output" ] && return 0
  [ "$output" = "{}" ] && return 0
  local has_hso
  has_hso=$(echo "$output" | jq -r 'has("hookSpecificOutput")' 2>/dev/null)
  [ "$has_hso" = "false" ] && return 0
  echo "Expected no-op, got: $output"
  return 1
}
