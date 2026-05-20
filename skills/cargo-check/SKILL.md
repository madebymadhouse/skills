---
name: cargo-check
description: Run cargo fmt, clippy, and tests on a Rust workspace before committing. Catches format failures that break CI. Triggers on "cargo check", "check rust", "run rust tests", "before I commit rust", "fmt and test", "check the workspace", "is the rust build clean".
allowed-tools: Bash
disable_model_invocation: true
triggers:
  - "cargo check"
  - "check rust"
  - "run rust tests"
  - "fmt and test"
  - "check the workspace"
  - "is the rust build clean"
  - "rust is it clean"
  - "before committing rust"
  - "run cargo fmt"
---

# Cargo Check

Run the full pre-commit Rust check suite: format, lint, test.

## Run

```bash
bash ~/.claude/commands/cargo-check/scripts/check.sh
```

## What it does

1. `cargo fmt --check` — if this fails, run `cargo fmt` then re-check
2. `cargo clippy -- -D warnings` — zero warnings policy
3. `cargo test --workspace` — all tests must pass

## Auto-fix format issues

```bash
bash ~/.claude/commands/cargo-check/scripts/check.sh --fix
```

With `--fix`, runs `cargo fmt` first, then proceeds with clippy and tests.

## One-liner (no script)

```bash
cd WORKSPACE && cargo fmt && cargo clippy -- -D warnings && cargo test --workspace
```
