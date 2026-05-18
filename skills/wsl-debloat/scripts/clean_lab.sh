#!/usr/bin/env bash
# clean_lab.sh — remove node_modules from projects under ~/dev
# Output: JSON { removed: [{path, freed}], skipped_count, total_freed_note }
set -euo pipefail

removed=()
total_bytes=0

while IFS= read -r nm; do
  parent="${nm%/node_modules}"
  rel_path="${parent#"${HOME}/"}"
  size=$(du -sh "$nm" 2>/dev/null | cut -f1 || echo "?")
  rm -rf "$nm"
  removed+=("{\"path\":\"${rel_path}\",\"freed\":\"${size}\"}")
done < <(find "${HOME}/dev" -maxdepth 4 -name "node_modules" -type d \
  ! -path "*/node_modules/*/node_modules" 2>/dev/null | sort)

if [[ ${#removed[@]} -eq 0 ]]; then
  echo '{"removed":[],"note":"no node_modules found"}'
  exit 0
fi

removed_json=$(IFS=,; echo "[${removed[*]}]")

python3 -c "
import json
items = json.loads('${removed_json}')
print(json.dumps({'removed': items, 'count': len(items)}, indent=2))
"
