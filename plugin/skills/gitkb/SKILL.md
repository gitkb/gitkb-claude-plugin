---
name: gitkb
description: Use GitKB from Claude Code for local code intelligence first, with full persistent knowledge graph setup when the user wants tasks, decisions, architecture, sync, or team context. Use when the user asks about callers, callees, impact, symbols, dead code, codebase structure, GitKB setup, tasks, or knowledge management.
---

# GitKB Bootstrap

GitKB is a local CLI for code intelligence and a persistent knowledge graph for tasks, decisions, architecture, sync, and team context. Do not assume MCP is available. Use Bash/CLI first unless the project already has full GitKB/Claude setup.

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

## Prefer Code Intelligence Over Grep

When exploring code relationships, prefer `git-kb code` over grep. Grep matches text; `git-kb code` understands the AST and call graph.

| Instead of | Use |
|---|---|
| grep for function callers | `git-kb code callers "<symbol>" --json` |
| grep for definitions | `git-kb code symbols --file <path> --json` |
| grep to assess change impact | `git-kb code impact <path> --json` |
| manual dead code search | `git-kb code dead --json` |

## Code Intelligence Without `.kb`

GitKB code intelligence works in a normal Git repo without `git-kb init`.

Use these commands for code questions:

```bash
git-kb code doctor --json
git-kb code index
git-kb code symbols --json
git-kb code symbols --file path/to/file --json
git-kb code callers "<symbol>" --json
git-kb code callees "<symbol>" --json
git-kb code impact path/to/file --json
git-kb code dead --json
git-kb code query hotspots --json
```

Run `git-kb code doctor --json` first when you need to understand index health or language support. Run `git-kb code index` before first analysis or after large code changes.

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
