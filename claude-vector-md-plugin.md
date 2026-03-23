# Claude Code Plugin: vector.md Auto-Injection

Automatically inject the nearest `vector.md` file into context whenever Claude Code reads a file, with dedup tracking and compaction-aware invalidation.

## Concept

Many projects use `vector.md` files scattered throughout the directory tree to store local constraints, conventions, and context for a subsystem. This plugin ensures Claude always sees the relevant `vector.md` when reading files in that subtree — without spamming duplicates on consecutive small reads.

## How it works

1. **PostToolUse (Read)** — after every `Read` tool call, a hook walks up from the read file's directory to find the nearest `vector.md`. If it hasn't been injected yet for this agent context, it outputs the content as `additionalContext` back to Claude.
2. **PostCompact** — when context compaction occurs, the hook clears the dedup state so that `vector.md` files are re-injected on next read (since compaction may have dropped them from context).
3. **Agent-aware dedup** — subagents share the same `session_id` as the parent but have separate conversation contexts. The hook scopes dedup state by `session_id + agent_id` so that a `vector.md` injected into a subagent's context doesn't suppress injection into the parent (or another subagent), and vice versa.

## Setup

### 1. Create the hook script

Create `.claude/hooks/inject-vector-md.sh` in your project:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "main"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$SESSION_ID" ] && exit 0
[ -z "$FILE_PATH" ] && exit 0

# Scope dedup per agent context — subagents have separate conversations
STATE_FILE="/tmp/vector-md-seen-${SESSION_ID}-${AGENT_ID}"

# Don't re-inject when reading a vector.md itself
BASENAME=$(basename "$FILE_PATH")
[ "$BASENAME" = "vector.md" ] && exit 0

# Walk up to find nearest vector.md
DIR=$(dirname "$FILE_PATH")
VECTOR_MD=""
while [ "$DIR" != "/" ]; do
  if [ -f "$DIR/vector.md" ]; then
    VECTOR_MD="$DIR/vector.md"
    break
  fi
  DIR=$(dirname "$DIR")
done

[ -z "$VECTOR_MD" ] && exit 0

# Check dedup state
if [ -f "$STATE_FILE" ] && grep -qxF "$VECTOR_MD" "$STATE_FILE"; then
  exit 0
fi

# Record as seen
echo "$VECTOR_MD" >> "$STATE_FILE"

# Emit content back to Claude via additionalContext
CONTENT=$(cat "$VECTOR_MD")
jq -n --arg ctx "--- Constraints from $VECTOR_MD ---
$CONTENT" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
```

### 2. Create the compaction reset script

Create `.claude/hooks/reset-vector-md-state.sh` in your project:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

[ -z "$SESSION_ID" ] && exit 0

# Clear all agent-scoped state files for this session
rm -f /tmp/vector-md-seen-${SESSION_ID}-*
```

### 3. Configure hooks

Add to `.claude/settings.json` (project-scoped) or `~/.claude/settings.json` (global):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/inject-vector-md.sh"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/reset-vector-md-state.sh"
          }
        ]
      }
    ]
  }
}
```

### 4. Make scripts executable

```bash
chmod +x .claude/hooks/inject-vector-md.sh
chmod +x .claude/hooks/reset-vector-md-state.sh
```

## Design decisions

- **Walk-up search**: Mirrors how tools like `.gitignore` or `tsconfig.json` resolve — the nearest ancestor wins. This means deeply nested code inherits constraints from parent directories.
- **Dedup by exact path per agent**: Two different `vector.md` files (e.g., `src/cli/vector.md` and `src/main/vector.md`) are tracked independently. Dedup state is also scoped per agent — the parent and each subagent maintain separate seen-sets, since their conversation contexts are isolated from each other.
- **Compaction = full reset**: On compaction, all agent-scoped entries for the session are cleared. This is intentionally aggressive — it's cheap to re-read small files, and the cost of a missing constraint after compaction is higher than a duplicate injection.
- **No TTL needed**: The `PostCompact` hook eliminates the need for time-based heuristics. The dedup state is only invalid after compaction, and we have a direct signal for that.
- **Skip self-reads**: Reading a `vector.md` file directly doesn't trigger injection of itself — you already have the content.

## Limitations

- Requires `jq` on the system (standard on most dev machines).
- State files accumulate in `/tmp` — they're small and cleaned up on reboot. For explicit cleanup, the session ID scoping prevents cross-session interference.
- If Claude reads files via `Bash` (e.g., `cat foo.ts`), the hook won't fire — it only triggers on the `Read` tool. This is generally fine since Claude Code prefers the `Read` tool.
- The `additionalContext` field in hook output may behave differently across Claude Code versions — test with your version.

## Distribution options

### Project-local (just commit it)

Drop the hooks and scripts into `.claude/` in any repo that uses `vector.md` files. Anyone who clones the repo gets the behavior automatically — no installation step.

```
.claude/settings.json
.claude/hooks/inject-vector-md.sh
.claude/hooks/reset-vector-md-state.sh
```

### Claude Code Plugin (recommended for cross-project use)

Plugins are the native packaging unit for distributable Claude Code extensions. A plugin bundles hooks, skills, MCP servers, and settings together.

```
vector-md-plugin/
├── .claude-plugin/plugin.json     # manifest: name, version, description
├── hooks/hooks.json               # hook definitions (same shape as settings.json hooks)
├── hooks/inject-vector-md.sh
├── hooks/reset-vector-md-state.sh
└── skills/                        # optional slash commands (e.g., /vector-md:status)
```

`plugin.json` example:

```json
{
  "name": "vector-md",
  "version": "1.0.0",
  "description": "Auto-inject nearest vector.md into context on file reads, with dedup and compaction-aware invalidation."
}
```

Users install from a GitHub repo:

```
/plugin install owner/vector-md-plugin
```

Or from an npm package:

```
/plugin install @org/vector-md-plugin
```

### Marketplace (for broader discovery)

A marketplace is a git-hosted catalog that lists available plugins. You can either:

- **Submit to the official Anthropic marketplace** (`claude-plugins-official`) for maximum visibility.
- **Host your own marketplace** — a repo with a `.claude-plugin/marketplace.json` that points to your plugin(s).

```json
{
  "name": "my-plugins",
  "owner": { "name": "Your Name" },
  "plugins": [
    {
      "name": "vector-md",
      "source": "./plugins/vector-md",
      "description": "Auto-inject nearest vector.md on file reads.",
      "version": "1.0.0"
    }
  ]
}
```

Users add the marketplace and install from it:

```
/plugin marketplace add owner/my-marketplace
/plugin install vector-md@my-marketplace
```

### Managed settings (enterprise / org-wide)

Organizations can push plugins and settings to all users via managed settings, including restricting which marketplaces are allowed with `strictKnownMarketplaces`.
