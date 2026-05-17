---
name: skill-audit
description: Audit all skills in ~/.claude/commands/ for quality, structure, and efficiency. Finds deterministic steps that should be extracted into scripts, AI interpretation of things that are actually fixed operations, duplicated logic across skills, missing folder structure, weak descriptions, and composability opportunities. Use when the user says "audit my skills", "review my skills", "improve my skills", "check skill quality", or wants to make skills more efficient or composable.
license: MIT
compatibility: Designed for Claude Code. Skills must be installed at ~/.claude/commands/ using the folder-based structure with SKILL.md files.
allowed-tools: Bash Read Edit
---

# Skill Audit

Scan all skills, then apply judgment to identify what should change and why. The script handles detection — you handle the decisions.

## Step 1 — Scan

```bash
~/.claude/commands/skill-audit/scripts/scan-skills.sh
```

## Step 2 — Analyze and Report

Work through each finding category:

---

### Structure Audit
From SKILL_STRUCTURES and SKILL_INVENTORY:

Flag any skill that is:
- Still a flat `.md` file instead of a folder with `SKILL.md` → needs migration
- A folder but missing `scripts/` despite having inline bash blocks → candidate for extraction
- A folder with scripts but the SKILL.md still has inline bash doing what the script should do

### Deterministic Step Audit
From INLINE_BASH_COMMANDS and BASH_BLOCKS_PER_SKILL:

For each bash block in each skill, classify:
- **Script already exists, block just calls it** → correct ✓
- **Pure data collection** (cat, ls, find, grep, uname, df, free, ssh + read-only commands) → should be in a script, not inline
- **Text transformation** (sed, awk, cut, tr — without conditional logic) → deterministic, should be in a script
- **Conditional logic / judgment** (if/then, case, comparing outputs, decisions) → belongs in SKILL.md, AI handles it
- **Complex pipeline doing what a 10-line script would do** → extract to script

For every deterministic block found inline: show the exact block, then show what the script extraction would look like. Label it clearly as a suggestion.

### Duplication Audit
From DUPLICATE_COMMANDS:

For each command pattern that appears in 2+ skills:
- Which skills contain it
- Is it already extracted to a shared script, or is it duplicated inline?
- If duplicated: suggest which skill should own the script and how others should reference it

### Composability Audit
Look at the skill set as a whole:
- Does any skill re-implement data collection that another skill's script already provides?
- Could any skill call another skill's collection script instead of duplicating it?
- Are there skills that should chain (one's output is another's input)?

### Description Quality Audit
From DESCRIPTION_LENGTHS:
- Descriptions under 80 chars are likely too short to trigger reliably — flag them
- Check if descriptions include specific trigger phrases ("use when the user says...")
- Check if descriptions say what the skill does AND when to use it (both are required for good triggering)

### Missing Metadata
From MISSING_ARGUMENT_HINTS:
- Flag any skill that uses `$ARGUMENTS` without declaring `argument-hint` in frontmatter

---

### Output Format

For each issue found, report:

```
SKILL: <name>
ISSUE: <what's wrong>
SEVERITY: high | medium | low
FIX: <exactly what to change — code diff if applicable>
WHY: <the reason this matters>
```

Group by severity. High = token waste, duplication, or broken behavior. Medium = structure/quality. Low = polish.

After the issue list, provide a **Summary Table**:

| Skill | Flat→Folder | Extract to Script | Duplication | Description | Total Issues |
|-------|-------------|-------------------|-------------|-------------|--------------|

End with a prioritized **Action List** — the 3-5 highest-value changes to make next.
