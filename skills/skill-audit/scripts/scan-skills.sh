#!/usr/bin/env bash
# Scan all skills in ~/.claude/commands/ for structure, patterns, and duplication.
# Deterministic analysis — AI synthesizes the findings.
#
# Usage:
#   scan-skills.sh             — scan all skills
#   scan-skills.sh <skill>     — scan a single skill (focused mode)

set -uo pipefail

COMMANDS_DIR="$HOME/.claude/commands"

# Optional: only scan a specific skill
TARGET_SKILL="${1:-}"

echo "=== SKILL_INVENTORY ==="
if [[ -n "$TARGET_SKILL" ]]; then
  find "$COMMANDS_DIR/$TARGET_SKILL" -maxdepth 1 -name "SKILL.md" 2>/dev/null | sort
else
  find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" ! -path "*/scripts/*" 2>/dev/null | sort
fi
echo ""

echo "=== SKILL_STRUCTURES ==="
scan_skill_structure() {
  local skill_dir="$1"
  local name; name=$(basename "$skill_dir")
  local has_skill_md="no"; [ -f "$skill_dir/SKILL.md" ]   && has_skill_md="yes"
  local has_scripts="no";  [ -d "$skill_dir/scripts" ]    && has_scripts="yes"
  local has_refs="no";     [ -d "$skill_dir/references" ] && has_refs="yes"
  local has_assets="no";   [ -d "$skill_dir/assets" ]     && has_assets="yes"
  echo "$name | SKILL.md:$has_skill_md | scripts:$has_scripts | references:$has_refs | assets:$has_assets"
}
if [[ -n "$TARGET_SKILL" ]]; then
  [[ -d "$COMMANDS_DIR/$TARGET_SKILL" ]] && scan_skill_structure "$COMMANDS_DIR/$TARGET_SKILL"
else
  find "$COMMANDS_DIR" -maxdepth 1 -mindepth 1 -type d | sort | while read -r d; do
    scan_skill_structure "$d"
  done
  find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | sort | while read -r f; do
    echo "FLAT: $(basename "$f")"
  done
fi
echo ""

echo "=== BASH_BLOCKS_PER_SKILL ==="
scan_bash_blocks() {
  local skill_md="$1"
  local skill; skill=$(basename "$(dirname "$skill_md")")
  local block_count; block_count=$(grep -c '```bash' "$skill_md" 2>/dev/null || echo 0)
  echo "$skill: $block_count bash block(s)"
}
if [[ -n "$TARGET_SKILL" ]]; then
  [[ -f "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md" ]] && scan_bash_blocks "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md"
else
  find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r f; do
    scan_bash_blocks "$f"
  done
fi
echo ""

echo "=== INLINE_BASH_COMMANDS ==="
# Show all bash blocks — AI classifies: pure data collection vs judgment/conditionals
scan_inline_bash() {
  local skill_md="$1"
  local skill; skill=$(basename "$(dirname "$skill_md")")
  echo "--- $skill ---"
  awk '/^```bash$/,/^```$/' "$skill_md" 2>/dev/null
  echo ""
}
if [[ -n "$TARGET_SKILL" ]]; then
  [[ -f "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md" ]] && scan_inline_bash "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md"
else
  find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r f; do
    scan_inline_bash "$f"
  done
fi
echo ""

echo "=== SCRIPT_FILES ==="
if [[ -n "$TARGET_SKILL" ]]; then
  find "$COMMANDS_DIR/$TARGET_SKILL/scripts" -type f 2>/dev/null | sort | while read -r f; do
    echo "$TARGET_SKILL/scripts/$(basename "$f") ($(wc -l < "$f") lines)"
  done
else
  find "$COMMANDS_DIR" -path "*/scripts/*" -type f | sort | while read -r f; do
    echo "$(basename "$(dirname "$(dirname "$f")")")/scripts/$(basename "$f") ($(wc -l < "$f") lines)"
  done
fi
echo ""

echo "=== DUPLICATE_COMMANDS ==="
# Find commands appearing verbatim in 2+ SKILL.md files — duplication candidates
if [[ -z "$TARGET_SKILL" ]]; then
  all_cmds=$(find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null \
    | xargs grep -h '^\(ssh\|docker\|find\|cat\|ls\|grep\|ollama\|df\|free\|uname\|git\|curl\)' 2>/dev/null \
    | sed 's/^[[:space:]]*//' | sort)
  dupes=$(echo "$all_cmds" | sort | uniq -d)
  if [[ -n "$dupes" ]]; then
    echo "$dupes" | head -20
  else
    echo "(none found)"
  fi
else
  echo "(single-skill mode: full duplication check skipped)"
fi
echo ""

echo "=== SHARED_SCRIPT_OPPORTUNITIES ==="
# Detect: inline bash in this skill uses commands that are already scripted in another skill.
# These are reuse opportunities — call the other script instead of duplicating the logic.
check_shared_for_skill() {
  local skill_md="$1"
  local skill; skill=$(basename "$(dirname "$skill_md")")
  local cmds
  cmds=$(awk '/^```bash$/,/^```$/' "$skill_md" 2>/dev/null \
    | grep -v '^```' | awk '{print $1}' | grep -E '^[a-z~$]' | sort -u)
  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    # Strip leading ~/ or $HOME/ prefixes for matching
    local bare_cmd="${cmd##*/}"
    bare_cmd="${bare_cmd#\~/.claude/commands/*/scripts/}"
    matches=$(grep -rl "$bare_cmd" "$COMMANDS_DIR"/*/scripts/ 2>/dev/null \
      | grep -v "/$skill/scripts/" | head -3 || true)
    if [[ -n "$matches" ]]; then
      for m in $matches; do
        relative="${m#$COMMANDS_DIR/}"
        echo "SKILL:$skill | CMD:$cmd | ALREADY_SCRIPTED_IN:$relative"
      done
    fi
  done <<< "$cmds"
}
if [[ -n "$TARGET_SKILL" ]]; then
  [[ -f "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md" ]] && check_shared_for_skill "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md"
else
  find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r f; do
    check_shared_for_skill "$f"
  done
fi
echo ""

echo "=== DESCRIPTION_LENGTHS ==="
scan_desc() {
  local skill_md="$1"
  local skill; skill=$(basename "$(dirname "$skill_md")")
  local desc
  desc=$(awk '/^description:/{found=1; sub(/^description: /,""); print; next} found && /^[^ ]/{exit} found{print}' "$skill_md" | tr -d '\n')
  local len=${#desc}
  echo "$skill: ${len} chars"
}
if [[ -n "$TARGET_SKILL" ]]; then
  [[ -f "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md" ]] && scan_desc "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md"
else
  find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r f; do
    scan_desc "$f"
  done
fi
echo ""

echo "=== MISSING_ARGUMENT_HINTS ==="
scan_arg_hints() {
  local skill_md="$1"
  local skill; skill=$(basename "$(dirname "$skill_md")")
  local has_args has_hint
  has_args=$(grep -c '\$ARGUMENTS' "$skill_md" 2>/dev/null || echo 0)
  has_hint=$(grep -c 'argument-hint' "$skill_md" 2>/dev/null || echo 0)
  [ "$has_args" -gt 0 ] && [ "$has_hint" -eq 0 ] && echo "$skill: uses \$ARGUMENTS but no argument-hint"
  return 0
}
if [[ -n "$TARGET_SKILL" ]]; then
  [[ -f "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md" ]] && scan_arg_hints "$COMMANDS_DIR/$TARGET_SKILL/SKILL.md"
else
  find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r f; do
    scan_arg_hints "$f"
  done
fi
echo "(end)"

echo ""
echo "=== CONTEXT ==="
echo "scanned_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "target: ${TARGET_SKILL:-all}"
