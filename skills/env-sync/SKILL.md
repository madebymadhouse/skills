---
name: env-sync
description: Check whether the skill collection scripts are still accurate and up to date with the current environment. Detects drift between hardcoded lists in scripts and what actually exists — new AI tools installed, new projects added to ~/dev, new VPS containers, broken script paths. Use when the user says "sync my skills", "are my skills up to date", "update skill scripts", "check for drift", or after installing new tools or adding new projects. Also useful periodically to keep skills accurate.
license: MIT
compatibility: Designed for Claude Code on WSL. Requires wsl-audit and vps-audit skills installed at ~/.claude/commands/. SSH access configured as "vps" alias required for VPS container drift detection.
allowed-tools: Bash Read Edit
---

# Env Sync

Checks whether skill scripts have drifted from the current environment. The drift-check script handles all detection deterministically. Your job is to interpret the gaps and propose the exact edits needed.

## Step 1 — Check for drift

```bash
~/.claude/commands/env-sync/scripts/check-drift.sh
```

## Step 2 — Interpret and fix

Work through each section:

---

### AI Client Drift (AI_CLIENT_DRIFT)

Compare "hardcoded in collect-wsl.sh" vs "actual AI-looking dirs in home".

- Any dir in the actual list that's **not** in the hardcoded list → needs to be added to the `for d in ...` loop in `collect-wsl.sh`
- Any dir in the hardcoded list that no longer exists → remove it from the script (stale entry)

For each gap, show the exact line to add or remove in `collect-wsl.sh`.

### Dev Org Drift (DEV_ORG_DRIFT)

Compare actual dirs in ~/dev vs what wsl-audit's SKILL.md synthesis instructions reference.

- New org dir in ~/dev not mentioned in SKILL.md → add it to the Dev Workspace Map section
- Org mentioned in SKILL.md that no longer exists in ~/dev → remove or mark stale

Show exact edits to `wsl-audit/SKILL.md`.

### VPS Container Drift (VPS_CONTAINER_DRIFT)

Compare current VPS containers (short names) vs the groupings defined in vps-audit SKILL.md.

- Container name doesn't fit any existing group → either it's a new project needing a new group, or it belongs in an existing group that needs its list updated
- Group in SKILL.md that has no matching containers → stale group, can be removed or noted

Show exact edits to `vps-audit/SKILL.md`.

### Broken Script Paths (SCRIPT_PATH_DRIFT)

Any `BROKEN:` line means a SKILL.md references a script path that doesn't exist.

For each broken path:
- Check if the script was moved (scan `scripts/` dirs for a file with the right name)
- If found elsewhere, update the path in the SKILL.md
- If the script is missing entirely, flag it — the skill will silently fail when invoked

This is high-priority — a broken script path causes silent failure with no error message to the user.

### Projects Without Sentinels (NEW_PROJECTS_NOT_IN_PROJECT_LANGS)

Directories in ~/dev that have no recognized sentinel file (`package.json`, `Cargo.toml`, etc.).

These won't appear in the PROJECT_LANGS output. For each:
- Is it a real code project that just uses an uncommon structure? → add a custom sentinel check to `collect-wsl.sh`
- Is it docs/assets/non-code? → acceptable, but consider adding a comment in the script to note it's intentionally excluded
- Is it a nested build artifact or temp dir? → add it to the exclusion list in the find command

---

### After Fixes

For any script edited, run a quick smoke-test to confirm no syntax errors:

```bash
bash -n ~/.claude/commands/wsl-audit/scripts/collect-wsl.sh && echo "syntax OK"
bash -n ~/.claude/commands/vps-audit/scripts/collect-vps.sh && echo "syntax OK"
bash -n ~/.claude/commands/env-sync/scripts/check-drift.sh && echo "syntax OK"
```

Report a summary of what was updated and what (if anything) still needs manual attention.
