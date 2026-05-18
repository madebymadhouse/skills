---
name: gh-org-audit
description: Audit one or more GitHub orgs for stale live repos, local clones of
  archived repos, and repos missing standard files. Use when cleaning up the org,
  doing a monthly review, or when something feels disorganized. Triggers on "audit
  github", "audit the org", "org cleanup", "what repos are stale", "org health",
  "github audit".
allowed-tools: Bash
---

# gh-org-audit

Full health picture of your GitHub orgs: stale repos, missing files, archived repo clutter.

## Tools

### scripts/audit.sh
Audits all configured orgs and reports: stale live repos, archived repos with local clones, repos missing standard files.
- Input: `AUDIT_ORGS=<"orgname:~/local/path orgname2:~/local/path2">` — space-separated org:localpath pairs
- Input: `STALE_DAYS=<int>` days since last push to consider stale (default: 90)
- Output:
  ```json
  {
    "orgs": {
      "<org1>": {stale, missing_standard_files, local_archived_clones},
      "<org2>": {...}
    },
    "summary": {live, archived, stale}
  }
  ```

## Workflow

1. Determine the orgs and their local paths, then run:
   `AUDIT_ORGS="myorg:~/dev/projects" bash scripts/audit.sh`
2. Report: stale repos first (most actionable), then missing standard files, then local archived clones
3. For each stale repo: suggest archive or note active reason
4. For each local clone of an archived repo: suggest removing the local dir
5. Do NOT delete anything without confirmation
