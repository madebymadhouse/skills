#!/usr/bin/env bash
# debloat.sh — orchestrator: scan then clean everything applicable
# The SKILL.md calls tools directly; this script exists for manual/backward-compat use.
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== SCAN ===" >&2
"${SCRIPTS_DIR}/scan.sh"

echo "" >&2
echo "=== CLEAN WSL ===" >&2
"${SCRIPTS_DIR}/clean_wsl.sh"

SECRETS_FILE="${HOME}/.secrets/master.env"
VPS_SSH_HOST=""
[[ -f "$SECRETS_FILE" ]] && VPS_SSH_HOST=$(grep -m1 '^VPS_SSH_HOST=' "$SECRETS_FILE" | cut -d= -f2- || true)

if [[ -n "$VPS_SSH_HOST" ]]; then
  echo "" >&2
  echo "=== CLEAN VPS ===" >&2
  "${SCRIPTS_DIR}/clean_vps.sh"
fi

nm_count=$(find "${HOME}/dev" -maxdepth 4 -name "node_modules" -type d \
  ! -path "*/node_modules/*/node_modules" 2>/dev/null | wc -l || echo 0)
if [[ "$nm_count" -gt 0 ]]; then
  echo "" >&2
  echo "=== CLEAN LAB ===" >&2
  "${SCRIPTS_DIR}/clean_lab.sh"
fi
