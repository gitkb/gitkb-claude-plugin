---
allowed-tools:
  - mcp__gitkb__kb_show
  - mcp__gitkb__kb_smart_context
  - mcp__gitkb__kb_board
  - mcp__gitkb__kb_list
  - mcp__gitkb__kb_graph
  - Agent
  - SendMessage
  - Skill
description: Parallel implementation — decompose a task and dispatch kb-worker agents for each subtask
user-invocable: true
argument-hint: "<task-slug>"
context: fork
agent: kb-coordinator
---

Implement a task in parallel by decomposing it and dispatching worker agents.

**Input:** `$ARGUMENTS`

The argument should be a task slug (e.g. `tasks/harmony-42`).

## Steps

### 1. Decompose

Run `/kb-decompose $ARGUMENTS` to break the task into subtasks with dependency relationships.

If the task is already decomposed (has child tasks visible via `kb_graph`), skip this step and use existing subtasks.

### 2. Verify Readiness

Check `kb_board` to confirm:
- All subtasks are created and linked
- No circular dependencies
- Independent subtasks are identifiable (no `blockedBy`)

### 3. Dispatch Workers

For each independent subtask (no unresolved `blockedBy`):
1. Spawn a `kb-worker` agent with `isolation: worktree`
2. Pass the subtask slug in the agent prompt
3. Run agents in parallel where possible

For sequential subtasks, wait for blockers to complete before dispatching.

### 4. Monitor

Use `kb_board` to track progress. Workers auto-report via hooks.

When all subtasks complete, verify the parent task's acceptance criteria are satisfied.

### 5. Finalize

If all parent criteria are met, recommend closing with `/kb-close <parent-slug>`.
