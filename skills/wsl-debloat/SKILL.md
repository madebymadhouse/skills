---
name: wsl-debloat
description: Free disk space on WSL by clearing package manager caches (npm, pip, pnpm, playwright, node-gyp, puppeteer, prisma, cargo, go-mod) and optionally pruning Docker on a remote VPS. Surveys first so you see exactly what's taking space before anything is deleted. Triggers on "free disk space", "clean up caches", "WSL disk full", "debloat", "clear npm cache", "clean caches", "disk is getting low", "how much space can I free".
compatibility: Designed for Claude Code on WSL. VPS pruning requires VPS_SSH_HOST in ~/.secrets/master.env.
allowed-tools: Bash Read
---

# WSL Debloat

Two-phase: survey first, clean second. Never ask the user what to include — figure it out from the scan.

## Tools

### `scripts/scan.sh`

Survey disk state without cleaning anything.

```
Input:  (none)
Output: {
  wsl:  { disk: {used, total, percent}, caches: [{name, size, available}] },
  vps:  { available: bool, disk: {...}, docker_df: string } | { available: false, reason },
  lab:  { node_modules: [{path, size}] }
}
```

### `scripts/clean_wsl.sh`

Clear all WSL package manager caches (npm, pip, pnpm, playwright, node-gyp, puppeteer, prisma, cargo, go-mod).

```
Input:  (none)
Output: { disk_before, disk_after, cleaned: [{name, freed}], skipped: [name] }
```

### `scripts/clean_vps.sh`

Prune Docker build cache, unused images, and volumes on the VPS via SSH.

```
Input:  (none)
Output: { available: bool, disk_before, disk_after, pruned: {build_cache, images, volumes} }
```

### `scripts/clean_lab.sh`

Remove `node_modules` directories from all projects under `~/dev`.

```
Input:  (none)
Output: { removed: [{path, freed}], count } | { removed: [], note }
```

## Step 1 — Scan

Always run this first:

```bash
~/.claude/commands/wsl-debloat/scripts/scan.sh
```

## Step 2 — Synthesize findings

Present what was found before cleaning:

**WSL caches** — list each cache with its size. Separate populated from empty.

**VPS** — if `available: true`, show disk usage and the `docker_df` table. If `available: false`, note why (not configured vs unreachable).

**Lab node_modules** — list each project and size. If none, say so.

One sentence summary: "Found X MB across N caches on WSL, VPS Docker is clean, no lab node_modules."

## Step 3 — Clean

Run all applicable tools based on what the scan found. Do not ask for confirmation — just run them.

- Always run `clean_wsl.sh` (safe, all caches are regenerated on demand)
- Run `clean_vps.sh` only if `vps.available: true`
- Run `clean_lab.sh` only if `lab.node_modules` is non-empty

Run WSL and VPS in parallel if both apply:

```bash
~/.claude/commands/wsl-debloat/scripts/clean_wsl.sh
~/.claude/commands/wsl-debloat/scripts/clean_vps.sh   # if VPS available
~/.claude/commands/wsl-debloat/scripts/clean_lab.sh   # if node_modules found
```

## Step 4 — Report

Show a tight summary:

**WSL** — list each cache freed with its size. Show disk before → after (e.g. "35G → 34G"). If a cache was already empty, list it under "already clean" in one line.

**VPS** — show what Docker pruned per category. Show disk before → after.

**Lab** — list each project removed and size freed.

**Total** — one sentence: what was freed overall, where.

If everything was already clean, say so in one sentence. Don't pad.
