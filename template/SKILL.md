---
name: skill-name
description: Replace with a description of what this skill does and when to use it. Include specific trigger phrases.
license: MIT
compatibility: Designed for Claude Code on WSL.
allowed-tools: Bash Read
---

# Skill Name

Brief description of what this skill does.

## Step 1 - Collect

Run the deterministic data collection script. Do not re-run collection commands inline.

```bash
~/.claude/commands/skill-name/scripts/collect.sh
```

## Step 2 - Synthesize

Read the labeled sections from the script output and produce a report. Use only observed data.
