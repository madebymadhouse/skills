#!/usr/bin/env bash
# check_git.sh — check all git repos under ~/dev for uncommitted/unpushed changes
# Output: JSON array of { area, name, status, detail }
# status: "clean" | "drift"
set -euo pipefail

RESULTS=()

REPO_ROOTS=()
while IFS= read -r dir; do
  REPO_ROOTS+=("$dir")
done < <(find ~/dev -maxdepth 1 -mindepth 1 -type d ! -name '.*' 2>/dev/null | sort)

for root in "${REPO_ROOTS[@]}"; do
  [ -d "$root" ] || continue
  while IFS= read -r -d '' gitdir; do
    repo_dir="$(dirname "$gitdir")"
    repo_name="${repo_dir#"$HOME/"}"

    dirty=$(git -C "$repo_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    upstream=$(git -C "$repo_dir" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo "")
    ahead=0; behind=0
    if [ -n "$upstream" ]; then
      ahead=$(git -C "$repo_dir" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)
      behind=$(git -C "$repo_dir" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo 0)
    fi

    if [ "$dirty" -gt 0 ] || [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
      RESULTS+=("{\"area\":\"git\",\"name\":\"${repo_name}\",\"status\":\"drift\",\"detail\":\"dirty=${dirty} ahead=${ahead} behind=${behind}\"}")
    else
      RESULTS+=("{\"area\":\"git\",\"name\":\"${repo_name}\",\"status\":\"clean\",\"detail\":\"\"}")
    fi
  done < <(find "$root" -maxdepth 3 -name ".git" -type d -print0 2>/dev/null)
done

echo "["
for i in "${!RESULTS[@]}"; do
  comma=","; [ $i -eq $((${#RESULTS[@]}-1)) ] && comma=""
  echo "  ${RESULTS[$i]}${comma}"
done
echo "]"
