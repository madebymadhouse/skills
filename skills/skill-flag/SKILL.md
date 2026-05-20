---
name: skill-flag
description: Batch add or remove frontmatter fields across one or more SKILL.md files
allowed-tools: Bash
disable_model_invocation: true
---

# Skill Flag

Add or remove frontmatter fields across multiple SKILL.md files in one shot. No manual editing per file.

## Input

- `ACTION` - `add` or `remove`
- `SKILLS` - space-separated skill names (or `--all` for every installed skill)
- `FIELD` - the full frontmatter line to add or the key to remove (e.g. `disable_model_invocation: true`)

## Usage

```bash
# Add a flag
~/.claude/commands/skill-flag/scripts/flag.sh add "skill1 skill2 skill3" "disable_model_invocation: true"

# Remove a flag
~/.claude/commands/skill-flag/scripts/flag.sh remove "skill1 skill2" "disable_model_invocation"

# Apply to all installed skills
~/.claude/commands/skill-flag/scripts/flag.sh add --all "user_invocable: false"
```

## What the script does

- For `add`: inserts the field line before the closing `---` of the YAML frontmatter, skipping if the key already exists
- For `remove`: deletes any line matching the key from the frontmatter block
- Reports a per-skill result: `added`, `removed`, `already-present`, `already-absent`, `no-frontmatter`, `not-found`

## Step 1 - Run

```bash
~/.claude/commands/skill-flag/scripts/flag.sh <action> "<skills>" "<field>"
```

## Step 2 - Report

Parse the JSON output and present a clean table of what changed.
