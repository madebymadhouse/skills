#!/usr/bin/env bash
# git-scan.sh — shared git repo scanner used by workspace-audit, workspace-drift, workspace-sync
#
# Scans all git repos under $DEV_ROOT and outputs JSON.
#
# Options:
#   --fetch     git fetch each repo before checking ahead/behind (slower, accurate)
#   --untracked include untracked file count
#
# Output (stdout):
# {
#   "timestamp": "...",
#   "dev_root": "...",
#   "repos": [
#     {
#       "name": "dev/mad-house/skills",
#       "path": "/home/samhc/dev/mad-house/skills",
#       "dirty": 0,
#       "untracked": 2,
#       "ahead": 0,
#       "behind": 0,
#       "has_remote": true
#     }
#   ]
# }

set -uo pipefail

DEV_ROOT="${DEV_ROOT:-$HOME/dev}"
DO_FETCH=false
DO_UNTRACKED=false

for arg in "$@"; do
  case $arg in
    --fetch)     DO_FETCH=true ;;
    --untracked) DO_UNTRACKED=true ;;
  esac
done

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
REPO_JSONS=()

while IFS= read -r -d '' gitdir; do
  repo_dir="$(dirname "$gitdir")"
  repo_name="${repo_dir#"$HOME/"}"

  has_remote=false
  if git -C "$repo_dir" remote get-url origin &>/dev/null 2>&1; then
    has_remote=true
    $DO_FETCH && git -C "$repo_dir" fetch --quiet 2>/dev/null || true
  fi

  dirty=$(git -C "$repo_dir" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  staged=$(git -C "$repo_dir" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  dirty=$(( dirty + staged ))

  untracked=0
  if $DO_UNTRACKED; then
    untracked=$(git -C "$repo_dir" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  fi

  ahead=0
  behind=0
  if $has_remote; then
    upstream=$(git -C "$repo_dir" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo "")
    if [[ -n "$upstream" ]]; then
      ahead=$(git -C "$repo_dir" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)
      behind=$(git -C "$repo_dir" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo 0)
    fi
  fi

  has_remote_str="false"; $has_remote && has_remote_str="true"
  REPO_JSONS+=("{\"name\":\"$repo_name\",\"path\":\"$repo_dir\",\"dirty\":$dirty,\"untracked\":$untracked,\"ahead\":$ahead,\"behind\":$behind,\"has_remote\":$has_remote_str}")
done < <(find "$DEV_ROOT" -name ".git" -maxdepth 4 -type d -print0 2>/dev/null)

echo "{"
echo "  \"timestamp\": \"$TIMESTAMP\","
echo "  \"dev_root\": \"$DEV_ROOT\","
echo "  \"repos\": ["
for i in "${!REPO_JSONS[@]}"; do
  comma=","; [[ $i -eq $(( ${#REPO_JSONS[@]} - 1 )) ]] && comma=""
  echo "    ${REPO_JSONS[$i]}$comma"
done
echo "  ]"
echo "}"
