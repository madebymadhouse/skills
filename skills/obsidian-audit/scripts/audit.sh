#!/usr/bin/env bash
set -euo pipefail

CANONICAL_VAULT="${VAULT_PATH:-$HOME/vault}"

resolve_live_vault() {
  if [[ -n "${OBSIDIAN_LIVE_VAULT_PATH:-}" && -d "${OBSIDIAN_LIVE_VAULT_PATH}" ]]; then
    printf '%s\n' "${OBSIDIAN_LIVE_VAULT_PATH}"
    return 0
  fi

  local candidate
  while IFS= read -r candidate; do
    if [[ -d "$candidate/.obsidian" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(find /mnt/c/Users -maxdepth 3 -type d -path '*/Documents/vault' 2>/dev/null | sort)

  return 1
}

LIVE_VAULT="$(resolve_live_vault || true)"

python3 - <<'PY' "$CANONICAL_VAULT" "${LIVE_VAULT:-}"
import json
import subprocess
import sys
from pathlib import Path

canonical = Path(sys.argv[1]).expanduser()
live = Path(sys.argv[2]).expanduser() if len(sys.argv) > 2 and sys.argv[2] else None

def read_json(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text())
    except Exception as exc:
        return {"__error__": str(exc)}

def git_summary(path: Path):
    if not path or not path.exists():
        return "missing"
    if not (path / ".git").exists():
        return "not-a-repo"
    status = subprocess.run(
        ["git", "-C", str(path), "status", "--porcelain"],
        capture_output=True,
        text=True,
        check=False,
    )
    dirty = len([line for line in status.stdout.splitlines() if line.strip()])
    branch = subprocess.run(
        ["git", "-C", str(path), "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True,
        text=True,
        check=False,
    ).stdout.strip() or "unknown"
    ahead_behind = subprocess.run(
        ["git", "-C", str(path), "rev-list", "--left-right", "--count", "@{upstream}...HEAD"],
        capture_output=True,
        text=True,
        check=False,
    )
    if ahead_behind.returncode == 0:
        behind, ahead = ahead_behind.stdout.strip().split()
        divergence = f"ahead={ahead} behind={behind}"
    else:
        divergence = "no-upstream"
    return f"branch={branch} dirty={dirty} {divergence}"

def cmp_state(rel: str):
    a = canonical / rel
    b = live / rel if live else None
    if not a.exists():
        return f"{rel}: missing-canonical"
    if not b or not b.exists():
        return f"{rel}: missing-live"
    return f"{rel}: {'match' if a.read_bytes() == b.read_bytes() else 'diff'}"

vault_for_obsidian = live if live else canonical
community = read_json(vault_for_obsidian / ".obsidian/community-plugins.json") or []
core = read_json(vault_for_obsidian / ".obsidian/core-plugins.json") or {}
graph = read_json(vault_for_obsidian / ".obsidian/graph.json") or {}
extended = read_json(vault_for_obsidian / ".obsidian/plugins/extended-graph/data.json") or {}

print("===== OBSIDIAN AUDIT =====")
print()
print("[ PATHS ]")
print(f"canonical={canonical}")
print(f"live={live if live else 'not-found'}")
print()
print("[ GIT ]")
print(f"canonical={git_summary(canonical)}")
print(f"live={git_summary(live) if live else 'not-found'}")
print()
print("[ COMMUNITY PLUGINS ]")
print(f"count={len(community)}")
for plugin in community:
    print(f"- {plugin}")
print()
print("[ CORE PLUGINS ]")
enabled_core = [name for name, enabled in core.items() if enabled]
print(f"count={len(enabled_core)}")
for plugin in enabled_core:
    print(f"- {plugin}")
print()
print("[ GRAPH ]")
graph_keys = [
    "showAttachments",
    "showOrphans",
    "nodeSizeMultiplier",
    "lineSizeMultiplier",
    "centerStrength",
    "repelStrength",
    "linkStrength",
    "linkDistance",
    "scale",
]
for key in graph_keys:
    print(f"{key}={graph.get(key)}")
print()
print("[ EXTENDED GRAPH ]")
graph_features = (((extended.get("enableFeatures") or {}).get("graph")) or {})
for key in [
    "tags",
    "properties",
    "imagesForAttachments",
    "folders",
    "links",
    "names",
    "icons",
    "arrows",
    "layers",
]:
    print(f"{key}={graph_features.get(key)}")
print()
print("[ DRIFT ]")
for rel in [
    ".obsidian/graph.json",
    ".obsidian/plugins/extended-graph/data.json",
    ".obsidian/plugins/manual-sorting/data.json",
    ".obsidian/plugins/obsidian-git/data.json",
    ".obsidian/community-plugins.json",
]:
    print(cmp_state(rel))
print()
print("[ DASHBOARDS ]")
dashboard_root = vault_for_obsidian / "dashboards"
dashboards = sorted(dashboard_root.glob("*.md")) if dashboard_root.exists() else []
for path in dashboards:
    print(f"- {path.name}")
PY
