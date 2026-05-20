---
name: session-close
description: End-of-session workspace sync - pull clean behind repos, push clean ahead repos, report dirty repos
allowed-tools: Bash
disable_model_invocation: true
---

# Session Close

One command to end a session cleanly. Pulls all repos that are behind (fast-forward only), pushes all repos that are ahead, and reports everything dirty so nothing is left dangling.

## Step 1 - Scan

```bash
~/.claude/commands/workspace-audit/scripts/git-scan.sh --fetch
```

Uses the shared git scanner with `--fetch` so ahead/behind counts are accurate.

## Step 2 - Sync

```bash
~/.claude/commands/session-close/scripts/close.sh
```

The script:
1. Calls git-scan.sh --fetch internally
2. For each repo that is **only behind** (ahead=0, behind>0, not dirty): `git pull --ff-only`
3. For each repo that is **only ahead** (ahead>0, behind=0, not dirty): `git push`
4. Skips repos that are dirty or have both ahead and behind (diverged)
5. Outputs a summary: pulled, pushed, skipped-dirty, skipped-diverged

## Step 3 - Report

After the script completes, present the result as a clean summary table:

| Status | Count | Repos |
|--------|-------|-------|
| Pulled | N | ... |
| Pushed | N | ... |
| Dirty (action needed) | N | ... |
| Diverged (action needed) | N | ... |
| Clean | N | ... |

Dirty repos need human attention. List them explicitly with their dirty file count.
