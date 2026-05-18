#!/usr/bin/env bash
# workspace-flatten/scripts/scan.sh
# Finds repos nested in parent dirs that should be at the flat level
set -euo pipefail

MAD_HOUSE="${HOME}/dev/mad-house"
PARENT_DIRS=("lab" "core" "prod" "tooling")

python3 - <<PYEOF
import subprocess, json, os
from pathlib import Path

base = Path("${MAD_HOUSE}")
parent_dirs = [d for d in ["lab", "core", "prod", "tooling"] if (base / d).is_dir()]
nested = []

for parent in parent_dirs:
    parent_path = base / parent
    for child in sorted(parent_path.iterdir()):
        if not child.is_dir():
            continue
        git_dir = child / ".git"
        if not git_dir.exists():
            continue

        # Get remote
        remote = subprocess.run(
            ["git", "-C", str(child), "remote", "get-url", "origin"],
            capture_output=True, text=True
        ).stdout.strip()

        # Get unpushed count
        ahead_out = subprocess.run(
            ["git", "-C", str(child), "rev-list", "@{u}..", "--count"],
            capture_output=True, text=True
        ).stdout.strip()
        ahead = int(ahead_out) if ahead_out.isdigit() else 0

        # Dirty check
        dirty_out = subprocess.run(
            ["git", "-C", str(child), "status", "--porcelain"],
            capture_output=True, text=True
        ).stdout.strip()

        # Determine target
        name = child.name
        target = str(base / name)
        target_exists = (base / name).exists()

        nested.append({
            "name": name,
            "current_path": str(child),
            "target_path": target,
            "target_exists": target_exists,
            "git_remote": remote,
            "unpushed_count": ahead,
            "dirty": bool(dirty_out)
        })

print(json.dumps({"nested": nested}, indent=2))
PYEOF
