#!/usr/bin/env bash
# search.sh <query> — fuzzy match an application by name
# Output: JSON { matched: bool, uuid, name, candidates: [{uuid, name, status}] }
# matched=true and uuid/name set when exactly one result.
# matched=false and candidates populated when zero or multiple results.
set -euo pipefail

QUERY="${1:-}"
if [[ -z "$QUERY" ]]; then
  echo '{"error":"query required"}' >&2; exit 1
fi

SECRETS_FILE="${HOME}/.secrets/master.env"
COOLIFY_API_BASE=$(grep -m1 '^COOLIFY_API_BASE=' "$SECRETS_FILE" | cut -d= -f2-)
COOLIFY_API_TOKEN=$(grep -m1 '^COOLIFY_API_TOKEN=' "$SECRETS_FILE" | cut -d= -f2-)

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

curl -sf -X GET \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  "${COOLIFY_API_BASE}/api/v1/applications" 2>/dev/null > "$tmpfile" || echo "[]" > "$tmpfile"

QUERY="$QUERY" python3 - "$tmpfile" <<'EOF'
import json, sys, os

query = os.environ["QUERY"].lower()
with open(sys.argv[1]) as f:
    apps = json.load(f)

if not isinstance(apps, list):
    apps = []

matches = [a for a in apps if query in a.get("name", "").lower()]

if len(matches) == 1:
    m = matches[0]
    print(json.dumps({
        "matched": True,
        "uuid": m.get("uuid", ""),
        "name": m.get("name", ""),
        "candidates": []
    }))
else:
    candidates = [
        {"uuid": a.get("uuid", ""), "name": a.get("name", ""), "status": a.get("status", "unknown")}
        for a in (matches if matches else apps)
    ]
    print(json.dumps({
        "matched": False,
        "uuid": "",
        "name": "",
        "candidates": candidates
    }))
EOF
