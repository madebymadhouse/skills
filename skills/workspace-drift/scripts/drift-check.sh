#!/usr/bin/env bash
# drift-check.sh — automated drift detection across repos and live services
# Outputs machine-readable JSON to stdout + human summary to stderr
# Usage: ./drift-check.sh [--json] [--verbose]
#
# Config (add to ~/.secrets/master.env):
#   VPS_SSH_HOST=user@your.vps.ip
#   COOLIFY_API_URL=http://your.vps.ip:8000
#   COOLIFY_API_TOKEN=your_token
#   DASHBOARD_URL=https://your-dashboard-url
#   (add more SERVICE_URL_* vars for additional HTTP health checks)

set -euo pipefail

JSON_MODE=false
VERBOSE=false
for arg in "$@"; do
  case $arg in
    --json) JSON_MODE=true ;;
    --verbose) VERBOSE=true ;;
  esac
done

# Load config from master.env if present
if [ -f "$HOME/.secrets/master.env" ]; then
  while IFS='=' read -r key val; do
    [[ "$key" =~ ^[A-Z_]+$ ]] || continue
    export "$key=$val"
  done < <(grep -E '^(VPS_SSH_HOST|COOLIFY_API_URL|COOLIFY_API_TOKEN|DASHBOARD_URL)=' "$HOME/.secrets/master.env" 2>/dev/null)
fi

VPS_SSH_HOST="${VPS_SSH_HOST:-}"
COOLIFY_API_URL="${COOLIFY_API_URL:-}"
COOLIFY_API_TOKEN="${COOLIFY_API_TOKEN:-}"
DASHBOARD_URL="${DASHBOARD_URL:-}"

# Auto-discover repo roots from ~/dev (exclude hidden dirs)
REPO_ROOTS=()
while IFS= read -r dir; do
  REPO_ROOTS+=("$dir")
done < <(find ~/dev -maxdepth 1 -mindepth 1 -type d ! -name '.*' 2>/dev/null | sort)

# ── Helpers ────���───────────────────────���──────────────────────────────────────
log() { echo "▸ $*" >&2; }
ok()  { echo "  ✓ $*" >&2; }
warn(){ echo "  ⚠ $*" >&2; }
err() { echo "  ✗ $*" >&2; }

RESULTS=()
add_result() {
  local area="$1" name="$2" status="$3" detail="${4:-}"
  RESULTS+=("{\"area\":\"$area\",\"name\":\"$name\",\"status\":\"$status\",\"detail\":\"$detail\"}")
}

# ── 1. Git repo drift ────────────────────────��─────────────────────────────────
log "Checking git repos..."
for root in "${REPO_ROOTS[@]}"; do
  [ -d "$root" ] || continue
  while IFS= read -r -d '' gitdir; do
    repo_dir="$(dirname "$gitdir")"
    repo_name="${repo_dir#"$HOME/"}"

    dirty=$(git -C "$repo_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    upstream=$(git -C "$repo_dir" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo "")
    ahead=0; behind=0
    if [ -n "$upstream" ]; then
      ahead=$(git -C "$repo_dir" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)
      behind=$(git -C "$repo_dir" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo 0)
    fi

    if [ "$dirty" -gt 0 ] || [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
      detail="dirty=$dirty ahead=$ahead behind=$behind"
      warn "$repo_name: $detail"
      add_result "git" "$repo_name" "drift" "$detail"
    else
      $VERBOSE && ok "$repo_name: clean"
      add_result "git" "$repo_name" "clean" ""
    fi
  done < <(find "$root" -maxdepth 3 -name ".git" -type d -print0 2>/dev/null)
done

# ── 2. Service health checks ────────────────��─────────────────────────────────
log "Checking service health..."

check_service() {
  local name="$1" url="$2"
  if [ -z "$url" ]; then
    $VERBOSE && warn "$name: URL not configured — skipping"
    return 0
  fi
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null || echo "timeout")
  if [[ "$code" =~ ^[23] ]] || [ "$code" = "401" ] || [ "$code" = "403" ]; then
    $VERBOSE && ok "$name: $code"
    add_result "service" "$name" "healthy" "http=$code"
  else
    warn "$name: $code at $url"
    add_result "service" "$name" "down" "http=$code url=$url"
  fi
}

check_service "dashboard" "$DASHBOARD_URL"

# ── 3. VPS SSH ──────────────────────────────────────────────────���─────────────
log "Checking VPS SSH..."
if [ -n "$VPS_SSH_HOST" ]; then
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes \
      "$VPS_SSH_HOST" "echo ok" &>/dev/null; then
    $VERBOSE && ok "VPS SSH reachable"
    add_result "infra" "vps-ssh" "healthy" ""
  else
    err "VPS SSH unreachable"
    add_result "infra" "vps-ssh" "down" "host=$VPS_SSH_HOST"
  fi
else
  warn "VPS_SSH_HOST not configured — skipping"
fi

# ── 4. Coolify API ────────────────────────���──────────────────────────��────────
log "Checking Coolify API..."
if [ -n "$COOLIFY_API_URL" ] && [ -n "$COOLIFY_API_TOKEN" ]; then
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 \
    -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "${COOLIFY_API_URL}/api/v1/version" 2>/dev/null || echo "timeout")
  if [[ "$code" =~ ^2 ]]; then
    $VERBOSE && ok "Coolify API: $code"
    add_result "infra" "coolify-api" "healthy" "http=$code"
  else
    warn "Coolify API: $code"
    add_result "infra" "coolify-api" "degraded" "http=$code"
  fi
else
  warn "COOLIFY_API_URL or COOLIFY_API_TOKEN not configured — skipping"
fi

# ── 5. npm outdated (auto-discovered package.json projects) ───��──────────────
log "Checking npm packages..."
while IFS= read -r pkg; do
  repo_dir="$(dirname "$pkg")"
  repo_name="${repo_dir#"$HOME/"}"
  outdated=$(npm outdated --prefix "$repo_dir" 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
  if [ "$outdated" -gt 0 ]; then
    warn "$repo_name: $outdated outdated package(s)"
    add_result "packages" "$repo_name" "outdated" "count=$outdated"
  else
    $VERBOSE && ok "$repo_name: packages current"
    add_result "packages" "$repo_name" "current" ""
  fi
done < <(find ~/dev -maxdepth 3 -name "package.json" \
  ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | head -20)

# ── 6. Summary ─────────────────��──────────────────────────────���───────────────
total=${#RESULTS[@]}
drift_count=$(printf '%s\n' "${RESULTS[@]}" | grep -c '"status":"drift"\|"status":"down"\|"status":"outdated"' || true)

log ""
log "── Drift Check Complete ─────��────────────────────────────────────────────"
log "Total checks: $total | Issues: $drift_count"

if $JSON_MODE; then
  echo "{"
  echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"total\": $total,"
  echo "  \"issues\": $drift_count,"
  echo "  \"results\": ["
  for i in "${!RESULTS[@]}"; do
    comma=","; [ $i -eq $((${#RESULTS[@]}-1)) ] && comma=""
    echo "    ${RESULTS[$i]}$comma"
  done
  echo "  ]"
  echo "}"
fi

[ "$drift_count" -eq 0 ] && exit 0 || exit 1
