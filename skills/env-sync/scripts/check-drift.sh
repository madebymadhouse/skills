#!/usr/bin/env bash
# Check for drift between hardcoded lists in skill scripts and actual current environment.
# Compares what the scripts know about vs what actually exists. No AI. Output is labeled sections.

set -uo pipefail

SSH_TARGET="${VPS_SSH_TARGET:-vps}"
COMMANDS_DIR="$HOME/.claude/commands"
WSL_SCRIPT="$COMMANDS_DIR/wsl-audit/scripts/collect-wsl.sh"
VPS_SCRIPT="$COMMANDS_DIR/vps-audit/scripts/collect-vps.sh"

echo "=== AI_CLIENT_DRIFT ==="
# Compare hardcoded AI client list in collect-wsl.sh vs actual ~/.* dirs that look like AI tools

# Extract what's hardcoded in the script
echo "--- hardcoded in collect-wsl.sh ---"
grep -A 10 'for d in .agents' "$WSL_SCRIPT" 2>/dev/null \
  | grep -o '\.[a-z][a-zA-Z0-9_-]*' | sort

echo "--- actual AI-looking dirs in home ---"
find ~/ -maxdepth 1 -type d -name '.*' 2>/dev/null \
  | xargs -I{} basename {} \
  | grep -iE 'agent|ai|llm|gpt|claude|copilot|gemini|codex|openai|anthropic|ollama|qwen|corust|aitk|antigravity|junie|opencode|codewhisperer|cody|cursor|continue|zed' \
  | sort

echo ""

echo "=== DEV_ORG_DRIFT ==="
# Top-level org dirs in ~/dev — compare against what wsl-audit SKILL.md synthesis knows about
echo "--- actual orgs in ~/dev ---"
find ~/dev -maxdepth 1 -mindepth 1 -type d | xargs -I{} basename {} | sort

echo "--- orgs mentioned in wsl-audit SKILL.md ---"
grep -oE '\*\*[^/*]+/\*\*' "$COMMANDS_DIR/wsl-audit/SKILL.md" 2>/dev/null \
  | grep -oE '[^*]+/' \
  | sed 's|/||' \
  | sort -u || echo "(could not extract)"

echo ""

echo "=== VPS_CONTAINER_DRIFT ==="
# Check if VPS has containers not grouped in vps-audit synthesis instructions
echo "--- containers VPS currently runs (short names) ---"
ssh -q "$SSH_TARGET" "docker ps --format '{{.Names}}' 2>/dev/null | sed 's/-[a-z0-9]\{24\}\(-[0-9]\{12\}\)\{0,1\}//g'" 2>/dev/null | sort || echo "(ssh failed or docker not available)"

echo "--- project groups mentioned in vps-audit SKILL.md ---"
grep -oE '\*\*[^*]+\*\*' "$COMMANDS_DIR/vps-audit/SKILL.md" 2>/dev/null \
  | grep -v '^\*\*$' \
  | sort -u || echo "(could not extract)"

echo ""

echo "=== SCRIPT_PATH_DRIFT ==="
# Check that all script paths referenced in SKILL.md files actually exist
find "$COMMANDS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort | while read -r skill_md; do
  skill=$(basename "$(dirname "$skill_md")")
  # Extract paths that look like script references (absolute paths ending in .sh or .py)
  grep -oE '~/.claude/commands/[^"` )]+\.(sh|py)' "$skill_md" 2>/dev/null | while read -r ref_path; do
    expanded="${ref_path/\~/$HOME}"
    if [ ! -f "$expanded" ]; then
      echo "BROKEN: $skill → $ref_path (does not exist)"
    else
      echo "OK: $skill → $ref_path"
    fi
  done
done
echo ""

echo "=== NEW_PROJECTS_NOT_IN_PROJECT_LANGS ==="
# Projects found by find that would NOT be detected by collect-wsl.sh PROJECT_LANGS
# (i.e., dirs in ~/dev at depth 2-3 with no recognized sentinel file)
while IFS= read -r proj; do
  [ -d "$proj" ] || continue
  has_sentinel=false
  for f in Cargo.toml package.json pnpm-workspace.yaml pyproject.toml requirements.txt go.mod wrangler.toml docker-compose.yml docker-compose.yaml next.config.ts next.config.js; do
    [ -f "$proj/$f" ] && has_sentinel=true && break
  done
  $has_sentinel || echo "NO_SENTINEL: ${proj#"$HOME/"}"
done < <(find ~/dev -mindepth 2 -maxdepth 3 -type d \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/.next/*" \
  ! -name ".next" \
  | sort)
echo "(end)"

echo ""
echo "=== OLLAMA_MODELS_DRIFT ==="
echo "--- currently installed ---"
ollama list 2>/dev/null || echo "(ollama not running)"
echo ""

echo "=== RUNTIME_VERSIONS ==="
echo "node: $(node --version 2>/dev/null || echo not found)"
echo "npm: $(npm --version 2>/dev/null || echo not found)"
echo "rust: $(rustc --version 2>/dev/null || echo not found)"
echo "python: $(python3 --version 2>/dev/null || echo not found)"
echo "ollama: $(ollama --version 2>/dev/null || echo not found)"
