#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

[ -z "$SESSION_ID" ] && exit 0

# Clear all agent-scoped state files for this session
rm -f /tmp/vector-md-seen-"${SESSION_ID}"-*
