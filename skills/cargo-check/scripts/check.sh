#!/usr/bin/env bash
# Pre-commit Rust check: fmt, clippy, test.
set -uo pipefail

FIX=false
for arg in "$@"; do
  case $arg in --fix) FIX=true ;; esac
done

WORKSPACE="${CARGO_WORKSPACE:-$(pwd)}"

if [ ! -f "$WORKSPACE/Cargo.toml" ]; then
  echo "ERROR: no Cargo.toml in $WORKSPACE"
  echo "Run from a Rust workspace root or set CARGO_WORKSPACE"
  exit 1
fi

cd "$WORKSPACE"

echo "=== Format ==="
if $FIX; then
  cargo fmt
  echo "  formatted"
else
  cargo fmt --check && echo "  ok" || {
    echo "  FAIL: run 'cargo fmt' to fix, or pass --fix"
    exit 1
  }
fi

echo "=== Clippy ==="
cargo clippy -- -D warnings && echo "  ok"

echo "=== Tests ==="
cargo test --workspace && echo "  ok"

echo ""
echo "All checks passed. Safe to commit."
