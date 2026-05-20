---
name: rust-release
description: Cut a Rust crate release. Bumps version in Cargo.toml, updates CHANGELOG.md, runs full check suite, creates git tag, and pushes. Triggers on "release urchin", "bump version", "cut a release", "release X crate", "tag rust release", "ship rust version".
allowed-tools: Bash Read Edit
disable_model_invocation: false
triggers:
  - "release urchin"
  - "bump version"
  - "cut a release"
  - "tag rust release"
  - "ship rust version"
  - "new rust version"
  - "release the crate"
  - "publish rust"
---

# Rust Release

Cut a versioned release of a Rust workspace crate.

## Arguments

`$ARGUMENTS` = new version (e.g. `0.3.6`) and optionally the workspace path.

## Steps

### 1. Confirm current version

```bash
bash ~/.claude/commands/rust-release/scripts/bump-version.sh --current
```

### 2. Run pre-release checks

```bash
bash ~/.claude/commands/cargo-check/scripts/check.sh
```

### 3. Bump version

Edit `Cargo.toml` in the workspace root: change `version = "X.Y.Z"` to the new version.
Also update any workspace member `Cargo.toml` files that inherit the version.

```bash
bash ~/.claude/commands/rust-release/scripts/bump-version.sh NEW_VERSION
```

### 4. Update CHANGELOG.md

Add a new `## [NEW_VERSION] - YYYY-MM-DD` section at the top. Summarize commits since last tag:

```bash
git log --oneline $(git describe --tags --abbrev=0)..HEAD
```

Group as: Added, Changed, Fixed, Removed. Be concise.

### 5. Commit, tag, push

```bash
git add Cargo.toml Cargo.lock CHANGELOG.md
git commit -m "chore: release vNEW_VERSION"
git tag vNEW_VERSION
git push origin main --tags
```

## Verify

```bash
git tag | tail -5
cargo metadata --no-deps | python3 -c "import json,sys; m=json.load(sys.stdin); print(m['packages'][0]['version'])"
```
