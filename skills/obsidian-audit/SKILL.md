---
name: obsidian-audit
description: Audit the live Obsidian vault surface, plugin set, graph config, and drift between the canonical WSL vault and the live Windows vault. Use when the graph looks wrong, plugins misbehave, or vault changes are not appearing in Obsidian.
license: MIT
compatibility: Designed for WSL with the canonical vault at ~/vault and the live Obsidian vault at /mnt/c/Users/*/Documents/vault.
allowed-tools: Bash Read
disable_model_invocation: true
---

# Obsidian Audit

Get the real Obsidian state before making changes.

## Step 1, collect

```bash
~/dev/mad-house/skills/skills/obsidian-audit/scripts/audit.sh
```

## Step 2, synthesize

Summarize only what matters:

- resolved canonical and live vault paths
- enabled core and community plugins
- graph and Extended Graph settings that affect visibility
- drift between the canonical and live vault for graph and key plugin data
- git status of both vault copies when available

Call out mismatches and risky plugin state first.

## Never

- assume the Windows vault is using the same files as `~/vault`
- claim sync is healthy without checking the live vault path
- recommend rebase-based Obsidian Git automation as a default
