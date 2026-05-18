#!/usr/bin/env bash
# workspace-flatten/scripts/flatten.sh
# Moves one nested repo to its flat target location.
#
# Required env vars:
#   REPO_PATH    — current absolute path to the repo
#   TARGET_PATH  — where it should land (must not exist)
#
# Optional:
#   DRY_RUN=true — print what would happen, touch nothing
#
# Safety rules:
#   - Exits if working tree is dirty (uncommitted changes)
#   - Exits if repo has no remote (internal-only repos stay put)
#   - Pushes unpushed commits before cloning
#   - Verifies cloned remote matches source before removing old path
#   - Never removes old path if clone remote differs

set -euo pipefail

REPO_PATH="${REPO_PATH:-}"
TARGET_PATH="${TARGET_PATH:-}"
DRY_RUN="${DRY_RUN:-false}"

if [[ -z "$REPO_PATH" || -z "$TARGET_PATH" ]]; then
  echo '{"moved":false,"error":"REPO_PATH and TARGET_PATH are required"}'
  exit 1
fi

REPO_PATH="${REPO_PATH/#\~/$HOME}"
TARGET_PATH="${TARGET_PATH/#\~/$HOME}"

if [[ ! -d "$REPO_PATH/.git" ]]; then
  echo "{\"moved\":false,\"error\":\"not a git repo: $REPO_PATH\"}"
  exit 1
fi

dirty=$(git -C "$REPO_PATH" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [[ "$dirty" -gt 0 ]]; then
  echo "{\"moved\":false,\"error\":\"dirty working tree — commit or stash first\",\"dirty\":$dirty}"
  exit 1
fi

remote_url=$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null || echo "")
if [[ -z "$remote_url" ]]; then
  echo '{"moved":false,"error":"no remote — internal-only repos stay in place"}'
  exit 1
fi

unpushed=0
upstream=$(git -C "$REPO_PATH" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo "")
if [[ -n "$upstream" ]]; then
  unpushed=$(git -C "$REPO_PATH" rev-list --count "$upstream..HEAD" 2>/dev/null || echo 0)
fi

if $DRY_RUN; then
  echo "{\"moved\":false,\"dry_run\":true,\"would_push\":$unpushed,\"from\":\"$REPO_PATH\",\"to\":\"$TARGET_PATH\",\"remote\":\"$remote_url\"}"
  exit 0
fi

if [[ -d "$TARGET_PATH" ]]; then
  echo "{\"moved\":false,\"error\":\"target already exists: $TARGET_PATH\"}"
  exit 1
fi

pushed=0
if [[ "$unpushed" -gt 0 ]]; then
  git -C "$REPO_PATH" push >&2
  pushed=$unpushed
fi

git clone "$remote_url" "$TARGET_PATH" 2>/dev/null

cloned_remote=$(git -C "$TARGET_PATH" remote get-url origin 2>/dev/null || echo "")
if [[ "$cloned_remote" != "$remote_url" ]]; then
  rm -rf "$TARGET_PATH"
  echo "{\"moved\":false,\"error\":\"remote mismatch after clone — aborted\",\"expected\":\"$remote_url\",\"got\":\"$cloned_remote\"}"
  exit 1
fi

rm -rf "$REPO_PATH"

python3 -c "
import json
print(json.dumps({
  'moved': True,
  'pushed': $pushed,
  'target': '$TARGET_PATH',
  'removed_old': True,
  'remote': '$remote_url'
}))
"
