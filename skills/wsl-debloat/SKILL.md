---
name: wsl-debloat
description: Free disk space on WSL by clearing package manager caches (npm, pip, pnpm, playwright, node-gyp, puppeteer, prisma) and optionally pruning Docker build cache, images, and volumes on a remote VPS. Also reports lab node_modules. Triggers on "free disk space", "clean up caches", "WSL disk full", "debloat", "clear npm cache", "clean caches", "disk is getting low".
license: MIT
compatibility: Designed for Claude Code on WSL. VPS pruning requires SSH access configured as "vps" alias or VPS_SSH_HOST env var. Reads VPS_SSH_HOST from ~/.secrets/master.env if present.
allowed-tools: Bash Read
---

# WSL Debloat

Clears caches and frees disk space. The script handles all cleanup — your job is to decide which flags to pass based on what the user wants.

## Flags

| Flag | What it does |
|------|-------------|
| _(none)_ | WSL caches only — always safe |
| `--vps` | Also prune Docker build cache, unused images, volumes on VPS via SSH |
| `--clean-lab` | Also remove `node_modules` from lab projects |
| Both | Full cleanup: WSL + VPS + lab |

## Step 1 — Ask if needed

If the user didn't specify whether to include VPS or lab node_modules, ask. Otherwise infer from context ("just WSL" → no flags, "everything" → both flags).

## Step 2 — Run

```bash
~/.claude/commands/wsl-debloat/scripts/debloat.sh [--vps] [--clean-lab]
```

Pass the appropriate flags based on the user's intent.

## Step 3 — Report

Read the BEFORE / AFTER disk usage and the per-cache summary. Report:
- Total space freed (WSL side)
- VPS space freed (if `--vps`)
- Lab node_modules removed (if `--clean-lab`)
- Any caches that were already empty

One paragraph is enough unless the user wants details.
