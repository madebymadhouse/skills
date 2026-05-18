#!/usr/bin/env bash
# clean_vps.sh — prune Docker build cache, unused images, volumes on VPS
# Output: JSON { available, disk_before, disk_after, pruned: {build_cache, images, volumes} }
set -euo pipefail

SECRETS_FILE="${HOME}/.secrets/master.env"
VPS_SSH_HOST=""
[[ -f "$SECRETS_FILE" ]] && VPS_SSH_HOST=$(grep -m1 '^VPS_SSH_HOST=' "$SECRETS_FILE" | cut -d= -f2- || true)

if [[ -z "$VPS_SSH_HOST" ]]; then
  echo '{"available":false,"reason":"VPS_SSH_HOST not configured"}'
  exit 0
fi

if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$VPS_SSH_HOST" "echo ok" &>/dev/null; then
  echo '{"available":false,"reason":"unreachable"}'
  exit 0
fi

tmpresult=$(mktemp)
trap 'rm -f "$tmpresult"' EXIT

ssh -o ConnectTimeout=30 "$VPS_SSH_HOST" '
  used_before=$(df -h / | awk "NR==2{print \$3}")
  pct_before=$(df -h / | awk "NR==2{print \$5}")

  build=$(docker builder prune -f 2>&1 | grep -oE "[0-9]+(\.[0-9]+)?(B|kB|MB|GB)" | tail -1 || echo "0B")
  images=$(docker image prune -f 2>&1 | grep -oE "[0-9]+(\.[0-9]+)?(B|kB|MB|GB)" | tail -1 || echo "0B")
  volumes=$(docker volume prune -f 2>&1 | grep -oE "[0-9]+(\.[0-9]+)?(B|kB|MB|GB)" | tail -1 || echo "0B")

  used_after=$(df -h / | awk "NR==2{print \$3}")
  pct_after=$(df -h / | awk "NR==2{print \$5}")

  echo "{\"available\":true,\"disk_before\":{\"used\":\"$used_before\",\"percent\":\"$pct_before\"},\"disk_after\":{\"used\":\"$used_after\",\"percent\":\"$pct_after\"},\"pruned\":{\"build_cache\":\"$build\",\"images\":\"$images\",\"volumes\":\"$volumes\"}}"
' > "$tmpresult" 2>/dev/null || echo '{"available":false,"error":"ssh command failed"}' > "$tmpresult"

cat "$tmpresult"
