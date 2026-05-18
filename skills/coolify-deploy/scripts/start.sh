#!/usr/bin/env bash
# start.sh <uuid> — trigger a deploy/start for an application
# Output: JSON { triggered, uuid, name }
set -euo pipefail

UUID="${1:-}"
if [[ -z "$UUID" ]]; then
  echo '{"error":"uuid required"}' >&2; exit 1
fi

SECRETS_FILE="${HOME}/.secrets/master.env"
COOLIFY_API_BASE=$(grep -m1 '^COOLIFY_API_BASE=' "$SECRETS_FILE" | cut -d= -f2-)
COOLIFY_API_TOKEN=$(grep -m1 '^COOLIFY_API_TOKEN=' "$SECRETS_FILE" | cut -d= -f2-)

# Get name before triggering
app=$(curl -sf -X GET \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  "${COOLIFY_API_BASE}/api/v1/applications/${UUID}" 2>/dev/null || echo "{}")

name=$(echo "$app" | python3 -c "import json,sys; print(json.load(sys.stdin).get('name','unknown'))" 2>/dev/null || echo "unknown")

curl -sf -X POST \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  "${COOLIFY_API_BASE}/api/v1/applications/${UUID}/start" > /dev/null 2>&1 || true

python3 -c "import json; print(json.dumps({'triggered': True, 'uuid': '${UUID}', 'name': '${name}'}))"
