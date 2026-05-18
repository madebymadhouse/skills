#!/usr/bin/env bash
# stage.sh — copy one or more skills from ~/.claude/commands/ into the public skills repo
#
# Usage:
#   stage.sh <skill-name>                    — stage one skill
#   stage.sh <skill1> <skill2> ...           — stage multiple skills
#   stage.sh "skill1 skill2 skill3"          — stage multiple (space-separated string)
#   stage.sh --all                           — stage every installed skill

set -euo pipefail

COMMANDS_DIR="${HOME}/.claude/commands"
REPO_DIR="${HOME}/dev/mad-house/skills"
SKILLS_DIR="${REPO_DIR}/skills"

if [[ $# -eq 0 ]]; then
  echo "Usage: stage.sh <skill-name> [skill2 ...]" >&2
  echo "       stage.sh --all" >&2
  exit 1
fi

if [[ ! -d "${REPO_DIR}" ]]; then
  echo "ERROR: skills repo not found at ${REPO_DIR}" >&2
  exit 1
fi

# Build list of skills to stage
SKILL_NAMES=()
if [[ "$1" == "--all" ]]; then
  while IFS= read -r d; do
    SKILL_NAMES+=("$(basename "$d")")
  done < <(find "${COMMANDS_DIR}" -maxdepth 1 -mindepth 1 -type d | sort)
else
  for arg in "$@"; do
    # Support both "skill1 skill2" as one arg or multiple args
    read -ra parts <<< "$arg"
    SKILL_NAMES+=("${parts[@]}")
  done
fi

STAGED=0
FAILED=0

for SKILL_NAME in "${SKILL_NAMES[@]}"; do
  SOURCE="${COMMANDS_DIR}/${SKILL_NAME}"
  DEST="${SKILLS_DIR}/${SKILL_NAME}"

  if [[ ! -d "$SOURCE" ]]; then
    echo "SKIP: '${SKILL_NAME}' not found at ${SOURCE}" >&2
    FAILED=$((FAILED + 1))
    continue
  fi

  rsync -a --delete \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.DS_Store' \
    --exclude='node_modules' \
    "${SOURCE}/" "${DEST}/"

  # Remove nested artifact: rsync can create DEST/SKILL_NAME/ if source was previously corrupted
  if [[ -d "${DEST}/${SKILL_NAME}" ]]; then
    rm -rf "${DEST:?}/${SKILL_NAME}"
    echo "  cleaned nested artifact: ${DEST}/${SKILL_NAME}" >&2
  fi

  echo "staged: ${SKILL_NAME}"
  STAGED=$((STAGED + 1))
done

echo ""
echo "done: $STAGED staged, $FAILED skipped"
