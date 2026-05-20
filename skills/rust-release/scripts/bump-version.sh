#!/usr/bin/env bash
# Show current version or validate a proposed version string.
set -uo pipefail

WORKSPACE="${CARGO_WORKSPACE:-$(pwd)}"

if [ ! -f "$WORKSPACE/Cargo.toml" ]; then
  echo "ERROR: no Cargo.toml in $WORKSPACE"
  exit 1
fi

current=$(grep -m1 '^version\s*=' "$WORKSPACE/Cargo.toml" | sed 's/.*"\(.*\)"/\1/')

if [[ "${1:-}" == "--current" ]]; then
  echo "current: $current"
  exit 0
fi

NEW="${1:-}"
if [[ -z "$NEW" ]]; then
  echo "Usage: $0 NEW_VERSION | --current"
  echo "current: $current"
  exit 1
fi

if ! echo "$NEW" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "ERROR: version must be X.Y.Z, got: $NEW"
  exit 1
fi

echo "  $current -> $NEW"
echo "Next: edit Cargo.toml manually or with sed, update CHANGELOG.md, then commit + tag."
