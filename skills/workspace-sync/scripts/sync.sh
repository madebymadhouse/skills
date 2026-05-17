#!/bin/bash
# workspace-sync.sh — fetch and fast-forward pull all clean git repos

DEV_ROOT="$HOME/dev"
PULLED=0
SKIPPED_DIRTY=0
SKIPPED_NO_REMOTE=0
UP_TO_DATE=0

echo "===== WORKSPACE SYNC — $(date '+%Y-%m-%d %H:%M:%S') ====="
echo

while IFS= read -r -d '' repo; do
  dir=$(dirname "$repo")
  name=${dir#"$HOME/"}
  cd "$dir" || continue

  if ! git remote get-url origin &>/dev/null; then
    echo "  SKIP (no remote): $name"
    SKIPPED_NO_REMOTE=$((SKIPPED_NO_REMOTE + 1))
    continue
  fi

  git fetch --quiet 2>/dev/null

  behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
  if [[ "$behind" -eq 0 ]]; then
    UP_TO_DATE=$((UP_TO_DATE + 1))
    continue
  fi

  # Check for uncommitted changes
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo "  SKIP (dirty, behind $behind): $name"
    SKIPPED_DIRTY=$((SKIPPED_DIRTY + 1))
    continue
  fi

  # Fast-forward only
  if git merge --ff-only @{u} --quiet 2>/dev/null; then
    echo "  PULLED (ff, $behind commits): $name"
    PULLED=$((PULLED + 1))
  else
    echo "  SKIP (ff not possible): $name"
    SKIPPED_DIRTY=$((SKIPPED_DIRTY + 1))
  fi
done < <(find "$DEV_ROOT" -name ".git" -maxdepth 4 -print0)

echo
echo "===== SUMMARY ====="
echo "  Pulled         : $PULLED"
echo "  Up to date     : $UP_TO_DATE"
echo "  Skipped (dirty): $SKIPPED_DIRTY"
echo "  Skipped (no remote): $SKIPPED_NO_REMOTE"
