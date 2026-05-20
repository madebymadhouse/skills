---
name: skill-audit
description: Audit skills for quality, structure, and efficiency. Finds deterministic steps that should be scripts, duplicated logic across skills, composability gaps, and weak descriptions. Run after creating or updating any skill, or when the user says "audit my skills", "review my skills", "check skill quality", "is this skill good", or "improve my skills".
---

# Skill Audit

Scan skills, then apply judgment to identify what should change and why. The script does detection - you do the decisions.

## Input

- `$ARGUMENTS` (optional) - a specific skill name to audit in focused mode. Omit to audit all skills.

## Step 1 - Scan

```bash
~/.claude/commands/skill-audit/scripts/scan-skills.sh $ARGUMENTS
```

If `$ARGUMENTS` is empty, scans all skills. If a skill name is provided, scans only that skill (faster, used automatically after creation).

## Step 2 - Analyze

Work through each section of the scan output:

---

### Deterministic Step Audit
From `INLINE_BASH_COMMANDS` and `BASH_BLOCKS_PER_SKILL`:

For each bash block, classify the operation:

| Classification | What it looks like | Verdict |
|---|---|---|
| Calls an existing script | `~/.claude/commands/*/scripts/*.sh` | Correct - no change |
| Pure data collection | `cat`, `ls`, `find`, `grep`, `uname`, `df`, `free`, `ssh` + read-only | Extract to script |
| Text transformation | `sed`, `awk`, `cut`, `tr` with no conditionals | Extract to script |
| Conditional / judgment | `if`/`then`, `case`, comparisons, decisions | Keep in SKILL.md |
| Complex pipeline | >5 piped commands doing what a script would do | Extract to script |

For every deterministic block: show BEFORE (the inline block) and AFTER (what the extracted script would look like). Label clearly.

### Shared Script Opportunities
From `SHARED_SCRIPT_OPPORTUNITIES`:

For each match: the skill has inline bash that already exists as a script in another skill. Suggest calling that script directly instead. Name which skill owns it and what the call would look like.

### Composability Audit
From `DUPLICATE_COMMANDS` and the full skill set:

- Does any skill re-implement data collection that another skill's script already provides?
- Could any skill call another skill's script instead of duplicating the logic?
- Are there skills that should chain (one's output is another's input)?

For each duplication: name both skills, show the duplicated lines, suggest which one should own a shared script.

### Structure Audit
From `SKILL_STRUCTURES`:

Flag any skill that:
- Has inline bash blocks but no `scripts/` folder - extraction candidate
- Has a `scripts/` folder but SKILL.md still has inline data collection - incomplete extraction
- Is a flat `.md` file (not a folder) - needs migration to folder format

### Description Quality
From `DESCRIPTION_LENGTHS`:

- Under 80 chars: likely too short to trigger reliably
- Missing trigger phrases ("use when the user says...")
- Missing both what-it-does AND when-to-use - both are required for reliable triggering

### Missing Metadata
From `MISSING_ARGUMENT_HINTS`:

Flag any skill using `$ARGUMENTS` without `argument-hint` in frontmatter.

---

## Step 3 - Output

For each issue found:

```
SKILL: <name>
ISSUE: <what's wrong, one sentence>
SEVERITY: high | medium | low
BEFORE:
  <the current inline bash block or current description>
AFTER:
  <the extracted script content or improved description>
WHY: <the reason - reuse, token savings, trigger reliability, etc.>
```

Group by severity. High = duplicated logic, broken triggering, or token waste. Medium = extraction opportunity. Low = description polish.

**Summary Table** after all issues:

| Skill | Extract to Script | Shared Script | Description | Total |
|-------|-------------------|---------------|-------------|-------|

**Action List** at the end - the 3 highest-value changes to make now, in order.
