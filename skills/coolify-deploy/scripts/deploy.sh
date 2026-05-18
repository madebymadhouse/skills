#!/usr/bin/env bash
set -euo pipefail

SECRETS_FILE="${HOME}/.secrets/master.env"
COMMAND="${1:-list}"
TARGET="${2:-}"

# Load config
if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "ERROR: ${SECRETS_FILE} not found" >&2
  exit 1
fi

COOLIFY_API_BASE=$(grep -m1 '^COOLIFY_API_BASE=' "$SECRETS_FILE" | cut -d= -f2-)
COOLIFY_API_TOKEN=$(grep -m1 '^COOLIFY_API_TOKEN=' "$SECRETS_FILE" | cut -d= -f2-)

if [[ -z "$COOLIFY_API_BASE" || -z "$COOLIFY_API_TOKEN" ]]; then
  echo "ERROR: COOLIFY_API_BASE and COOLIFY_API_TOKEN must be set in ${SECRETS_FILE}" >&2
  exit 1
fi

api() {
  local method="$1"
  local path="$2"
  curl -sf -X "$method" \
    -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${COOLIFY_API_BASE}${path}"
}

list_apps() {
  echo "=== APPLICATIONS ==="
  api GET "/api/v1/applications" | python3 -c "
import json, sys
apps = json.load(sys.stdin)
for app in apps:
    uuid = app.get('uuid', 'unknown')
    name = app.get('name', 'unnamed')
    status = app.get('status', 'unknown')
    fqdn = app.get('fqdn', '')
    print(f'APP | {name} | {status} | {uuid} | {fqdn}')
" 2>/dev/null || echo "ERROR: failed to parse applications response"

  echo ""
  echo "=== SERVICES ==="
  api GET "/api/v1/services" | python3 -c "
import json, sys
services = json.load(sys.stdin)
for svc in services:
    uuid = svc.get('uuid', 'unknown')
    name = svc.get('name', 'unnamed')
    status = svc.get('status', 'unknown')
    print(f'SERVICE | {name} | {status} | {uuid}')
" 2>/dev/null || echo "ERROR: failed to parse services response"
}

fuzzy_match() {
  local query="$1"
  local json_input
  json_input=$(api GET "/api/v1/applications")

  echo "$json_input" | python3 -c "
import json, sys
query = '${query}'.lower()
apps = json.load(sys.stdin)
matches = []
for app in apps:
    name = app.get('name', '')
    if query in name.lower():
        matches.append(app)
if not matches:
    print('NO_MATCH')
elif len(matches) == 1:
    print('MATCH', matches[0]['uuid'], matches[0]['name'])
else:
    print('AMBIGUOUS')
    for m in matches:
        print(' ', m['name'], '|', m['uuid'])
"
}

poll_status() {
  local uuid="$1"
  local max_wait=120
  local elapsed=0
  local interval=5

  echo "POLLING: waiting for deploy to complete (max ${max_wait}s)..."

  while [[ $elapsed -lt $max_wait ]]; do
    status=$(api GET "/api/v1/applications/${uuid}" | python3 -c "
import json, sys
app = json.load(sys.stdin)
print(app.get('status', 'unknown'))
" 2>/dev/null || echo "unknown")

    echo "STATUS: ${status} (${elapsed}s)"

    if [[ "$status" == "running" ]]; then
      echo "HEALTHY: application is running"
      return 0
    elif [[ "$status" == "exited" || "$status" == "stopped" ]]; then
      echo "FAILED: application stopped"
      return 1
    fi

    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  echo "TIMEOUT: deploy did not complete within ${max_wait}s"
  return 1
}

fetch_logs() {
  local uuid="$1"
  echo "=== LAST 20 LOG LINES ==="
  api GET "/api/v1/applications/${uuid}/logs" | python3 -c "
import json, sys
data = json.load(sys.stdin)
lines = data if isinstance(data, list) else data.get('logs', [])
for line in lines[-20:]:
    if isinstance(line, dict):
        print(line.get('output', line))
    else:
        print(line)
" 2>/dev/null || echo "(could not fetch logs)"
}

case "$COMMAND" in
  list)
    list_apps
    ;;

  deploy)
    if [[ -z "$TARGET" ]]; then
      echo "ERROR: deploy requires a service name" >&2
      exit 1
    fi

    echo "SEARCHING: '${TARGET}'"
    result=$(fuzzy_match "$TARGET")

    first_word=$(echo "$result" | awk 'NR==1{print $1}')

    case "$first_word" in
      NO_MATCH)
        echo "ERROR: no application matching '${TARGET}'" >&2
        echo "Run 'deploy.sh list' to see all services." >&2
        exit 1
        ;;
      AMBIGUOUS)
        echo "ERROR: multiple matches for '${TARGET}'" >&2
        echo "$result" >&2
        exit 1
        ;;
      MATCH)
        uuid=$(echo "$result" | awk '{print $2}')
        name=$(echo "$result" | awk '{$1=$2=""; print $0}' | xargs)
        echo "MATCHED: ${name} (${uuid})"
        ;;
    esac

    echo "DEPLOYING: triggering start..."
    api POST "/api/v1/applications/${uuid}/start" > /dev/null 2>&1 || true
    echo "TRIGGERED"

    if ! poll_status "$uuid"; then
      fetch_logs "$uuid"
      exit 1
    fi
    ;;

  *)
    echo "Usage: deploy.sh [list|deploy <name>]" >&2
    exit 1
    ;;
esac
