# GitKB Plugin for Claude Code

Knowledge base and code intelligence for AI-native development.

GitKB gives your agent persistent memory, structured task management, and deep code understanding — call graphs, impact analysis, dead code detection across 17 languages. All local, all free.

## Prerequisites

Install GitKB:

```bash
brew install gitkb/tap/gitkb
# or
curl -fsSL https://get.gitkb.com/install.sh | bash
```

Requires `jq` for JSON parsing (pre-installed on most systems):

```bash
brew install jq    # macOS
apt install jq     # Debian/Ubuntu
```

Initialize in your project:

```bash
cd your-project
git kb init
```

## What You Get

### 42 MCP Tools

The plugin connects Claude to GitKB's full tool surface:

| Category | Tools |
|----------|-------|
| **Knowledge Base** | Create, show, list, search, checkout, commit, diff, board, graph |
| **Code Intelligence** | Symbols, callers, callees, impact analysis, dead code, refs |
| **AI** | Semantic search, smart context assembly |
| **Sync** | Push, pull, remote management |

### 4 Skills

Skills that Claude invokes automatically based on context:

- **gitkb** — Core KB management: documents, tasks, context, commits
- **understand** — Analyze a file or symbol's structure and dependencies
- **before-refactor** — Safety check: callers, callees, and blast radius before changes
- **explore** — Semantic and structural search across code and documents

### 12 Slash Commands

Type `/kb-` to see all commands:

| Command | Description |
|---------|-------------|
| `/kb-start` | Start a task — load context, checkout, understand scope |
| `/kb-board` | View the kanban board |
| `/kb-tasks` | List and filter tasks |
| `/kb-create` | Create a document (task, spec, incident, note) |
| `/kb-status` | Show workspace changes |
| `/kb-commit` | Commit KB changes |
| `/kb-search` | Search the knowledge base |
| `/kb-context` | Load project context |
| `/kb-review` | Review task against acceptance criteria |
| `/kb-close` | Complete a task with verification |
| `/kb-progress` | Log progress on a task |
| `/kb-handoff` | End-of-session context handoff |

## Example Prompts

After installing, try asking Claude:

- "What functions call `authenticate()`?"
- "What's the blast radius of changing `src/auth.rs`?"
- "Find dead code in this project"
- "Create a task for the login bug we found"
- "Show me the kanban board"
- "What's the impact of modifying `UserService`?"

### 7 Lifecycle Hooks

Hooks fire automatically during Claude Code sessions:

| Hook | What it does | Config key | Default |
|------|-------------|------------|---------|
| SessionStart | Inject active task context, start daemon | `context_injection` | on |
| PreToolUse(Agent) | Inject task context into subagent prompts | `context_injection` | on |
| PostToolUse(Bash) | Auto-link git commits to active task | `auto_commit_link` | on |
| WorktreeCreate | Bind new worktrees to matching KB tasks | `auto_worktree_bind` | on |
| Stop | Append progress entry to active task | `auto_progress` | off |
| UserPromptSubmit | Inject relevant KB docs per prompt | `prompt_context` | off |
| PostToolUse(Write/Edit) | Track file changes | — | always |

### Configuration

Toggle hook features in `.kb/config.toml`:

```toml
[hooks]
context_injection = true    # SessionStart + agent spawn context
auto_commit_link = true     # Auto-link commits to active task
auto_worktree_bind = true   # Match worktree branches to tasks
auto_progress = false       # Append progress entries on Stop
prompt_context = false       # Per-prompt KB context injection
```

All keys are optional — defaults apply when missing. Changes take effect on the next hook invocation (no restart needed).

## Documentation

- [Getting Started](https://gitkb.com/docs/getting-started/quick-start/)
- [MCP Setup](https://gitkb.com/docs/getting-started/mcp-setup/)
- [Claude Code Guide](https://gitkb.com/docs/getting-started/claude-code/)
- [Code Intelligence](https://gitkb.com/docs/core-concepts/code-intelligence/)

## License

MIT
