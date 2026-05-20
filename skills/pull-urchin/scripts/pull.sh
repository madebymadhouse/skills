#!/usr/bin/env bash
# Pull Urchin events into vault.
set -uo pipefail

SCRIPT="${PULL_URCHIN_SCRIPT:-$HOME/scripts/pull-urchin.py}"

if [ ! -f "$SCRIPT" ]; then
  echo "ERROR: $SCRIPT not found"
  exit 1
fi

if ! curl -sf --max-time 3 "http://127.0.0.1:18799/health" >/dev/null 2>&1; then
  echo "ERROR: Urchin daemon not reachable at 127.0.0.1:18799"
  echo "Start it with: urchin daemon"
  exit 1
fi

python3 "$SCRIPT" "$@"
