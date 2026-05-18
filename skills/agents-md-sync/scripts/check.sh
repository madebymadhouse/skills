#!/usr/bin/env bash
# agents-md-sync/scripts/check.sh
# Checks an AGENTS.md for stale path references
set -euo pipefail

TARGET_DIR="${TARGET_DIR:-$HOME}"
AGENTS_FILE="${TARGET_DIR}/AGENTS.md"

if [[ ! -f "$AGENTS_FILE" ]]; then
  python3 -c "import json; print(json.dumps({'error': 'no AGENTS.md at ${AGENTS_FILE}'}))"
  exit 0
fi

python3 - "$AGENTS_FILE" <<'PYEOF'
import json, re, os, sys
from pathlib import Path

agents_file = sys.argv[1]
home = os.path.expanduser("~")

with open(agents_file) as f:
    content = f.read()

# Extract all path-like references: ~/dev/... or absolute paths
path_pattern = re.compile(r'`(~/[^`\s]+)`|`(/[^`\s]+)`')
paths_found = []
for m in path_pattern.finditer(content):
    raw = m.group(1) or m.group(2)
    # Skip paths with globs or shell vars
    if any(c in raw for c in ['*', '$', '{', '}']):
        continue
    expanded = raw.replace('~', home)
    paths_found.append({'raw': raw, 'expanded': expanded})

# Deduplicate
seen = set()
unique_paths = []
for p in paths_found:
    if p['expanded'] not in seen:
        seen.add(p['expanded'])
        unique_paths.append(p)

valid = []
stale = []

for p in unique_paths:
    exists = os.path.exists(p['expanded'])
    entry = {'path': p['raw'], 'expanded': p['expanded'], 'exists': exists}
    if exists:
        valid.append(entry)
    else:
        stale.append(entry)

# Check: which repos under ~/dev/mad-house are not mentioned in any AGENTS.md
mad_house = Path(home) / 'dev' / 'mad-house'
untracked = []
if mad_house.exists():
    for child in sorted(mad_house.iterdir()):
        if child.is_dir() and (child / '.git').exists():
            ref = f'~/dev/mad-house/{child.name}'
            if ref not in content:
                untracked.append({'path': ref, 'note': 'local repo not mentioned in AGENTS.md'})

print(json.dumps({
    'file': agents_file,
    'checked': len(unique_paths),
    'valid_count': len(valid),
    'stale_count': len(stale),
    'stale': stale,
    'untracked': untracked
}, indent=2))
PYEOF
