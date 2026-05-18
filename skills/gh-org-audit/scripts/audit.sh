#!/usr/bin/env bash
# gh-org-audit/scripts/audit.sh
# Audits GitHub orgs for health: stale repos, missing standard files, local archived clones
#
# Configuration via env vars:
#   AUDIT_ORGS  — space-separated list of "orgname:local_path" pairs
#                 e.g. "myorg:~/dev/projects anotherog:~/dev/other"
#   STALE_DAYS  — days since last push to consider stale (default: 90)
#
# Example:
#   AUDIT_ORGS="myorg:~/dev/projects" bash audit.sh
set -euo pipefail

STALE_DAYS="${STALE_DAYS:-90}"
AUDIT_ORGS="${AUDIT_ORGS:-}"

if [[ -z "$AUDIT_ORGS" ]]; then
  echo '{"error":"AUDIT_ORGS is required. Format: \"orgname:~/local/path orgname2:~/local/path2\""}' >&1
  exit 1
fi

# Fetch repos for each org into temp files
declare -a ORG_NAMES=()
declare -a ORG_PATHS=()
declare -a TMP_FILES=()

for pair in $AUDIT_ORGS; do
  org="${pair%%:*}"
  local_path="${pair##*:}"
  local_path="${local_path/#\~/$HOME}"
  tmp=$(mktemp)
  ORG_NAMES+=("$org")
  ORG_PATHS+=("$local_path")
  TMP_FILES+=("$tmp")
  gh repo list "$org" --json name,isArchived,pushedAt,description \
    --limit 100 2>/dev/null > "$tmp" || echo "[]" > "$tmp"
done

cleanup() { for f in "${TMP_FILES[@]}"; do rm -f "$f"; done; }
trap cleanup EXIT

export STALE_DAYS HOME
export ORG_NAMES_JSON
export ORG_PATHS_JSON
export TMP_FILES_JSON

ORG_NAMES_JSON=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${ORG_NAMES[@]}")
ORG_PATHS_JSON=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${ORG_PATHS[@]}")
TMP_FILES_JSON=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${TMP_FILES[@]}")

python3 <<'PYEOF'
import json, os
from pathlib import Path
from datetime import datetime, timezone

stale_days = int(os.environ.get("STALE_DAYS", 90))
home = Path(os.environ["HOME"])
now = datetime.now(timezone.utc)

org_names = json.loads(os.environ["ORG_NAMES_JSON"])
org_paths = json.loads(os.environ["ORG_PATHS_JSON"])
tmp_files = json.loads(os.environ["TMP_FILES_JSON"])

standard_files = ["README.md", ".gitignore"]
results = {}
totals = {"live": 0, "archived": 0, "stale": 0}

for org, local_root_str, tmp_file in zip(org_names, org_paths, tmp_files):
    local_root = Path(local_root_str)

    with open(tmp_file) as f:
        repos = json.load(f)

    stale = []
    missing_files = []
    local_archived_clones = []

    for repo in repos:
        name = repo["name"]
        is_archived = repo.get("isArchived", False)
        pushed = repo.get("pushedAt", "")

        if is_archived:
            totals["archived"] += 1
            for search_root in [local_root, local_root / name]:
                if search_root.exists() and (search_root / ".git").exists():
                    local_archived_clones.append({
                        "name": name,
                        "local_path": str(search_root)
                    })
                    break
        else:
            totals["live"] += 1
            if pushed:
                try:
                    pushed_dt = datetime.fromisoformat(pushed.replace("Z", "+00:00"))
                    age_days = (now - pushed_dt).days
                    if age_days > stale_days:
                        stale.append({
                            "name": name,
                            "last_push": pushed[:10],
                            "days_ago": age_days
                        })
                        totals["stale"] += 1
                except ValueError:
                    pass

            local_path = local_root / name
            if local_path.exists():
                missing = [f for f in standard_files if not (local_path / f).exists()]
                if missing:
                    missing_files.append({"name": name, "missing": missing})

    results[org] = {
        "stale": sorted(stale, key=lambda x: x["days_ago"], reverse=True),
        "missing_standard_files": missing_files,
        "local_archived_clones": local_archived_clones
    }

print(json.dumps({
    "stale_threshold_days": stale_days,
    "orgs": results,
    "summary": totals
}, indent=2))
PYEOF
