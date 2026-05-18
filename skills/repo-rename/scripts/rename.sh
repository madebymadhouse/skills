#!/usr/bin/env bash
# rename.sh — rename a local repo folder and update all AGENTS.md + memory refs
#
# Usage: rename.sh <old-name> <new-name>
#
# Outputs JSON summary to stdout.

set -euo pipefail

OLD_NAME="${1:-}"
NEW_NAME="${2:-}"

if [[ -z "$OLD_NAME" || -z "$NEW_NAME" ]]; then
  echo '{"error":"Usage: rename.sh <old-name> <new-name>"}' >&2
  exit 1
fi

if [[ "$OLD_NAME" == "$NEW_NAME" ]]; then
  echo '{"error":"old and new names are the same"}' >&2
  exit 1
fi

DEV_ROOT="${HOME}/dev"

# Find the repo path (maxdepth 3 under ~/dev)
REPO_PATH=""
while IFS= read -r candidate; do
  if [[ "$(basename "$candidate")" == "$OLD_NAME" ]]; then
    REPO_PATH="$candidate"
    break
  fi
done < <(find "$DEV_ROOT" -maxdepth 3 -mindepth 1 -type d -name "$OLD_NAME" 2>/dev/null)

if [[ -z "$REPO_PATH" ]]; then
  echo "{\"error\":\"repo '${OLD_NAME}' not found under ${DEV_ROOT}\"}" >&2
  exit 1
fi

if [[ ! -d "${REPO_PATH}/.git" ]]; then
  echo "{\"error\":\"${REPO_PATH} is not a git repo\"}" >&2
  exit 1
fi

NEW_PATH="$(dirname "$REPO_PATH")/${NEW_NAME}"

if [[ -e "$NEW_PATH" ]]; then
  echo "{\"error\":\"target path already exists: ${NEW_PATH}\"}" >&2
  exit 1
fi

# Rename folder
mv "$REPO_PATH" "$NEW_PATH"

# Update remote URL if it contains the old name
REMOTE_CHANGE="null"
if git -C "$NEW_PATH" remote get-url origin &>/dev/null; then
  OLD_REMOTE="$(git -C "$NEW_PATH" remote get-url origin)"
  if [[ "$OLD_REMOTE" == *"${OLD_NAME}"* ]]; then
    NEW_REMOTE="${OLD_REMOTE//${OLD_NAME}/${NEW_NAME}}"
    git -C "$NEW_PATH" remote set-url origin "$NEW_REMOTE"
    REMOTE_CHANGE="{\"old\":\"${OLD_REMOTE}\",\"new\":\"${NEW_REMOTE}\"}"
  fi
fi

# Files to scan and update
SCAN_FILES=()
[[ -f "${HOME}/AGENTS.md" ]] && SCAN_FILES+=("${HOME}/AGENTS.md")
while IFS= read -r f; do
  SCAN_FILES+=("$f")
done < <(find "${DEV_ROOT}" -maxdepth 2 -name "AGENTS.md" 2>/dev/null)
while IFS= read -r f; do
  SCAN_FILES+=("$f")
done < <(find "${HOME}/.claude/projects" -maxdepth 3 -name "*.md" -path "*/memory/*" 2>/dev/null)

# Deduplicate
declare -A seen
UNIQUE_FILES=()
for f in "${SCAN_FILES[@]}"; do
  if [[ -z "${seen[$f]+_}" ]]; then
    seen[$f]=1
    UNIQUE_FILES+=("$f")
  fi
done

# Replace in each file, collect results
CHANGES="[]"
for f in "${UNIQUE_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    continue
  fi
  count=$(grep -c "$OLD_NAME" "$f" 2>/dev/null || true)
  if [[ "$count" -gt 0 ]]; then
    sed -i "s|${OLD_NAME}|${NEW_NAME}|g" "$f"
    entry="{\"file\":\"${f}\",\"replacements\":${count}}"
    if [[ "$CHANGES" == "[]" ]]; then
      CHANGES="[${entry}]"
    else
      CHANGES="${CHANGES%]},${entry}]"
    fi
  fi
done

cat <<EOF
{
  "old_path": "${REPO_PATH}",
  "new_path": "${NEW_PATH}",
  "remote_change": ${REMOTE_CHANGE},
  "files_updated": ${CHANGES}
}
EOF
