#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="${1:-}"
COMMANDS_DIR="${HOME}/.claude/commands"
REPO_DIR="${HOME}/dev/mad-house/skills"
SKILLS_DIR="${REPO_DIR}/skills"

if [[ -z "$SKILL_NAME" ]]; then
  echo "Usage: stage.sh <skill-name>" >&2
  exit 1
fi

SOURCE="${COMMANDS_DIR}/${SKILL_NAME}"
DEST="${SKILLS_DIR}/${SKILL_NAME}"

if [[ ! -d "$SOURCE" ]]; then
  echo "ERROR: skill '${SKILL_NAME}' not found at ${SOURCE}" >&2
  echo "Available skills:" >&2
  ls "${COMMANDS_DIR}" >&2
  exit 1
fi

if [[ ! -d "${REPO_DIR}" ]]; then
  echo "ERROR: skills repo not found at ${REPO_DIR}" >&2
  exit 1
fi

# Copy skill into repo, excluding local-only artifacts
# No --delete: repo may have files (LICENSE, etc.) not present locally
rsync -av \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  --exclude='.DS_Store' \
  --exclude='node_modules' \
  "${SOURCE}/" "${DEST}/"

echo "STAGED: ${SKILL_NAME} -> ${DEST}"
echo "FILES:"
find "${DEST}" -type f | sort
