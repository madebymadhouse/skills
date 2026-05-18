#!/usr/bin/env bash
# status.sh <uuid> — get current status of an application
# Output: JSON { uuid, name, status, healthy }
set -euo pipefail

UUID="${1:-}"
if [[ -z "$UUID" ]]; then
  echo '{"error":"uuid required"}' >&2; exit 1
fi

SECRETS_FILE="${HOME}/.secrets/master.env"
COOLIFY_API_BASE=$(grep -m1 '^COOLIFY_API_BASE=' "$SECRETS_FILE" | cut -d= -f2-)
COOLIFY_API_TOKEN=$(grep -m1 '^COOLIFY_API_TOKEN=' "$SECRETS_FILE" | cut -d= -f2-)

app=$(curl -sf -X GET \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  "${COOLIFY_API_BASE}/api/v1/applications/${UUID}" 2>/dev/null || echo "{}")

echo "$app" | python3 -c "
import json, sys
app = json.load(sys.stdin)
status = app.get('status', 'unknown')
print(json.dumps({
    'uuid': app.get('uuid', '${UUID}'),
    'name': app.get('name', 'unknown'),
    'status': status,
    'healthy': status == 'running'
}))
"
