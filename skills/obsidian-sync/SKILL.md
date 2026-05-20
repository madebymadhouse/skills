---
name: obsidian-sync
description: Mirror selected Obsidian surfaces between the canonical WSL vault and the live Windows vault using a safe allowlist. Use when graph settings, plugin data, or dashboards changed in one place and need to appear in the other immediately.
license: MIT
compatibility: Designed for WSL with the canonical vault at ~/vault and the live Obsidian vault at /mnt/c/Users/*/Documents/vault.
argument-hint: <graph|plugins|dashboards|all> [canonical-to-live|live-to-canonical]
allowed-tools: Bash Read
disable_model_invocation: true
---

# Obsidian Sync

Mirror only the Obsidian-facing surfaces that are safe to copy directly.

## Run

```bash
~/dev/mad-house/skills/skills/obsidian-sync/scripts/sync.sh ${ARGUMENTS:-all canonical-to-live}
```

## Safe surfaces

- `graph` - graph view state and Extended Graph config
- `plugins` - selected plugin data and plugin lists
- `dashboards` - markdown control surfaces in `dashboards/`
- `all` - the union of the above

## Never

- use this for broad wiki note syncing
- copy `.git/`, workspace state, or arbitrary plugin folders
- claim the live Windows vault changed unless the script reports copied files
