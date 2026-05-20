---
name: urchin-collect
description: Run Urchin connectors to ingest new events. Can run all connectors or a specific one. Shows which import directories have data and which are empty. Triggers on "run urchin", "collect urchin", "sync urchin", "ingest from X", "run collectors", "pull in data", "urchin collect", "update journal".
allowed-tools: Bash
disable_model_invocation: true
triggers:
  - "run urchin"
  - "collect urchin"
  - "sync urchin"
  - "urchin collect"
  - "run collectors"
  - "pull in data"
  - "update journal"
  - "ingest from"
  - "ingest health data"
  - "ingest bank data"
  - "ingest calendar"
---

# Urchin Collect

Run Urchin connectors and show what was ingested.

## Check available import sources

```bash
bash ~/.claude/commands/urchin-collect/scripts/collect.sh --status
```

## Run all collectors

```bash
urchin collect
```

## Run a specific connector

```bash
# $ARGUMENTS should be one of: claude, git, shell, copilot, gemini, codex, opencode, google-takeout, apple-health, bank-csv, calendar
urchin collect $ARGUMENTS
```

## Drop import files first

| Connector | Drop files here |
|---|---|
| apple-health | `~/.local/share/urchin/imports/apple-health/export.xml` |
| bank-csv | `~/.local/share/urchin/imports/bank/*.csv` |
| calendar | `~/.local/share/urchin/imports/calendar/*.ics` |
| google-takeout | `~/.local/share/urchin/imports/google-takeout/` (unzipped Takeout dir) |

## Verify

```bash
urchin recent --n 10
```
