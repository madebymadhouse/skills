#!/usr/bin/env bash
# check_vps.sh — check VPS SSH connectivity and Coolify API health
# Reads VPS_SSH_HOST, COOLIFY_API_URL, COOLIFY_API_TOKEN from ~/.secrets/master.env
# Output: JSON array of { area, name, status, detail }
# status: "healthy" | "down" | "skipped"
set -euo pipefail

SECRETS_FILE="${HOME}/.secrets/master.env"
RESULTS=()

if [[ -f "$SECRETS_FILE" ]]; then
  while IFS='=' read -r key val; do
    [[ "$key" =~ ^[A-Z_]+$ ]] || continue
    export "$key=$val"
  done < <(grep -E '^(VPS_SSH_HOST|COOLIFY_API_URL|COOLIFY_API_TOKEN)=' "$SECRETS_FILE" 2>/dev/null)
fi

VPS_SSH_HOST="${VPS_SSH_HOST:-}"
COOLIFY_API_URL="${COOLIFY_API_URL:-}"
COOLIFY_API_TOKEN="${COOLIFY_API_TOKEN:-}"

# SSH connectivity
if [[ -n "$VPS_SSH_HOST" ]]; then
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes \
      "$VPS_SSH_HOST" "echo ok" &>/dev/null; then
    RESULTS+=("{\"area\":\"infra\",\"name\":\"vps-ssh\",\"status\":\"healthy\",\"detail\":\"\"}")
  else
    RESULTS+=("{\"area\":\"infra\",\"name\":\"vps-ssh\",\"status\":\"down\",\"detail\":\"host=${VPS_SSH_HOST}\"}")
  fi
else
  RESULTS+=("{\"area\":\"infra\",\"name\":\"vps-ssh\",\"status\":\"skipped\",\"detail\":\"VPS_SSH_HOST not configured\"}")
fi

# Coolify API
if [[ -n "$COOLIFY_API_URL" && -n "$COOLIFY_API_TOKEN" ]]; then
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 \
    -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "${COOLIFY_API_URL}/api/v1/version" 2>/dev/null || echo "timeout")
  if [[ "$code" =~ ^2 ]]; then
    RESULTS+=("{\"area\":\"infra\",\"name\":\"coolify-api\",\"status\":\"healthy\",\"detail\":\"http=${code}\"}")
  else
    RESULTS+=("{\"area\":\"infra\",\"name\":\"coolify-api\",\"status\":\"down\",\"detail\":\"http=${code}\"}")
  fi
else
  RESULTS+=("{\"area\":\"infra\",\"name\":\"coolify-api\",\"status\":\"skipped\",\"detail\":\"COOLIFY_API_URL or COOLIFY_API_TOKEN not configured\"}")
fi

echo "["
for i in "${!RESULTS[@]}"; do
  comma=","; [ $i -eq $((${#RESULTS[@]}-1)) ] && comma=""
  echo "  ${RESULTS[$i]}${comma}"
done
echo "]"
