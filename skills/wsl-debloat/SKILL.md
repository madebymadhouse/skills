---
name: wsl-debloat
description: Free disk space on WSL by clearing package manager caches (npm, pip, pnpm, playwright, node-gyp, puppeteer, prisma) and optionally pruning Docker build cache, images, and volumes on a remote VPS. Also reports lab node_modules. Triggers on "free disk space", "clean up caches", "WSL disk full", "debloat", "clear npm cache", "clean caches", "disk is getting low".
license: MIT
compatibility: Designed for Claude Code on WSL. VPS pruning requires SSH access configured as "vps" alias or VPS_SSH_HOST env var. Reads VPS_SSH_HOST from ~/.secrets/master.env if present.
allowed-tools: Bash Read
disable_model_invocation: true
---

# WSL Debloat

Clears caches and frees disk space. The script handles all cleanup - your job is to decide which flags to pass based on what the user wants.

## Flags

| Flag | What it does |
|------|-------------|
| `--scan` | Report purgeable sizes only - no changes |
| _(none)_ | WSL caches only - always safe |
| `--vps` | Also prune Docker build cache, unused images, volumes on VPS via SSH |
| `--clean-lab` | Also remove `node_modules` from mad-house projects |
| Both | Full cleanup: WSL + VPS + mad-house node_modules |

## Step 1 - Scan what's purgeable

Always run scan first so you know what's available before touching anything:

```bash
~/.claude/commands/wsl-debloat/scripts/debloat.sh --scan
```

Report the sizes to the user. If VPS shows "(ssh failed)" or is missing, note that `--vps` won't work.

## Step 2 - Run

If the user asked for everything or the scan shows meaningful sizes, proceed. If they only said "free disk space", infer from context: WSL caches are always safe, VPS pruning requires explicit intent.

```bash
~/.claude/commands/wsl-debloat/scripts/debloat.sh [--vps] [--clean-lab]
```

## Step 3 - Report

Read the BEFORE / AFTER disk usage and the per-cache summary. Report:
- Total space freed (WSL side)
- VPS space freed (if `--vps`)
- node_modules removed (if `--clean-lab`)
- Any caches that were already empty

One paragraph is enough unless the user wants details.
