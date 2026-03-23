#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "main"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
WORKSPACE=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$SESSION_ID" ] && exit 0
[ -z "$FILE_PATH" ] && exit 0
[ -z "$WORKSPACE" ] && exit 0

# Scope dedup per agent context — subagents have separate conversations
STATE_FILE="/tmp/vector-md-seen-${SESSION_ID}-${AGENT_ID}"

# Don't re-inject when reading a vector.md itself
BASENAME=$(basename "$FILE_PATH")
[ "$BASENAME" = "vector.md" ] && exit 0

# Walk up to find nearest vector.md, stopping at workspace root
DIR=$(dirname "$FILE_PATH")
VECTOR_MD=""
while true; do
  if [ -f "$DIR/vector.md" ]; then
    VECTOR_MD="$DIR/vector.md"
    break
  fi
  # Stop at workspace root — don't traverse above it
  [ "$DIR" = "$WORKSPACE" ] && break
  PARENT=$(dirname "$DIR")
  # Safety: stop if we can't go higher (shouldn't happen given the workspace check)
  [ "$PARENT" = "$DIR" ] && break
  DIR="$PARENT"
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
