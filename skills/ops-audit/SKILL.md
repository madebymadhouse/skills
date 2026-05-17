---
name: ops-audit
description: Full eagle-eye ops audit across both WSL and a remote VPS simultaneously. Use when the user wants a complete picture of everything — what's running locally and in production, what's live vs local-only, cross-environment dependency map. Triggers on phrases like "full audit", "audit everything", "ops audit", "what do I have running", "overview of my stack", "eagle eye view", or "show me everything".
compatibility: Designed for Claude Code on WSL. Requires both wsl-audit and vps-audit skills installed at ~/.claude/commands/. Requires SSH access configured as "vps" alias in ~/.ssh/config.
allowed-tools: Bash Read
---

# Ops Audit

Full stack audit: local WSL machine + remote VPS. Both collection scripts run in parallel. Synthesize a unified cross-environment report from the combined output.

## Step 1 — Collect both environments simultaneously

Run these in parallel — do not wait for one before starting the other:

```bash
~/.claude/commands/wsl-audit/scripts/collect-wsl.sh
```

```bash
~/.claude/commands/vps-audit/scripts/collect-vps.sh
```

## Step 2 — Synthesize unified report

Use only observed data. No guessing.

---

## Local Machine (WSL)
**Role:** Dev machine. Code lives here. No public-facing services.

### Dev Workspace
From WSL PROJECT_LANGS and DEV_TREE. For each repo in ~/dev: name, runtime, one-line purpose (infer from name + structure). Group by top-level org directory.

### AI Tooling
From WSL AI_CLIENTS, OLLAMA_MODELS, SKILLS, AGENT_MANIFEST:
- Ollama models installed
- Claude Code skills registered
- Agent fleet: count + key roles
- Other AI clients present in home

### Cross-Environment Touchpoints
Things on WSL that connect outward:
- SSH config hosts (from WSL SSH section)
- CF Worker projects from COMPOSE_AND_WRANGLER (wrangler.toml files)
- External service env vars from BASHRC_ENV_VAR_NAMES (names only — no values)

---

## Remote VPS
**Role:** Production runtime. Services via Docker (typically Coolify-managed).

### Running Services Map
From VPS CONTAINERS and CONTAINER_STATS. Group by project (infer from container name prefixes):

| Service | Status | CPU% | Memory | Exposed |
|---------|--------|------|--------|---------|

### Traefik Routes
From VPS TRAEFIK_ROUTES:

| Domain | Upstream | TLS |
|--------|----------|-----|

### Non-Docker Services
From VPS SYSTEMD_SERVICES: tailscaled, fail2ban — status of each.

### Network Exposure
From VPS LISTEN_PORTS and FIREWALL:
- Public (0.0.0.0): list ports
- VPN-only: list ports
- Internal (127.0.0.1): list ports

---

## Cross-Environment Summary

### What's Live in Production
Every user-facing or team-facing service with its URL or access method.

### What's Local-Only
Projects in ~/dev with no corresponding running container on VPS.

### WSL → VPS Deployment Map
Which WSL projects deploy to the VPS, and how (Coolify, wrangler deploy, direct SSH, etc.).

### Flags
Anything needing attention from either environment — unhealthy containers, resource pressure, security issues, stale projects, orphaned volumes.

---

Keep it tight. Say "unknown" rather than guess.
