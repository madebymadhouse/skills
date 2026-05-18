#!/usr/bin/env bash
# co-author-fix/scripts/fix.sh
# Ensures the last commit has the Claude co-author trailer
set -euo pipefail

REPO_PATH="${REPO_PATH:-$(pwd)}"
TRAILER="Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

if ! git -C "$REPO_PATH" rev-parse HEAD &>/dev/null; then
  python3 -c "import json; print(json.dumps({'error': 'not a git repo or no commits'}))"
  exit 0
fi

LAST_MSG=$(git -C "$REPO_PATH" log -1 --format="%B")
LAST_HASH=$(git -C "$REPO_PATH" log -1 --format="%H")
MSG_PREVIEW=$(echo "$LAST_MSG" | head -1)

if echo "$LAST_MSG" | grep -qF "Co-Authored-By: Claude"; then
  python3 -c "
import json
print(json.dumps({
  'had_trailer': True,
  'amended': False,
  'commit_hash': '${LAST_HASH}'[:8],
  'message_preview': '''${MSG_PREVIEW}'''
}))
"
  exit 0
fi

# Amend: ensure blank line before trailer
# Strip trailing whitespace/newlines from message, then add blank line + trailer
NEW_MSG=$(printf '%s\n\n%s\n' "$(echo "$LAST_MSG" | sed 's/[[:space:]]*$//')" "$TRAILER")

git -C "$REPO_PATH" commit --amend -m "$NEW_MSG" --no-edit 2>/dev/null || \
git -C "$REPO_PATH" commit --amend -m "$NEW_MSG"

NEW_HASH=$(git -C "$REPO_PATH" log -1 --format="%H")

python3 -c "
import json
print(json.dumps({
  'had_trailer': False,
  'amended': True,
  'old_hash': '${LAST_HASH}'[:8],
  'new_hash': '${NEW_HASH}'[:8],
  'message_preview': '''${MSG_PREVIEW}'''
}))
"
