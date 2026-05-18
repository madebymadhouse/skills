#!/bin/bash
# workspace-audit.sh — audit git repos, secrets exposure, and disk usage

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DEV_ROOT="$HOME/dev"
ISSUES=0
CLEAN=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "===== WORKSPACE AUDIT — $TIMESTAMP ====="
echo

# --- Git repo checks (via shared git-scan.sh) ---
echo "[ GIT REPOS ]"

GIT_JSON=$("$SCRIPT_DIR/git-scan.sh" --fetch --untracked 2>/dev/null)

while IFS= read -r repo_json; do
  name=$(echo "$repo_json" | python3 -c "import sys,json; r=json.loads(sys.stdin.read()); print(r['name'])")
  dirty=$(echo "$repo_json" | python3 -c "import sys,json; r=json.loads(sys.stdin.read()); print(r['dirty'])")
  untracked=$(echo "$repo_json" | python3 -c "import sys,json; r=json.loads(sys.stdin.read()); print(r['untracked'])")
  ahead=$(echo "$repo_json" | python3 -c "import sys,json; r=json.loads(sys.stdin.read()); print(r['ahead'])")
  has_remote=$(echo "$repo_json" | python3 -c "import sys,json; r=json.loads(sys.stdin.read()); print(r['has_remote'])")

  flags=""
  [[ "$dirty" -gt 0 ]]     && flags="$flags [DIRTY]"
  [[ "$untracked" -gt 0 ]] && flags="$flags [UNTRACKED]"
  [[ "$has_remote" == "False" ]] && flags="$flags [NO-REMOTE]"
  [[ "$ahead" -gt 0 ]]     && flags="$flags [AHEAD:$ahead]"

  if [[ -n "$flags" ]]; then
    echo "  NEEDS ATTENTION: $name$flags"
    ISSUES=$((ISSUES + 1))
  else
    CLEAN=$((CLEAN + 1))
  fi
done < <(echo "$GIT_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data['repos']:
    print(json.dumps(r))
")

echo

# --- Secrets exposure check ---
echo "[ .ENV FILES NOT IN .GITIGNORE ]"
found_env=0
while IFS= read -r -d '' envfile; do
  dir=$(dirname "$envfile")
  gitroot=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$gitroot" ]]; then continue; fi
  if ! git -C "$gitroot" check-ignore -q "$envfile" 2>/dev/null; then
    echo "  EXPOSED: $envfile"
    ISSUES=$((ISSUES + 1))
    found_env=1
  fi
done < <(find "$DEV_ROOT" -name ".env" -not -path "*/.git/*" -print0)
[[ $found_env -eq 0 ]] && echo "  OK — no exposed .env files"

echo

# --- Context file tracking check ---
echo "[ CONTEXT FILES TRACKED IN GIT ]"
found_ctx=0
for fname in CLAUDE.md AGENTS.md GEMINI.md; do
  while IFS= read -r -d '' repo; do
    dir=$(dirname "$repo")
    cd "$dir" || continue
    if git ls-files --error-unmatch "$fname" &>/dev/null; then
      echo "  TRACKED: $dir/$fname"
      ISSUES=$((ISSUES + 1))
      found_ctx=1
    fi
  done < <(find "$DEV_ROOT" -name ".git" -maxdepth 4 -print0)
done
[[ $found_ctx -eq 0 ]] && echo "  OK — no context files tracked"

echo

# --- Disk usage ---
echo "[ DISK USAGE ]"
du -sh "$DEV_ROOT" 2>/dev/null | awk '{print "  ~/dev/ total: " $1}'

echo

# --- Summary ---
echo "===== SUMMARY ====="
echo "  Clean repos    : $CLEAN"
echo "  Repos with issues: $ISSUES"
if [[ $ISSUES -gt 0 ]]; then
  echo "  STATUS: NEEDS ATTENTION"
  exit 1
else
  echo "  STATUS: CLEAN"
  exit 0
fi
