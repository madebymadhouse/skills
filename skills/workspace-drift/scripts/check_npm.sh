#!/usr/bin/env bash
# check_npm.sh — scan auto-discovered npm projects for outdated packages
# Output: JSON array of { area, name, status, detail }
# status: "current" | "outdated"
set -euo pipefail

RESULTS=()

while IFS= read -r pkg; do
  repo_dir="$(dirname "$pkg")"
  repo_name="${repo_dir#"$HOME/"}"
  outdated=$(npm outdated --prefix "$repo_dir" 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
  if [ "$outdated" -gt 0 ]; then
    RESULTS+=("{\"area\":\"packages\",\"name\":\"${repo_name}\",\"status\":\"outdated\",\"detail\":\"count=${outdated}\"}")
  else
    RESULTS+=("{\"area\":\"packages\",\"name\":\"${repo_name}\",\"status\":\"current\",\"detail\":\"\"}")
  fi
done < <(find ~/dev -maxdepth 3 -name "package.json" \
  ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | head -20)

echo "["
for i in "${!RESULTS[@]}"; do
  comma=","; [ $i -eq $((${#RESULTS[@]}-1)) ] && comma=""
  echo "  ${RESULTS[$i]}${comma}"
done
echo "]"
