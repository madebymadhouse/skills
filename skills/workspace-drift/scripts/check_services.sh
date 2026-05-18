#!/usr/bin/env bash
# check_services.sh — HTTP health checks for configured service URLs
# Reads DASHBOARD_URL (and any SERVICE_URL_* vars) from ~/.secrets/master.env
# Output: JSON array of { area, name, status, detail }
# status: "healthy" | "down" | "skipped"
set -euo pipefail

SECRETS_FILE="${HOME}/.secrets/master.env"
RESULTS=()

if [[ -f "$SECRETS_FILE" ]]; then
  while IFS='=' read -r key val; do
    [[ "$key" =~ ^[A-Z_]+$ ]] || continue
    export "$key=$val"
  done < <(grep -E '^(DASHBOARD_URL|SERVICE_URL_[A-Z_]+)=' "$SECRETS_FILE" 2>/dev/null)
fi

check_url() {
  local name="$1" url="$2"
  if [[ -z "$url" ]]; then
    RESULTS+=("{\"area\":\"service\",\"name\":\"${name}\",\"status\":\"skipped\",\"detail\":\"url not configured\"}")
    return
  fi
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null || echo "timeout")
  if [[ "$code" =~ ^[23] ]] || [[ "$code" == "401" ]] || [[ "$code" == "403" ]]; then
    RESULTS+=("{\"area\":\"service\",\"name\":\"${name}\",\"status\":\"healthy\",\"detail\":\"http=${code}\"}")
  else
    RESULTS+=("{\"area\":\"service\",\"name\":\"${name}\",\"status\":\"down\",\"detail\":\"http=${code}\"}")
  fi
}

check_url "dashboard" "${DASHBOARD_URL:-}"

# Pick up any extra SERVICE_URL_* vars defined in master.env
while IFS='=' read -r key val; do
  [[ "$key" =~ ^SERVICE_URL_(.+)$ ]] || continue
  svc_name=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
  check_url "$svc_name" "$val"
done < <(grep '^SERVICE_URL_' "$SECRETS_FILE" 2>/dev/null || true)

echo "["
for i in "${!RESULTS[@]}"; do
  comma=","; [ $i -eq $((${#RESULTS[@]}-1)) ] && comma=""
  echo "  ${RESULTS[$i]}${comma}"
done
echo "]"
