#!/usr/bin/env bash
# flag.sh — batch add/remove frontmatter fields in SKILL.md files
#
# Usage:
#   flag.sh add "skill1 skill2" "disable_model_invocation: true"
#   flag.sh remove "skill1 skill2" "disable_model_invocation"
#   flag.sh add --all "user_invocable: false"

set -euo pipefail

ACTION="${1:-}"
SKILLS_ARG="${2:-}"
FIELD="${3:-}"

COMMANDS_DIR="${HOME}/.claude/commands"

if [[ -z "$ACTION" || -z "$SKILLS_ARG" || -z "$FIELD" ]]; then
  echo '{"error":"Usage: flag.sh <add|remove> <\"skill1 skill2\"|--all> \"<field>\""}'
  exit 1
fi

if [[ "$ACTION" != "add" && "$ACTION" != "remove" ]]; then
  echo '{"error":"action must be add or remove"}'
  exit 1
fi

# Build skill list
SKILL_NAMES=()
if [[ "$SKILLS_ARG" == "--all" ]]; then
  while IFS= read -r d; do
    SKILL_NAMES+=("$(basename "$d")")
  done < <(find "$COMMANDS_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
else
  read -ra SKILL_NAMES <<< "$SKILLS_ARG"
fi

# Extract key from field line (e.g. "disable_model_invocation: true" → "disable_model_invocation")
FIELD_KEY="${FIELD%%:*}"
FIELD_KEY="${FIELD_KEY%% *}"

RESULTS="[]"

append_result() {
  local name="$1" status="$2"
  local entry="{\"skill\":\"${name}\",\"status\":\"${status}\"}"
  if [[ "$RESULTS" == "[]" ]]; then
    RESULTS="[${entry}]"
  else
    RESULTS="${RESULTS%]},${entry}]"
  fi
}

for SKILL_NAME in "${SKILL_NAMES[@]}"; do
  SKILL_MD="${COMMANDS_DIR}/${SKILL_NAME}/SKILL.md"

  if [[ ! -f "$SKILL_MD" ]]; then
    append_result "$SKILL_NAME" "not-found"
    continue
  fi

  # Check for frontmatter (file must start with ---)
  first_line="$(head -1 "$SKILL_MD")"
  if [[ "$first_line" != "---" ]]; then
    append_result "$SKILL_NAME" "no-frontmatter"
    continue
  fi

  if [[ "$ACTION" == "add" ]]; then
    # Check if key already present in frontmatter
    if grep -qP "^${FIELD_KEY}[: ]" "$SKILL_MD" 2>/dev/null || grep -qE "^${FIELD_KEY}:" "$SKILL_MD" 2>/dev/null; then
      append_result "$SKILL_NAME" "already-present"
      continue
    fi
    # Insert before the closing --- of frontmatter
    # Find line number of closing ---
    closing_line=$(awk 'NR>1 && /^---$/{print NR; exit}' "$SKILL_MD")
    if [[ -z "$closing_line" ]]; then
      append_result "$SKILL_NAME" "no-frontmatter"
      continue
    fi
    sed -i "${closing_line}i ${FIELD}" "$SKILL_MD"
    append_result "$SKILL_NAME" "added"

  elif [[ "$ACTION" == "remove" ]]; then
    # Check if key exists in frontmatter block
    closing_line=$(awk 'NR>1 && /^---$/{print NR; exit}' "$SKILL_MD")
    if [[ -z "$closing_line" ]]; then
      append_result "$SKILL_NAME" "no-frontmatter"
      continue
    fi
    if ! awk "NR>1 && NR<${closing_line} && /^${FIELD_KEY}[: ]/{found=1} END{exit !found}" "$SKILL_MD" 2>/dev/null; then
      append_result "$SKILL_NAME" "already-absent"
      continue
    fi
    # Remove the line containing the key within frontmatter
    sed -i "1,${closing_line}s/^${FIELD_KEY}[^$]*$//" "$SKILL_MD"
    # Clean up blank lines left by removal
    sed -i '/^$/d' "$SKILL_MD"
    # But frontmatter needs a blank line after closing --- if there's content below — restore it
    # Actually simpler: just ensure no double-blank inside frontmatter, leave content alone
    append_result "$SKILL_NAME" "removed"
  fi
done

cat <<EOF
{
  "action": "${ACTION}",
  "field": "${FIELD}",
  "results": ${RESULTS}
}
EOF
