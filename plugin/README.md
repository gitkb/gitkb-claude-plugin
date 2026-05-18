# GitKB for Claude Code

Local code intelligence for Claude Code, backed by GitKB's persistent knowledge graph for tasks, decisions, architecture, and team sync.

GitKB lets Claude inspect symbols, callers, callees, impact, dead code, language coverage, and service-edge patterns through the `git-kb` CLI. When you initialize the full KB, those code facts connect to durable tasks, specs, decisions, architecture, and synced team knowledge.

## First Value

Install the plugin, open a Git repo, and ask Claude about the code:

- "What calls `authenticate()`?"
- "What's the blast radius of changing `src/auth.rs`?"
- "Find likely dead code in this project."
- "Index this repo with GitKB and summarize language support."
- "Show route/client service edges."

Claude will use local commands such as:

```bash
git-kb code doctor
git-kb code index
git-kb code symbols
git-kb code callers "<symbol>"
git-kb code callees "<symbol>"
git-kb code impact path/to/file
git-kb code dead
git-kb code query
```

No `.kb` project is required for those code intelligence commands.

## Prerequisites

Install GitKB:

```bash
brew install gitkb/tap/gitkb
# or
curl -fsSL https://get.gitkb.com/install.sh | bash
```

If `git-kb` is missing, the plugin tells Claude how to guide you through installation instead of failing through MCP startup.

## Optional Full KB Setup

When you want persistent tasks, project knowledge, sync, or the full Claude integration, initialize GitKB in the repo:

```bash
git-kb init
git-kb init claude
```

`git-kb init claude` is the source of truth for canonical GitKB Claude assets. It installs shared skills under `.kb/skills` and symlinks Claude-specific views under `.claude/skills`.

## What This Plugin Ships

- one bootstrap skill that teaches Claude to use `git-kb` safely;
- one SessionStart hook that detects GitKB state and injects setup/code-intelligence guidance;
- no mandatory MCP server configuration;
- no vendored copy of the full canonical `git-kb init claude` skill set.

## MCP

GitKB MCP remains supported after full KB setup, but this marketplace plugin does not require MCP for first value. Until code-only MCP exists, Claude should use the CLI path in plain Git repos and full MCP only after `git-kb init && git-kb init claude`.

## Documentation

- [Getting Started](https://gitkb.com/docs/getting-started/quick-start/)
- [Claude Code Guide](https://gitkb.com/docs/getting-started/claude-code/)
- [Code Intelligence](https://gitkb.com/docs/core-concepts/code-intelligence/)
- [MCP Setup](https://gitkb.com/docs/getting-started/mcp-setup/)

## License

MIT
