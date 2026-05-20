---
name: workspace-sync
description: Fast-forward pull all clean git repos under ~/dev. Skips dirty repos and repos with no remote. Safe to run at the start of any session to get all repos up to date. Triggers on "sync repos", "pull all repos", "update all repos", "get latest", "sync my workspace", "pull everything".
license: MIT
compatibility: Designed for Claude Code on WSL. Requires git and repos under ~/dev with remotes configured.
allowed-tools: Bash Read
disable_model_invocation: true
---

# Workspace Sync

Pulls all clean repos under `~/dev` that are behind their upstream. The script handles all the git operations - your job is to summarize the result.

## Step 1 - Sync

```bash
~/.claude/commands/workspace-sync/scripts/sync.sh
```

## Step 2 - Report

Read the output and summarize:

- How many repos were pulled (and which ones, if >0)
- How many were already up to date
- Which repos were skipped and why (dirty / no remote / ff not possible)

If any repos were skipped as dirty: mention them by name so the user knows they need attention.

Keep it to one paragraph unless there are many skipped repos.
