#!/usr/bin/env bash
# Deterministic WSL data collection. No AI. Called by wsl-audit and ops-audit.
# Outputs labeled sections so the AI only needs to synthesize, not gather.

set -uo pipefail

echo "=== SYSTEM ==="
uname -a
grep -E 'PRETTY_NAME|VERSION_ID' /etc/os-release
echo "hostname: $(hostname)"
echo "user: $(whoami)  groups: $(id)"
uptime

echo ""
echo "=== RESOURCES ==="
df -h /
free -h
echo "cpus: $(nproc)"

echo ""
echo "=== BASHRC_ENV_VAR_NAMES ==="
# Names only — never print values
grep '^export ' ~/.bashrc 2>/dev/null \
  | sed 's/^export //' \
  | cut -d'=' -f1 \
  | sort \
  || echo "(none)"

echo ""
echo "=== BASHRC_AUTOSTARTS ==="
# Lines that launch background processes
grep -n 'nohup\|disown\|& $\|&$\|ollama serve\|git.*pull\|auto-start' ~/.bashrc 2>/dev/null \
  || echo "(none)"

echo ""
echo "=== SSH ==="
ls ~/.ssh/ 2>/dev/null
echo "--- config ---"
cat ~/.ssh/config 2>/dev/null || echo "(no config)"

echo ""
echo "=== RUNTIMES ==="
node  --version 2>/dev/null || echo "node: not found"
echo  "npm:    $(npm --version 2>/dev/null || echo not found)"
echo  "nvm versions: $(ls ~/.nvm/versions/node/ 2>/dev/null | tr '\n' ' ' || echo none)"
rustc --version 2>/dev/null || echo "rust: not found"
python3 --version 2>/dev/null || echo "python3: not found"
go    version 2>/dev/null || echo "go: not found"
bun   --version 2>/dev/null || echo "bun: not found"
ollama --version 2>/dev/null || echo "ollama: not found"

echo ""
echo "=== OLLAMA_MODELS ==="
ollama list 2>/dev/null || echo "(not running or not installed)"

echo ""
echo "=== AI_CLIENTS ==="
# Check for known AI client directories — add new ones here as you install them
for d in .agents .aitk .antigravity-server .codex .copilot .corust-agent .junie \
          .ollama .opencode .qwen .gemini; do
  [ -d ~/"$d" ] && echo "$d"
done
ls ~/GEMINI.md ~/AGENTS.md 2>/dev/null | xargs -I{} basename {} 2>/dev/null || true

echo ""
echo "=== DOCKER ==="
if command -v docker &>/dev/null; then
  docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null \
    || echo "(docker daemon not running)"
else
  echo "docker: not installed"
fi

echo ""
echo "=== DEV_TREE ==="
find ~/dev -maxdepth 3 -type d 2>/dev/null | sort

echo ""
echo "=== PROJECT_LANGS ==="
# Detect language/runtime per project from sentinel files — no AI needed.
# Uses find at depth 2-3 to catch nested org layouts (org/project or org/group/project).
# Only emits dirs that have at least one recognized sentinel file.
while IFS= read -r proj; do
  [ -d "$proj" ] || continue
  tags=""
  [ -f "$proj/Cargo.toml" ]         && tags="$tags rust"
  [ -f "$proj/package.json" ]        && tags="$tags node"
  [ -f "$proj/pnpm-workspace.yaml" ] && tags="$tags pnpm-mono"
  { [ -f "$proj/pyproject.toml" ] || [ -f "$proj/requirements.txt" ]; } && tags="$tags python"
  [ -f "$proj/go.mod" ]              && tags="$tags go"
  [ -f "$proj/wrangler.toml" ]       && tags="$tags cf-worker"
  { [ -f "$proj/docker-compose.yml" ] || [ -f "$proj/docker-compose.yaml" ]; } && tags="$tags docker"
  { [ -f "$proj/next.config.ts" ] || [ -f "$proj/next.config.js" ]; } && tags="$tags nextjs"
  tags="${tags# }"  # trim leading space
  [ -n "$tags" ] && echo "${proj#"$HOME/"}: $tags"
done < <(find ~/dev -mindepth 2 -maxdepth 3 -type d \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/.next/*" \
  ! -name ".next" \
  | sort)

echo ""
echo "=== COMPOSE_AND_WRANGLER ==="
find ~/dev -maxdepth 3 \( -name "docker-compose*" -o -name "wrangler.toml" \) 2>/dev/null | sort

echo ""
echo "=== SKILLS ==="
ls ~/.claude/commands/ 2>/dev/null || echo "(none)"

echo ""
echo "=== MCP_FILES ==="
find ~/.mcp -type f 2>/dev/null | head -20 || echo "(~/.mcp not found)"

echo ""
echo "=== CUSTOM_BIN ==="
echo "~/bin:"; ls ~/bin/ 2>/dev/null || echo "(empty)"
echo "~/.local/bin:"; ls ~/.local/bin/ 2>/dev/null | head -20 || echo "(empty)"

echo ""
echo "=== GIT_CONFIG ==="
cat ~/.gitconfig 2>/dev/null || echo "(not found)"

echo ""
echo "=== NPM_GLOBAL ==="
npm list -g --depth=0 2>/dev/null | tail -n +2 || echo "(npm not available)"

echo ""
echo "=== AGENT_MANIFEST ==="
head -80 ~/agents.manifest.yaml 2>/dev/null || echo "(not found)"

echo ""
echo "=== HOME_SYMLINKS ==="
find ~/ -maxdepth 1 -type l -exec ls -la {} \; 2>/dev/null || echo "(none)"

echo ""
echo "=== RUNNING_PROCESSES ==="
ps aux --no-header \
  | grep -v -E '(bash|/bin/sh|ps |grep |sshd|systemd|init|kernel|kworker|kthread|ksoftirq|migration|rcu_|idle)' \
  | sort -k3 -rn \
  | head -15
