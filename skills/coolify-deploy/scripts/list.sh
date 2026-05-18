#!/usr/bin/env bash
# list.sh — list all Coolify applications and services
# Output: JSON { applications: [...], services: [...] }
# Each item: { uuid, name, status, fqdn }
set -euo pipefail

SECRETS_FILE="${HOME}/.secrets/master.env"

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo '{"error":"secrets file not found"}' >&2; exit 1
fi

COOLIFY_API_BASE=$(grep -m1 '^COOLIFY_API_BASE=' "$SECRETS_FILE" | cut -d= -f2-)
COOLIFY_API_TOKEN=$(grep -m1 '^COOLIFY_API_TOKEN=' "$SECRETS_FILE" | cut -d= -f2-)

if [[ -z "$COOLIFY_API_BASE" || -z "$COOLIFY_API_TOKEN" ]]; then
  echo '{"error":"COOLIFY_API_BASE or COOLIFY_API_TOKEN not set"}' >&2; exit 1
fi

tmpapps=$(mktemp)
tmpsvc=$(mktemp)
trap 'rm -f "$tmpapps" "$tmpsvc"' EXIT

curl -sf -X GET \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  "${COOLIFY_API_BASE}/api/v1/applications" 2>/dev/null > "$tmpapps" || echo "[]" > "$tmpapps"

curl -sf -X GET \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  "${COOLIFY_API_BASE}/api/v1/services" 2>/dev/null > "$tmpsvc" || echo "[]" > "$tmpsvc"

python3 - "$tmpapps" "$tmpsvc" <<'EOF'
import json, sys

with open(sys.argv[1]) as f:
    apps = json.load(f)
with open(sys.argv[2]) as f:
    services = json.load(f)

out = {
    "applications": [
        {
            "uuid": a.get("uuid", ""),
            "name": a.get("name", ""),
            "status": a.get("status", "unknown"),
            "fqdn": a.get("fqdn", "")
        }
        for a in (apps if isinstance(apps, list) else [])
    ],
    "services": [
        {
            "uuid": s.get("uuid", ""),
            "name": s.get("name", ""),
            "status": s.get("status", "unknown"),
            "fqdn": s.get("fqdn", "")
        }
        for s in (services if isinstance(services, list) else [])
    ]
}

print(json.dumps(out, indent=2))
EOF
