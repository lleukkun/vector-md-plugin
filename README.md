# vector-md — Claude Code Plugin

Auto-inject the nearest `vector.md` file into Claude's context whenever it reads a file, so design constraints and conventions are always visible.

## What it does

Many projects use `vector.md` files throughout the directory tree to document design intent, architectural constraints, and review rules for each subsystem. This plugin ensures Claude always sees the relevant `vector.md` when working in that subtree — without duplicate injections.

- **PostToolUse (Read)** — after every file read, walks up the directory tree to find the nearest `vector.md` and injects it into context
- **PostCompact** — clears dedup state after context compaction so constraints are re-injected
- **Agent-aware dedup** — parent and subagents maintain separate seen-sets, since their contexts are isolated
- **Workspace-bounded** — the search stops at the workspace root and never traverses above it

## Install

```
/plugin install lleukkun/vector-md-plugin
```

## What goes in a vector.md

Each `vector.md` serves as the index of its directory — capturing *why* the code is the way it is, not implementation details.

```markdown
# path/to/directory

Brief description of this directory's purpose.

## Files

- `foo.ts` — what this file is responsible for

## Design

- Constraints and patterns that must hold
- Key architectural decisions and rationale

## Review

- What a reviewer should verify when changes touch this directory

## See Also

- [path/to/related/vector.md] — relationship
```

Sections are optional — omit any that would be empty.

The plugin includes a `/vector-md:vector-author` skill that guides Claude through creating and updating these files. Invoke it with:

```
/vector-md:vector-author
```

## Requirements

- [Claude Code](https://claude.com/claude-code) with plugin support
- `jq` (pre-installed on most dev machines)
