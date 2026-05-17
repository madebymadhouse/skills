---
name: uninstall
description: Cleanly uninstall a CLI tool or package from WSL — finds every trace across npm, pip, cargo, config dirs, caches, VS Code extensions, and home files, then removes what the user confirms. Use when the user wants to fully remove a tool, package, or CLI from the WSL environment. Triggers on "uninstall", "remove", "get rid of", "clean up" followed by a tool name.
argument-hint: <tool-name>
license: MIT
compatibility: Designed for Claude Code on WSL (Windows Subsystem for Linux). Requires bash, find, and whichever package managers are relevant (npm, pip, pipx, cargo).
allowed-tools: Bash Read
---

# Uninstall

Completely remove all traces of a CLI tool or package from WSL.

## Arguments

The user wants to uninstall: $ARGUMENTS

## Step 1 — Find all traces

The collection script searches every likely install location deterministically.

```bash
~/.claude/commands/uninstall/scripts/collect-install-traces.sh "$ARGUMENTS"
```

## Step 2 — Categorize

Read the script output and group findings. This is where judgment is needed — the script finds everything, you decide what matters.

- **Package manager installs** (npm global, pip, pipx, cargo) — safe to remove via the package manager; this also cleans the binary symlink
- **Standalone binaries** — if not from a package manager, note the path; user decides
- **Config / auth data** (`~/.<tool>`, `~/.config/<tool>`, etc.) — ask if they want to preserve settings before removing (e.g. if reinstalling)
- **Caches** (npx cache, npm cache, zed cache) — safe to remove
- **VS Code extensions** — ask explicitly; user may want to keep them
- **User project files** (anything inside `~/dev/`) — never remove; flag as FYI only
- **Systemd units** — flag for manual review; do not auto-remove

Present the categorized list clearly. Flag anything ambiguous.

## Step 3 — Ask about VS Code extensions (if found)

If VS Code extensions appeared in VSCODE_EXTENSIONS, ask the user before removing.

## Step 4 — Remove

Remove everything the user confirmed, in this order:
1. Package manager uninstall first (cleans binary automatically):
   - `npm uninstall -g <pkg>`
   - `pipx uninstall <pkg>`
   - `pip uninstall -y <pkg>`
   - `cargo uninstall <pkg>`
2. Config/data dirs: `rm -rf`
3. Cache dirs: `rm -rf`
4. VS Code extensions: only if user confirmed

Never remove anything in `~/dev/` or systemd units without explicit user confirmation.

## Step 5 — Verify

```bash
which "$ARGUMENTS" 2>/dev/null && echo "binary still present" || echo "binary gone"
ls ~/."$ARGUMENTS" 2>/dev/null && echo "config still present" || echo "config gone"
```

Report what was removed. Explain anything left behind.
