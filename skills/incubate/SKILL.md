---
name: incubate
description: Mad House project lifecycle manager. Create, list, stage, promote, ship, and archive projects in ~/dev/mad-house/lab. Every project has a stage (concept → prototype → building → shipped → maintained → archived) and a type (code, game, creative, tool, experiment, content, bot). Use when managing lab projects, moving a project between stages, promoting from lab to a GitHub org, marking something as shipped, or archiving a project.
argument-hint: <command> [args] — e.g. "new my-idea --type experiment --desc '...'" or "list" or "stage my-idea prototype" or "ship my-idea"
compatibility: Designed for Claude Code at Mad House. Requires ~/dev/mad-house/lab/ directory, Python 3, and the gh CLI for GitHub operations (promote command).
allowed-tools: Bash Read
---

# Incubate

Mad House project lifecycle manager. Every project in the lab has a stage and a type — no rigid gates, just honest tracking of where something is.

## Arguments

The user wants to: $ARGUMENTS

## Commands

| Command | What it does |
|---------|-------------|
| `new <name> [--type TYPE] [--desc "..."]` | Create a new lab project |
| `list [--all]` | Show active incubations (--all includes archived) |
| `stage <name> <stage>` | Move to: concept, prototype, building, shipped, maintained, archived |
| `promote <name> [--org ORG] [--public]` | Create GitHub repo from lab project |
| `ship <name>` | Mark shipped + print type-specific ship checklist |
| `archive <name> [--reason "..."]` | Retire gracefully |
| `info <name>` | Show full metadata JSON |

## Step 1 — Run

```bash
~/.claude/commands/incubate/scripts/incubate.sh $ARGUMENTS
```

## Step 2 — Report

For `list`: present the table cleanly.
For `new` / `stage` / `ship` / `archive`: echo the script output, then add context if helpful (e.g. suggest the next stage or next command).
For `promote`: confirm the repo was created and show the next step (push).
For `info`: show the JSON.

If the user's intent is ambiguous (e.g. "I want to start a new idea"), ask for the name and type before running.
