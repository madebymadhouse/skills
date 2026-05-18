#!/usr/bin/env bash
# logs.sh <uuid> [--lines N] — fetch recent deployment logs
# Output: JSON { uuid, lines: [...] }
# Default: last 20 lines
set -euo pipefail

UUID="${1:-}"
LINES=20

if [[ -z "$UUID" ]]; then
  echo '{"error":"uuid required"}' >&2; exit 1
fi

shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --lines) LINES="${2:-20}"; shift 2 ;;
    *) shift ;;
  esac
done

SECRETS_FILE="${HOME}/.secrets/master.env"
COOLIFY_API_BASE=$(grep -m1 '^COOLIFY_API_BASE=' "$SECRETS_FILE" | cut -d= -f2-)
COOLIFY_API_TOKEN=$(grep -m1 '^COOLIFY_API_TOKEN=' "$SECRETS_FILE" | cut -d= -f2-)

raw=$(curl -sf -X GET \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  "${COOLIFY_API_BASE}/api/v1/applications/${UUID}/logs" 2>/dev/null || echo "[]")

echo "$raw" | python3 -c "
import json, sys

N = ${LINES}
data = json.load(sys.stdin)
lines = data if isinstance(data, list) else data.get('logs', [])
tail = lines[-N:]

output = []
for line in tail:
    if isinstance(line, dict):
        output.append(line.get('output', str(line)))
    else:
        output.append(str(line))

print(json.dumps({'uuid': '${UUID}', 'lines': output}))
"
