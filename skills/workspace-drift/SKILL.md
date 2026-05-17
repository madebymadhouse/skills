---
name: workspace-drift
description: Automated drift detection across all repos and live services. Checks git repos for uncommitted changes and unpushed commits, pings service URLs for health, verifies VPS SSH connectivity, checks Coolify API status, and scans key npm projects for outdated packages. Outputs a machine-readable JSON summary and human-readable status. Triggers on "check for drift", "is everything healthy", "workspace drift", "check services", "are my services up", "what's drifted".
license: MIT
compatibility: Designed for Claude Code on WSL. Configure via ~/.secrets/master.env — set VPS_SSH_HOST, COOLIFY_API_URL, COOLIFY_API_TOKEN, DASHBOARD_URL, and any service URLs to check. VPS SSH requires a configured alias or host.
allowed-tools: Bash Read
---

# Workspace Drift

Comprehensive drift detection: git state, service health, VPS connectivity, npm freshness. The script handles all checks — your job is to synthesize the output into a prioritized status report.

## Step 1 — Run

```bash
~/.claude/commands/workspace-drift/scripts/drift-check.sh --json --verbose
```

If the user wants just a quick summary: run without `--verbose`.

## Step 2 — Synthesize

Parse the JSON output (`results` array) and stderr summary. Group findings by status:

### Critical (fix now)
- Any `"status":"down"` service
- Any repo with `"status":"drift"` that has unpushed commits

### Needs Attention
- Dirty repos with uncommitted changes (drift, dirty>0)
- Outdated npm packages

### Healthy
Brief count: "N services up, N repos clean" — no need to list each one unless the user asks.

### Not Configured
Mention any checks that were skipped due to missing env vars (e.g. VPS_SSH_HOST not set) so the user knows how to enable them.

Lead with critical items. If everything is clean, say so in one sentence.

## Configuration

Add to `~/.secrets/master.env`:
```
VPS_SSH_HOST=user@your.server.ip
COOLIFY_API_URL=http://your.server.ip:8000
COOLIFY_API_TOKEN=your_token
DASHBOARD_URL=https://your-dashboard-url
```
