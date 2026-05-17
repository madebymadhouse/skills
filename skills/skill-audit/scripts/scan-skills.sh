#!/usr/bin/env bash
# Scan all skills in ~/.claude/commands/ for structure, patterns, and duplication.
# Deterministic analysis — AI synthesizes the findings.

set -uo pipefail

COMMANDS_DIR="$HOME/.claude/commands"

echo "=== SKILL_INVENTORY ==="
# List all skills: flat .md files and folder-based SKILL.md
find "$COMMANDS_DIR" -maxdepth 2 \( -name "SKILL.md" -o \( -maxdepth 1 -name "*.md" \) \) \
  ! -path "*/scripts/*" \
  2>/dev/null | sort
echo ""

echo "=== SKILL_STRUCTURES ==="
# For each skill, report: type (flat vs folder), has scripts/, has references/, has assets/
find "$COMMANDS_DIR" -maxdepth 1 -mindepth 1 -type d | sort | while read -r skill_dir; do
  name=$(basename "$skill_dir")
  has_skill_md="no"; [ -f "$skill_dir/SKILL.md" ]     && has_skill_md="yes"
  has_scripts="no";  [ -d "$skill_dir/scripts" ]       && has_scripts="yes"
  has_refs="no";     [ -d "$skill_dir/references" ]    && has_refs="yes"
  has_assets="no";   [ -d "$skill_dir/assets" ]        && has_assets="yes"
  echo "$name | SKILL.md:$has_skill_md | scripts:$has_scripts | references:$has_refs | assets:$has_assets"
done
# Also list any flat .md files still present
find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | sort | while read -r f; do
  echo "FLAT: $(basename "$f")"
done
echo ""

echo "=== BASH_BLOCKS_PER_SKILL ==="
# Extract and count bash blocks in each skill's SKILL.md
find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r skill_md; do
  skill=$(basename "$(dirname "$skill_md")")
  block_count=$(grep -c '```bash' "$skill_md" 2>/dev/null || echo 0)
  echo "$skill: $block_count bash block(s)"
done
echo ""

echo "=== INLINE_BASH_COMMANDS ==="
# Show all bash blocks from all SKILL.md files — AI identifies which are deterministic vs need judgment
find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r skill_md; do
  skill=$(basename "$(dirname "$skill_md")")
  echo "--- $skill ---"
  awk '/^```bash$/,/^```$/' "$skill_md" 2>/dev/null
  echo ""
done
echo ""

echo "=== SCRIPT_FILES ==="
# Show all scripts bundled in skill folders
find "$COMMANDS_DIR" -path "*/scripts/*" -type f | sort | while read -r f; do
  echo "$(basename "$(dirname "$(dirname "$f")")")/scripts/$(basename "$f") ($(wc -l < "$f") lines)"
done
echo ""

echo "=== DUPLICATE_COMMANDS ==="
# Find the same shell command pattern appearing in 2+ different skill SKILL.md files
# Extract all bash command lines, sort and count duplicates
all_cmds=$(find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | xargs grep -h '^\(ssh\|docker\|find\|cat\|ls\|grep\|ollama\|df\|free\|uname\)' 2>/dev/null | sed 's/^[[:space:]]*//' | sort)
echo "$all_cmds" | sort | uniq -d | head -20
echo ""

echo "=== DESCRIPTION_LENGTHS ==="
# Description field length per skill — short descriptions trigger less reliably
find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r skill_md; do
  skill=$(basename "$(dirname "$skill_md")")
  desc=$(awk '/^description:/{found=1; sub(/^description: /,""); print; next} found && /^[^ ]/{exit} found{print}' "$skill_md" | tr -d '\n')
  len=${#desc}
  echo "$skill: ${len} chars"
done
echo ""

echo "=== MISSING_ARGUMENT_HINTS ==="
# Skills that take arguments but may not declare argument-hint
find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r skill_md; do
  skill=$(basename "$(dirname "$skill_md")")
  has_args=$(grep -c '\$ARGUMENTS' "$skill_md" 2>/dev/null || echo 0)
  has_hint=$(grep -c 'argument-hint' "$skill_md" 2>/dev/null || echo 0)
  [ "$has_args" -gt 0 ] && [ "$has_hint" -eq 0 ] && echo "$skill: uses \$ARGUMENTS but no argument-hint"
done
echo "(end)"
