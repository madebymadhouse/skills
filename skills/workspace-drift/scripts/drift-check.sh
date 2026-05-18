#!/usr/bin/env bash
# drift-check.sh — orchestrator: runs all check_*.sh tools and combines results
# Usage: drift-check.sh [--json] [--verbose] [--only git|services|vps|npm]
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_MODE=false
VERBOSE=false
ONLY=""

for arg in "$@"; do
  case $arg in
    --json)    JSON_MODE=true ;;
    --verbose) VERBOSE=true ;;
    --only)    ;;
  esac
done

# Handle --only <type> flag
args=("$@")
for i in "${!args[@]}"; do
  if [[ "${args[$i]}" == "--only" ]]; then
    ONLY="${args[$((i+1))]:-}"
  fi
done

log()  { echo "▸ $*" >&2; }
warn() { echo "  ⚠ $*" >&2; }

ALL_RESULTS=""

run_check() {
  local label="$1" script="$2"
  [[ -n "$ONLY" && "$ONLY" != "$label" ]] && return
  log "Checking ${label}..."
  local out
  out=$("$script" 2>/dev/null || echo "[]")
  # Strip outer [ ] and accumulate
  inner=$(echo "$out" | python3 -c "
import json, sys
items = json.load(sys.stdin)
for item in items:
    print(json.dumps(item))
" 2>/dev/null || true)
  if [[ -n "$inner" ]]; then
    ALL_RESULTS="${ALL_RESULTS}${inner}"$'\n'
  fi
  if $VERBOSE; then
    echo "$out" | python3 -c "
import json, sys
for item in json.load(sys.stdin):
    s = item.get('status','')
    n = item.get('name','')
    d = item.get('detail','')
    icon = '✓' if s in ('clean','healthy','current') else ('?' if s == 'skipped' else '⚠')
    print(f'  {icon} {n}: {s}' + (f' ({d})' if d else ''))
" >&2 2>/dev/null || true
  fi
}

run_check "git"      "${SCRIPTS_DIR}/check_git.sh"
run_check "services" "${SCRIPTS_DIR}/check_services.sh"
run_check "vps"      "${SCRIPTS_DIR}/check_vps.sh"
run_check "npm"      "${SCRIPTS_DIR}/check_npm.sh"

# Parse combined results
RESULTS_JSON=$(echo "$ALL_RESULTS" | python3 -c "
import json, sys
items = [json.loads(l) for l in sys.stdin if l.strip()]
total = len(items)
issues = sum(1 for i in items if i.get('status') in ('drift','down','outdated'))
print(json.dumps({'timestamp': __import__('datetime').datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'), 'total': total, 'issues': issues, 'results': items}, indent=2))
" 2>/dev/null || echo '{"error":"failed to combine results"}')

issue_count=$(echo "$RESULTS_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('issues',0))" 2>/dev/null || echo 0)
total_count=$(echo "$RESULTS_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('total',0))" 2>/dev/null || echo 0)

log ""
log "── Drift Check Complete ──────────────────────────────────────────────────"
log "Total checks: ${total_count} | Issues: ${issue_count}"

if $JSON_MODE; then
  echo "$RESULTS_JSON"
fi

[ "$issue_count" -eq 0 ] && exit 0 || exit 1
