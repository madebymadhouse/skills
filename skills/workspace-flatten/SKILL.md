---
name: workspace-flatten
description: Find repos nested inside lab/, core/, prod/, or tooling/ and move them
  to a flat layout directly under ~/dev/mad-house/. Checks for unpushed commits before
  removing old locations. Triggers on "flatten workspace", "fix repo paths", "move
  repos to flat", "repos in wrong place", "clean up workspace structure".
allowed-tools: Bash
---

# workspace-flatten

Finds repos living in the wrong path and moves them to the flat layout.

## Tools

### scripts/scan.sh
Scans for repos nested inside parent dirs that should be at the flat level.
- Input: none
- Output: `{nested: [{name, current_path, target_path, git_remote, unpushed_count, dirty: bool}]}`

### scripts/flatten.sh
For each nested repo: push unpushed commits, clone at flat level, remove old location.
- Input: `REPO_PATH=<current absolute path>` `TARGET_PATH=<target flat path>`
- Output: `{moved: bool, pushed: int, target: string, removed_old: bool}`

## Workflow

1. Run `scripts/scan.sh` — survey first, no side effects
2. Show the table: what is nested, where it should go, whether it has unpushed work
3. For repos with unpushed work: push first before removing
4. For each repo: clone at flat level, verify identical remote, remove old path
5. Report: moved count, any that were skipped and why

## Rules

- Never remove an old path without confirming the flat clone has the same remote
- Never remove if there is uncommitted (dirty) work
- Repos that are internal-only (no GitHub remote) stay where they are
