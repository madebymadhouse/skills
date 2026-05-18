---
name: agents-md-sync
description: Verify that AGENTS.md files are accurate by checking every path they
  reference against the actual filesystem. Reports stale paths, missing repos, and
  repos not mentioned in AGENTS.md. Triggers on "is agents.md accurate", "check agents.md",
  "sync agents.md", "verify agents.md", "agents.md drift", "update agents.md".
allowed-tools: Bash, Read, Edit
---

# agents-md-sync

AGENTS.md cannot lie. This skill verifies every path claim it makes and reports drift.

## Tools

### scripts/check.sh
Reads AGENTS.md files, extracts all path references, checks each against the filesystem.
- Input: `TARGET_DIR=<directory to check AGENTS.md in>` (default: `$HOME`)
- Output:
  ```json
  {
    "file": string,
    "valid": [{path, exists}],
    "stale": [{path, expected_at}],
    "untracked": [{path, note}]
  }
  ```

## Workflow

1. Run `TARGET_DIR="$HOME" bash scripts/check.sh` for the root AGENTS.md
2. Run for each project subdirectory that has its own AGENTS.md
3. For each stale path: propose the fix (remove the line, update the path, or note the drift)
4. Apply fixes only after confirming with the user

## What counts as a stale reference

- A path like `~/dev/mad-house/foo` where `foo` does not exist
- A tool command like `~/dev/mad-house/tooling/bar.sh` where `bar.sh` does not exist
- A repo mentioned in a workspace table that is not cloned locally
