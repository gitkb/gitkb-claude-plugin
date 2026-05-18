---
name: gitkb
description: Use GitKB from Claude Code for local code intelligence first, with optional persistent KB setup. Use when the user asks about callers, callees, impact, symbols, dead code, codebase structure, GitKB setup, tasks, or knowledge management.
---

# GitKB Bootstrap

GitKB is a local CLI for code intelligence and optional durable project memory. Do not assume MCP is available. Use Bash/CLI first unless the project already has full GitKB/Claude setup.

## First Checks

Run these checks before using GitKB:

```bash
command -v git-kb
git rev-parse --show-toplevel
```

If `git-kb` is missing, guide the user to install it:

```bash
brew install gitkb/tap/gitkb
# or
curl -fsSL https://get.gitkb.com/install.sh | bash
```

If the current directory is not a Git repo, explain that code intelligence needs a Git repo.

## Code Intelligence Without `.kb`

GitKB code intelligence works in a normal Git repo without `git-kb init`.

Use these commands for code questions:

```bash
git-kb code doctor
git-kb code index
git-kb code symbols
git-kb code symbols --file path/to/file
git-kb code callers "<symbol>"
git-kb code callees "<symbol>"
git-kb code impact path/to/file
git-kb code dead
git-kb code query
```

Run `git-kb code doctor` first when you need to understand index health or language support. Run `git-kb code index` before first analysis or after large code changes.

Use GitKB code intelligence before broad refactors, symbol renames, dead-code removal, dependency cleanup, service-edge analysis, or questions about how code flows through the repository.

## Full KB Setup

Only guide full setup when the user wants persistent tasks, project memory, sync, or complete Claude integration:

```bash
git-kb init
git-kb init claude
```

After full setup, canonical skills and Claude assets come from `git-kb init claude`. Do not recreate or vendor those assets from this plugin.

## MCP

MCP is supported after full KB setup today. It is not required for first value in Claude Code. If MCP is unavailable, stale, or not initialized, use the CLI fallback and continue.
