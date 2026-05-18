#!/usr/bin/env bash
# close.sh — pull behind repos, push ahead repos, report dirty/diverged
#
# Outputs a JSON summary to stdout.

set -euo pipefail

GIT_SCAN="${HOME}/.claude/commands/workspace-audit/scripts/git-scan.sh"

if [[ ! -x "$GIT_SCAN" ]]; then
  echo '{"error":"git-scan.sh not found or not executable at '"$GIT_SCAN"'"}' >&2
  exit 1
fi

SCAN_OUTPUT="$("$GIT_SCAN" --fetch 2>/dev/null)"

PULLED=()
PUSHED=()
DIRTY=()
DIVERGED=()
CLEAN=()
PULL_ERRORS=()
PUSH_ERRORS=()

# Parse with python3
while IFS='|' read -r name path dirty ahead behind has_remote; do
  if [[ "$dirty" == "true" ]]; then
    DIRTY+=("$name")
    continue
  fi

  if [[ "$has_remote" != "true" ]]; then
    CLEAN+=("$name")
    continue
  fi

  ahead_n="${ahead:-0}"
  behind_n="${behind:-0}"

  if [[ "$ahead_n" -gt 0 && "$behind_n" -gt 0 ]]; then
    DIVERGED+=("$name")
  elif [[ "$ahead_n" -gt 0 ]]; then
    if git -C "$path" push 2>/dev/null; then
      PUSHED+=("$name")
    else
      PUSH_ERRORS+=("$name")
    fi
  elif [[ "$behind_n" -gt 0 ]]; then
    if git -C "$path" pull --ff-only 2>/dev/null; then
      PULLED+=("$name")
    else
      PULL_ERRORS+=("$name")
    fi
  else
    CLEAN+=("$name")
  fi
done < <(python3 - "$SCAN_OUTPUT" <<'PYEOF'
import sys, json

data = json.loads(sys.argv[1])
for r in data.get("repos", []):
    name = r.get("name", "")
    path = r.get("path", "")
    dirty = str(r.get("dirty", False)).lower()
    ahead = r.get("ahead", 0) or 0
    behind = r.get("behind", 0) or 0
    has_remote = str(r.get("has_remote", False)).lower()
    print(f"{name}|{path}|{dirty}|{ahead}|{behind}|{has_remote}")
PYEOF
)

# Build JSON arrays
to_json_arr() {
  local arr=("$@")
  if [[ ${#arr[@]} -eq 0 ]]; then
    echo "[]"
    return
  fi
  local out="["
  for item in "${arr[@]}"; do
    out+="\"${item}\","
  done
  echo "${out%,}]"
}

cat <<EOF
{
  "pulled": $(to_json_arr "${PULLED[@]+"${PULLED[@]}"}"),
  "pushed": $(to_json_arr "${PUSHED[@]+"${PUSHED[@]}"}"),
  "dirty": $(to_json_arr "${DIRTY[@]+"${DIRTY[@]}"}"),
  "diverged": $(to_json_arr "${DIVERGED[@]+"${DIVERGED[@]}"}"),
  "clean": $(to_json_arr "${CLEAN[@]+"${CLEAN[@]}"}"),
  "pull_errors": $(to_json_arr "${PULL_ERRORS[@]+"${PULL_ERRORS[@]}"}"),
  "push_errors": $(to_json_arr "${PUSH_ERRORS[@]+"${PUSH_ERRORS[@]}"}")
}
EOF
