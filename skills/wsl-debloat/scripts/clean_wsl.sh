#!/usr/bin/env bash
# clean_wsl.sh — clear WSL package manager caches
# Output: JSON { disk_before, disk_after, cleaned: [{name, freed}], skipped: [name] }
set -euo pipefail

disk_used() { df -h / | awk 'NR==2{print $3}'; }
disk_pct()  { df -h / | awk 'NR==2{print $5}'; }

disk_before_used=$(disk_used)
disk_before_pct=$(disk_pct)

cleaned=()
skipped=()

clean_cache() {
  local name="$1" path="$2"
  if [[ -d "$path" ]]; then
    size=$(du -sh "$path" 2>/dev/null | cut -f1 || echo "?")
    rm -rf "$path"
    cleaned+=("{\"name\":\"${name}\",\"freed\":\"${size}\"}")
  else
    skipped+=("\"${name}\"")
  fi
}

# npm — get size first, then clean via npm cli
npm_path=$(npm config get cache 2>/dev/null || echo "${HOME}/.npm")
if [[ -d "$npm_path" ]]; then
  npm_size=$(du -sh "$npm_path" 2>/dev/null | cut -f1 || echo "?")
  npm cache clean --force --quiet 2>/dev/null || true
  cleaned+=("{\"name\":\"npm\",\"freed\":\"${npm_size}\"}")
else
  skipped+=("\"npm\"")
fi

clean_cache "pip"        "${HOME}/.cache/pip"
clean_cache "pnpm"       "${HOME}/.cache/pnpm"
clean_cache "playwright" "${HOME}/.cache/ms-playwright-go"
clean_cache "node-gyp"   "${HOME}/.cache/node-gyp"
clean_cache "puppeteer"  "${HOME}/.cache/puppeteer"
clean_cache "prisma"     "${HOME}/.cache/prisma"
clean_cache "cargo"      "${HOME}/.cargo/registry/cache"
clean_cache "go-mod"     "${HOME}/go/pkg/mod/cache"

disk_after_used=$(disk_used)
disk_after_pct=$(disk_pct)

# Build JSON
cleaned_json=$(IFS=,; echo "[${cleaned[*]:-}]")
skipped_json=$(IFS=,; echo "[${skipped[*]:-}]")

python3 -c "
import json, sys
print(json.dumps({
    'disk_before': {'used': '${disk_before_used}', 'percent': '${disk_before_pct}'},
    'disk_after':  {'used': '${disk_after_used}',  'percent': '${disk_after_pct}'},
    'cleaned': json.loads('${cleaned_json}'),
    'skipped': json.loads('${skipped_json}')
}, indent=2))
"
