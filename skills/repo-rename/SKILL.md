---
name: repo-rename
description: Rename a local repo folder and update all AGENTS.md and memory references to the old name
allowed-tools: Bash
disable_model_invocation: true
---

# Repo Rename

Renames a local repo directory and surgically updates every reference to the old name across all AGENTS.md files and memory.

## Input

- `OLD_NAME` — current folder name (e.g. `urchin-rust`)
- `NEW_NAME` — target folder name (e.g. `urchin`)

## Step 1 — Find the repo

```bash
~/.claude/commands/repo-rename/scripts/rename.sh OLD_NAME NEW_NAME
```

The script:
1. Locates the repo under `~/dev` (maxdepth 3)
2. Validates it is a git repo
3. Renames the folder
4. Updates git remote URL if it contains the old name
5. Replaces all occurrences in `~/AGENTS.md`, `~/dev/*/AGENTS.md`, and all `~/.claude/projects/*/memory/*.md` files
6. Outputs a JSON summary of every file changed and replacement count

## Step 2 — Report

Parse the JSON and report:
- New path
- Remote URL change (old → new), if any
- Files updated and replacement counts
- Any files that were skipped or could not be read

If the script exits non-zero, stop and report the error. Do not proceed.
