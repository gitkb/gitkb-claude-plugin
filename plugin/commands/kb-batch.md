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

### 2. Build Dispatch Order

Use `kb_graph` and `kb_show` to build the dependency graph from `blockedBy` relationships:
- For each subtask, inspect its `blockedBy` field via `kb_show`
- Compute the set of immediately runnable tasks (those with no unresolved blockers)
- Use `kb_board` only for status/progress tracking, not for dependency resolution

### 3. Dispatch Workers

For each runnable subtask (all `blockedBy` dependencies are completed):
1. Spawn a `kb-worker` agent with `isolation: worktree`
2. Pass the subtask slug in the agent prompt
3. Run agents in parallel where possible

For sequential subtasks, wait for blockers to complete before dispatching.

### 4. Monitor

Use `kb_board` to track progress. Workers auto-report via hooks.

When all subtasks complete, verify the parent task's acceptance criteria are satisfied.

### 5. Finalize

If all parent criteria are met, recommend closing with `/kb-close <parent-slug>`.
