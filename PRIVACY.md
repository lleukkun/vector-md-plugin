# Privacy Policy — vector-md Plugin

**Last updated:** 2026-03-24

## Overview

The vector-md plugin operates entirely on your local machine within the Claude Code process. It does not collect, transmit, or store any user data.

## What the plugin does

When Claude Code reads a file, the plugin walks up the directory tree to find the nearest `vector.md` file and injects its contents into the conversation context. It also maintains a temporary dedup state file (under `/tmp/`) to avoid re-injecting the same `vector.md` within a single session. This state file is scoped to the session and is automatically cleaned up on context compaction.

## Data collection

**None.** This plugin:

- Does not collect any personal information
- Does not collect any telemetry or usage analytics
- Does not make any network requests
- Does not send any data to external servers or third parties
- Does not read, access, or process any files other than `vector.md` files within your workspace

## Data storage

The only data written to disk is a temporary dedup state file at `/tmp/vector-md-seen-<session_id>-<agent_id>`. This file contains only the paths of `vector.md` files already injected in the current session. These files are ephemeral and removed when the session's context is compacted.

## Data transmission

**None.** The plugin runs entirely locally. It has no networking code and makes zero outbound connections.

## Permissions

The plugin requires only:

- Read access to `vector.md` files within your workspace directory tree
- Write access to `/tmp/` for session-scoped dedup state

## Third-party services

This plugin does not integrate with or send data to any third-party services.

## Changes to this policy

Updates to this policy will be reflected in this file within the plugin repository.

## Contact

For questions about this privacy policy, open an issue at [github.com/lleukkun/vector-md-plugin](https://github.com/lleukkun/vector-md-plugin).
