---
name: skill-publish
description: Package a locally built skill and publish it to the madebymadhouse/skills repo. Handles copying files, reviewing for internals to scrub, updating the README table, and pushing. Use when a skill has been built or updated locally and needs to go into the public skills repo. Triggers on "publish skill", "push this skill", "add skill to the repo", "package my skill".
argument-hint: <skill-name>
compatibility: Designed for Claude Code at Mad House. Requires ~/dev/mad-house/skills/ to be cloned and up to date.
allowed-tools: Bash Read Edit
disable_model_invocation: true
---

# Skill Publish

Takes a skill from `~/.claude/commands/` and packages it into the public skills repo.

## Arguments

Skill to publish: $ARGUMENTS

## Step 1 — Stage

```bash
~/.claude/commands/skill-publish/scripts/stage.sh "$ARGUMENTS"
```

If the script exits with an error, stop and explain what's wrong.

## Step 2 — Review for internals

Read every file in `~/dev/mad-house/skills/skills/$ARGUMENTS/` and check for:

- Hardcoded IPs or hostnames
- Specific container or service names from Mad House infrastructure
- Orinadus references of any kind
- Email addresses or personal information
- Tokens, API keys, passwords, or anything that looks like a secret
- Hardcoded paths that are specific to this machine (e.g. `/home/samhc/` beyond `~`, specific org names in `~/dev/`)

Mad House branding and org identity (e.g. `madebymadhouse`, `mad-house/lab`) is fine to keep. Generic paths using `~` or `$HOME` are fine.

If you find anything that needs scrubbing, fix it before continuing.

## Step 3 — Update the README

Open `~/dev/mad-house/skills/README.md` and add the skill to the correct section of the skills table. Use the same one-line description style as existing entries.

If it does not fit an existing section, add a new one.

## Step 4 — Commit and push

```bash
cd ~/dev/mad-house/skills && git add . && git commit -m "Add $ARGUMENTS skill

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>" && git push
```

Confirm the push succeeded and give the user the GitHub URL for the skill folder.
