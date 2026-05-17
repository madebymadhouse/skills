#!/bin/bash
# debloat.sh — free disk space on WSL and optionally VPS
#
# WSL: clears npm, pip, pnpm, playwright, node-gyp, puppeteer, prisma caches
#      reports lab node_modules (--clean-lab to remove them)
# VPS: runs docker builder prune, image prune, volume prune via SSH
#
# Usage:
#   ./debloat.sh                     # WSL caches only
#   ./debloat.sh --vps               # WSL + VPS docker prune
#   ./debloat.sh --clean-lab         # also remove lab node_modules
#   ./debloat.sh --vps --clean-lab   # full cleanup
#
# Config: set VPS_SSH_HOST=user@host in ~/.secrets/master.env, or export it directly

set -euo pipefail

# Read VPS host from secrets if not already set
if [ -f "$HOME/.secrets/master.env" ]; then
  set +a; source <(grep -E '^VPS_SSH_HOST=' "$HOME/.secrets/master.env"); set -a 2>/dev/null || true
fi
VPS_HOST="${VPS_SSH_HOST:-}"
DO_VPS=false
CLEAN_LAB=false
LAB_ROOT="$HOME/dev/mad-house/lab"

for arg in "$@"; do
  case $arg in
    --vps) DO_VPS=true ;;
    --clean-lab) CLEAN_LAB=true ;;
  esac
done

if $DO_VPS && [ -z "$VPS_HOST" ]; then
  echo "error: --vps requires VPS_SSH_HOST to be set (add to ~/.secrets/master.env)"
  exit 1
fi

hr() { echo "────────────────────────────────────────"; }
disk_wsl() { df -h / | awk 'NR==2 {print $3 " used / " $2 " (" $5 ")"}'; }
disk_vps() { ssh -o ConnectTimeout=8 "$VPS_HOST" "df -h / | awk 'NR==2 {print \$3 \" used / \" \$2 \" (\" \$5 \")\"}'" 2>/dev/null; }

echo
echo "===== WSL DEBLOAT — $(date '+%Y-%m-%d %H:%M:%S') ====="
hr

echo "BEFORE"
echo "  WSL : $(disk_wsl)"
$DO_VPS && echo "  VPS : $(disk_vps)"
hr

echo "[ WSL CACHES ]"

clean_cache() {
  local label="$1" path="$2"
  if [[ -d "$path" ]]; then
    size=$(du -sh "$path" 2>/dev/null | cut -f1)
    rm -rf "$path"
    echo "  cleared $label ($size)"
  fi
}

npm cache clean --force --quiet 2>/dev/null && echo "  cleared npm cache"
clean_cache "pip cache"            "$HOME/.cache/pip"
clean_cache "pnpm cache"           "$HOME/.cache/pnpm"
clean_cache "puppeteer cache"      "$HOME/.cache/puppeteer"
clean_cache "playwright-go cache"  "$HOME/.cache/ms-playwright-go"
clean_cache "node-gyp cache"       "$HOME/.cache/node-gyp"
clean_cache "prisma cache"         "$HOME/.cache/prisma"

hr

echo "[ LAB NODE_MODULES ]"
found_any=false
if [ -d "$LAB_ROOT" ]; then
  while IFS= read -r -d '' nm; do
    parent=$(dirname "$nm")
    size=$(du -sh "$nm" 2>/dev/null | cut -f1)
    found_any=true
    if $CLEAN_LAB; then
      rm -rf "$nm"
      echo "  removed: ${parent#"$HOME/"} node_modules ($size)"
    else
      echo "  found: ${parent#"$HOME/"} node_modules ($size) — pass --clean-lab to remove"
    fi
  done < <(find "$LAB_ROOT" -maxdepth 3 -name "node_modules" -type d -print0 2>/dev/null)
fi
$found_any || echo "  none found"

hr

if $DO_VPS; then
  echo "[ VPS DOCKER ]"
  ssh -o ConnectTimeout=10 "$VPS_HOST" "
    echo '  build cache:'
    docker builder prune -f 2>&1 | grep -E 'Total|reclaimed' | sed 's/^/    /'
    echo '  unused images:'
    docker image prune -f 2>&1 | grep -E 'Total|reclaimed' | sed 's/^/    /'
    echo '  unused volumes:'
    docker volume prune -f 2>&1 | grep -E 'Total|reclaimed' | sed 's/^/    /'
  " 2>/dev/null
  hr
fi

echo "AFTER"
echo "  WSL : $(disk_wsl)"
$DO_VPS && echo "  VPS : $(disk_vps)"
hr
echo "done."
echo
