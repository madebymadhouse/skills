---
name: pull-urchin
description: Pull recent events from Urchin into the vault. Runs pull-urchin.py which hits /recent, maps events by kind to vault markdown files, and commits. Triggers on "pull urchin", "sync urchin to vault", "push urchin events to vault", "update vault from urchin", "pull health data", "pull purchases to vault".
allowed-tools: Bash
disable_model_invocation: true
triggers:
  - "pull urchin"
  - "sync urchin to vault"
  - "push urchin events to vault"
  - "update vault from urchin"
  - "pull health data"
  - "pull purchases to vault"
  - "pull calendar to vault"
  - "urchin to vault"
---

# Pull Urchin

Fetch events from Urchin and write them into the vault.

## Run

```bash
bash ~/.claude/commands/pull-urchin/scripts/pull.sh
```

## With options

Set `PULL_URCHIN_SCRIPT` to the path of your `pull-urchin.py` script, or pass args directly:

```bash
# Pull last N hours (default: 24)
PULL_URCHIN_SCRIPT=~/scripts/pull-urchin.py bash ~/.claude/commands/pull-urchin/scripts/pull.sh --hours 72

# Pull more events
bash ~/.claude/commands/pull-urchin/scripts/pull.sh --limit 500

# Dry run (no commit)
bash ~/.claude/commands/pull-urchin/scripts/pull.sh --dry-run
```

## What it does

1. Reads cursor from `~/.local/share/urchin/overseer-cursor.txt`
2. Hits `http://127.0.0.1:18799/recent` for events after cursor
3. Groups events by kind and writes to vault paths:
   - health_metric: `wiki/personal/health/YYYY-MM.md`
   - purchase: `wiki/personal/purchases/YYYY-MM.md`
   - calendar_event: `wiki/personal/calendar/YYYY-MM.md`
   - location: `wiki/personal/location/YYYY-MM.md`
   - search_query: `wiki/personal/search/YYYY-MM.md`
   - conversation/command/commit: `wiki/systems/dev-activity/YYYY-MM.md`
4. Git commits and pushes vault

## Verify

```bash
ls ~/vault/wiki/personal/health/
ls ~/vault/wiki/personal/purchases/
```
