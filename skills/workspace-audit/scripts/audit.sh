#!/bin/bash
# workspace-audit.sh — audit git repos, secrets exposure, and disk usage

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DEV_ROOT="$HOME/dev"
ISSUES=0
CLEAN=0

echo "===== WORKSPACE AUDIT — $TIMESTAMP ====="
echo

# --- Git repo checks ---
echo "[ GIT REPOS ]"
while IFS= read -r -d '' repo; do
  dir=$(dirname "$repo")
  name=${dir#"$HOME/"}
  cd "$dir" || continue

  flags=""

  # Dirty working tree
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    flags="$flags [DIRTY]"
  fi
  # Untracked files
  if [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]]; then
    flags="$flags [UNTRACKED]"
  fi
  # No remote
  if ! git remote get-url origin &>/dev/null; then
    flags="$flags [NO-REMOTE]"
  else
    git fetch --quiet 2>/dev/null
    ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    if [[ "$ahead" -gt 0 ]]; then
      flags="$flags [AHEAD:$ahead]"
    fi
  fi

  if [[ -n "$flags" ]]; then
    echo "  NEEDS ATTENTION: $name$flags"
    ISSUES=$((ISSUES + 1))
  else
    CLEAN=$((CLEAN + 1))
  fi
done < <(find "$DEV_ROOT" -name ".git" -maxdepth 4 -print0)

echo

# --- Secrets exposure check ---
echo "[ .ENV FILES NOT IN .GITIGNORE ]"
found_env=0
while IFS= read -r -d '' envfile; do
  dir=$(dirname "$envfile")
  gitroot=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$gitroot" ]]; then continue; fi
  rel=${envfile#"$gitroot/"}
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
