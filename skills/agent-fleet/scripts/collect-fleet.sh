#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${HOME}/dev/mad-house/skills/agents"
DEV_DIR="${HOME}/dev"

echo "=== REGISTRY ==="
if [[ ! -d "$REGISTRY" ]]; then
  echo "NO_REGISTRY: ${REGISTRY} does not exist"
else
  find "${REGISTRY}" -name "*.agent.md" -type f | sort | while read -r agent_file; do
    agent_name=$(basename "$agent_file" .agent.md)
    description=$(grep -m1 '^description:' "$agent_file" 2>/dev/null | sed 's/^description: *//' || echo "(no description)")
    echo "AGENT: ${agent_name} | ${description}"
  done

  count=$(find "${REGISTRY}" -name "*.agent.md" -type f | wc -l)
  echo "REGISTRY_COUNT: ${count}"
fi

echo ""
echo "=== REPOS ==="

# Find all repos under ~/dev that look like mad-house projects (have .git and .github)
find "${DEV_DIR}" -maxdepth 3 -name ".git" -type d | sort | while read -r git_dir; do
  repo_dir=$(dirname "$git_dir")
  repo_name=$(basename "$repo_dir")
  agents_dir="${repo_dir}/.github/agents"

  if [[ ! -d "${repo_dir}/.github" ]]; then
    continue
  fi

  echo "REPO: ${repo_name} | ${repo_dir}"

  if [[ -d "$agents_dir" ]]; then
    agent_files=$(find "$agents_dir" -name "*.agent.md" -type f | sort)
    if [[ -z "$agent_files" ]]; then
      echo "  AGENTS: none"
    else
      echo "$agent_files" | while read -r agent_file; do
        agent_name=$(basename "$agent_file" .agent.md)
        echo "  DEPLOYED: ${agent_name}"
      done
    fi
  else
    echo "  AGENTS: no .github/agents dir"
  fi
done
