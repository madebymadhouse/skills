#!/usr/bin/env bash
# Show status of Urchin import directories and connector availability.
set -uo pipefail

IMPORT_BASE="$HOME/.local/share/urchin/imports"

echo "=== Urchin Import Sources ==="
declare -A SOURCES=(
  ["apple-health"]="$IMPORT_BASE/apple-health/export.xml"
  ["bank-csv"]="$IMPORT_BASE/bank"
  ["calendar"]="$IMPORT_BASE/calendar"
  ["google-takeout"]="$IMPORT_BASE/google-takeout"
)

for name in "${!SOURCES[@]}"; do
  path="${SOURCES[$name]}"
  if [ -e "$path" ]; then
    if [ -d "$path" ]; then
      count=$(find "$path" -type f | wc -l | tr -d ' ')
      echo "  $name: READY ($count files)"
    else
      size=$(du -sh "$path" 2>/dev/null | cut -f1)
      echo "  $name: READY ($size)"
    fi
  else
    echo "  $name: no data (drop files at $path)"
  fi
done

echo ""
echo "=== Auto Collectors ==="
for collector in claude copilot gemini codex opencode shell; do
  echo "  $collector: auto (no drop needed)"
done

echo ""
echo "Run: urchin collect        (all)"
echo "Run: urchin collect NAME   (single connector)"
