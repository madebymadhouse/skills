---
name: workspace-drift
description: Automated drift detection across all repos and live services. Checks git repos for uncommitted changes and unpushed commits, pings service URLs for health, verifies VPS SSH connectivity, checks Coolify API status, and scans key npm projects for outdated packages. Outputs a machine-readable JSON summary and human-readable status. Triggers on "check for drift", "is everything healthy", "workspace drift", "check services", "are my services up", "what's drifted".
compatibility: Designed for Claude Code on WSL. Configure via ~/.secrets/master.env — set VPS_SSH_HOST, COOLIFY_API_URL, COOLIFY_API_TOKEN, DASHBOARD_URL, and any SERVICE_URL_* vars to check. VPS SSH requires a configured alias or host.
allowed-tools: Bash Read
---

# Workspace Drift

Comprehensive drift detection: git state, service health, VPS connectivity, npm freshness. Four focused tools collect data; an orchestrator combines them. Your job is to synthesize the output into a prioritized status report.

## Tools

Each check tool is independent and outputs a JSON array of `{ area, name, status, detail }` objects. Run them individually or use the orchestrator.

### `scripts/check_git.sh`

Check all git repos under `~/dev` for uncommitted changes or unpushed commits.

```
Input:  (none)
Output: [{ area: "git", name: "dev/repo-name", status: "clean"|"drift", detail: "dirty=N ahead=N behind=N" }]
```

### `scripts/check_services.sh`

HTTP health checks for `DASHBOARD_URL` and any `SERVICE_URL_*` vars from `~/.secrets/master.env`.

```
Input:  (none)
Output: [{ area: "service", name: string, status: "healthy"|"down"|"skipped", detail: "http=NNN" }]
```

### `scripts/check_vps.sh`

Check VPS SSH reachability and Coolify API health. Reads `VPS_SSH_HOST`, `COOLIFY_API_URL`, `COOLIFY_API_TOKEN`.

```
Input:  (none)
Output: [{ area: "infra", name: "vps-ssh"|"coolify-api", status: "healthy"|"down"|"skipped", detail: string }]
```

### `scripts/check_npm.sh`

Scan auto-discovered `package.json` projects (up to 20) under `~/dev` for outdated packages.

```
Input:  (none)
Output: [{ area: "packages", name: "dev/repo-name", status: "current"|"outdated", detail: "count=N" }]
```

### `scripts/drift-check.sh` (orchestrator)

Runs all four tools and combines results. Accepts `--only <area>` to run a single check.

```
Usage:  drift-check.sh [--json] [--verbose] [--only git|services|vps|npm]
Output: JSON { timestamp, total, issues, results: [...] }  (to stdout with --json)
        Human summary to stderr always
```

## Step 1 — Run

For a full check:

```bash
~/.claude/commands/workspace-drift/scripts/drift-check.sh --json --verbose
```

For a quick summary (no per-item output):

```bash
~/.claude/commands/workspace-drift/scripts/drift-check.sh --json
```

For a single area only:

```bash
~/.claude/commands/workspace-drift/scripts/drift-check.sh --json --only git
```

## Step 2 — Synthesize

Parse the JSON output (`results` array). Group findings by severity:

### Critical (fix now)
- Any `"status":"down"` service or infra item
- Any repo with `"status":"drift"` that has unpushed commits (`ahead>0` in detail)

### Needs Attention
- Dirty repos with uncommitted changes
- Outdated npm packages

### Healthy
Brief count: "N services up, N repos clean" — no need to list each one unless the user asks.

### Not Configured
Mention any `"status":"skipped"` items so the user knows how to enable them.

Lead with critical items. If everything is clean, say so in one sentence.

## Configuration

Add to `~/.secrets/master.env`:
```
VPS_SSH_HOST=user@your.server.ip
COOLIFY_API_URL=http://your.server.ip:8000
COOLIFY_API_TOKEN=your_token
DASHBOARD_URL=https://your-dashboard-url
SERVICE_URL_MYAPP=https://myapp.example.com
```
