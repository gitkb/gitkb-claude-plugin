---
allowed-tools:
  - mcp__gitkb__kb_show
  - mcp__gitkb__kb_smart_context
  - mcp__gitkb__kb_impact
  - mcp__gitkb__kb_callers
  - mcp__gitkb__kb_callees
  - mcp__gitkb__kb_symbols
  - mcp__gitkb__kb_list
  - mcp__gitkb__kb_create
  - mcp__gitkb__kb_commit
  - mcp__gitkb__kb_graph
  - Bash(git kb:*)  # CLI fallback: `git kb code symbols "name"` (positional arg, not --search). Never suppress stderr.
description: Decompose a task into subtasks using code intelligence — callers, impact analysis, and symbol structure
user-invocable: true
argument-hint: "<task-slug>"
---

Decompose a task into independently implementable subtasks using code intelligence.

**Input:** `$ARGUMENTS`

The argument should be a task slug (e.g. `tasks/harmony-42`).

## Steps

### 1. Load the Task

Use `kb_show` to load the task. Parse its goals, acceptance criteria, and any referenced files/modules.

### 2. Analyze Code Scope

Use `kb_smart_context` with the task slug to get code context with call graph traversal. This reveals:
- Which files and symbols are directly referenced
- Callers and callees (transitive dependencies)
- Relevance scores for each code item

For each referenced file, use `kb_impact` to assess blast radius:
- How many files depend on it?
- How many callers would be affected by changes?

**Handling ambiguous symbols:** If `kb_callers` returns multiple candidates for a symbol name, use the fully qualified `file::kind::name` symbol ID from the candidates list (e.g. `src/auth.rs::fn::login` instead of just `login`).

### 3. Identify Natural Boundaries

Group the work into independent units based on:
- **Module boundaries** — changes within one module that don't affect others
- **Caller isolation** — changes with 0-2 callers vs 10+ callers
- **Test boundaries** — each subtask should be independently testable
- **Dependency ordering** — if B depends on A's changes, A must complete first

### 4. Propose Subtasks

For each proposed subtask, include:
- Title and brief description
- Specific files and symbols involved
- Caller count and impact assessment (LOW/MEDIUM/HIGH)
- `blockedBy` relationships (which subtasks must complete first)
- Estimated scope indicator based on caller/file counts

### 5. Present the Decomposition

Show a structured breakdown:

```markdown
## Decomposition: [parent task title]

### Independent (can run in parallel)
1. **[subtask title]** — [files] — [N callers] — LOW impact
2. **[subtask title]** — [files] — [N callers] — MEDIUM impact

### Sequential (has dependencies)
3. **[subtask title]** — depends on #1 — [files] — HIGH impact
4. **[subtask title]** — depends on #1, #2 — [files] — MEDIUM impact

### Verification
5. **Verify [parent task]** — run tests, check all criteria
```

### 6. Create Subtasks (on approval)

Ask the user: "Create these as child tasks? (They'll be linked to the parent with `blockedBy` relationships.)"

If approved, for each subtask:
1. `kb_create` with `type: "task"`, auto-incremented slug, parent link
2. Include specific files, symbols, and caller counts in the acceptance criteria
3. `kb_commit` with message: `"Decompose: [parent title] → [N] subtasks"`

Show the final board state with the new subtasks.
