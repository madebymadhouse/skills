---
name: nb-new
description: Create a new Jupyter notebook (.ipynb) in the how-to repo. Use when the
  user wants to add a new guide, tutorial, or how-to. Triggers on "new notebook", "add
  a notebook", "create a how-to for", "add to how-to".
allowed-tools: Bash, Read
---

# nb-new

Creates a correctly formatted `.ipynb` file in the right location inside `~/dev/mad-house/how-to/`.

## Tools

### scripts/create.sh
Creates a new notebook with a title cell and a placeholder body cell.
- Input: `NB_PATH=<relative path inside how-to>` (e.g. `vibe-coding/skills/advanced-patterns`)
- Input: `NB_TITLE=<human title>` (e.g. "Advanced Skill Patterns")
- Output: `{created: bool, path: string, abs_path: string}`

## Workflow

1. Determine the path: ask the user if not given, or infer from context (e.g. "add a git guide" → `vibe-coding/git/how-to-git`)
2. Run `NB_PATH="..." NB_TITLE="..." bash scripts/create.sh`
3. Report the created path and tell the user to open it
4. Do NOT add content — the notebook starts with a title and one placeholder cell. The user or a follow-up prompt fills it in.

## Naming convention

- Path uses kebab-case: `vibe-coding/skills/advanced-patterns`
- Title uses title case: "Advanced Skill Patterns"
- File is saved as `<last-path-segment>.ipynb`
