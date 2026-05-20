---
name: obsidian-ops
description: Improve Obsidian itself, including graph states, dashboards, plugin configuration, explorer order, file colors, Kanban, and other live vault UX surfaces. Use when the user wants Obsidian to feel better, not just the note content.
license: MIT
compatibility: Designed for WSL with a canonical vault at ~/vault and a live Windows vault under /mnt/c/Users/*/Documents/vault.
allowed-tools: Bash Read Edit
---

# Obsidian Ops

This skill owns the Obsidian UI and plugin surface.

## Start here

1. Run `~/dev/mad-house/skills/skills/obsidian-audit/scripts/audit.sh`
2. Read the live Windows vault surfaces that matter:
   - `/mnt/c/Users/*/Documents/vault/.obsidian/`
   - `/mnt/c/Users/*/Documents/vault/dashboards/`
3. Change only the targeted Obsidian-facing files
4. Mirror the changed surfaces with `~/dev/mad-house/skills/skills/obsidian-sync/scripts/sync.sh`

## This skill owns

- graph state and Extended Graph tuning
- explorer order, colors, icons, and dashboard surfaces
- plugin settings and safe plugin-level operational changes
- Kanban boards and visual control surfaces

## This skill does not own

- long-term note topology or MOC growth, use `vault-growth`
- broad wiki note authoring outside Obsidian-facing surfaces
- git repair of the whole Windows vault repo
