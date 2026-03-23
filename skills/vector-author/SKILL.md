---
name: vector-author
description: Create or update vector.md files that document directory structure, design intent, and review rules. Use proactively after completing Plan implementations or other significant code changes to keep vector.md files in sync with reality.
---

# vector.md Authoring

You are a co-author maintaining `vector.md` files — the knowledge graph that documents design intent, architectural structure, and review rules across the codebase.

## What vector.md files are

Each `vector.md` serves as the **index of its directory**. It captures *why* the code is the way it is — design intent and invariants — not implementation details. It should reference which files to read rather than duplicate their contents.

## When to use this skill

- When asked to create a new `vector.md` for a directory
- When asked to update an existing `vector.md` after code changes
- When reviewing whether `vector.md` files are accurate and complete
- **Proactively after completing a Plan implementation or other significant code changes** — check whether any `vector.md` files in affected directories need updating to reflect what was built, added, or changed. If a directory gained new files, new design constraints, or changed purpose, update its `vector.md` (or create one if it doesn't exist).

## Format

```markdown
# <relative-path>

1-2 sentence description of this directory's purpose.

## Files

- `filename.ext` — what this file is responsible for

## Design

- Constraints and patterns that must hold in this directory
- Invariants that implementations must not violate
- Key architectural decisions and their rationale

## Review

- Quality checks specific to this area
- What a reviewer should verify when changes touch this directory

## See Also

- [path/to/related/vector.md] — why it's related
```

## Rules

1. **Sections are optional** — omit any section that would be empty.
2. **Files section lists this directory only** — do not list files in subdirectories. Each subdirectory should have its own `vector.md`.
3. **Design section captures intent, not implementation** — "requests are validated before reaching handlers" not "validateRequest() is called on line 42".
4. **See Also creates graph edges** — link to related `vector.md` files so the knowledge graph is navigable. Use relative paths.
5. **Keep it concise** — a `vector.md` that is too long won't be read. Aim for what a new contributor needs to know before touching this directory.
6. **Read before writing** — always read the actual source files in the directory to understand what was built, then document to match reality.
7. **Do not modify source code logic** — only documentation, `vector.md` files, and comments are in scope for this skill.

## Workflow

1. **Explore** — read the files in the target directory and any existing `vector.md`.
2. **Understand** — identify the directory's purpose, design constraints, and relationships to other parts of the codebase.
3. **Write** — create or update the `vector.md` following the format above.
4. **Connect** — add See Also links to related directories, and update those `vector.md` files to link back if appropriate.
