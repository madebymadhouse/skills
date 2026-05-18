#!/usr/bin/env bash
# scan.sh — survey disk state: WSL caches, VPS Docker, lab node_modules
# Output: JSON { wsl, vps, lab }
# Does NOT clean anything.
set -euo pipefail

SECRETS_FILE="${HOME}/.secrets/master.env"
VPS_SSH_HOST=""
[[ -f "$SECRETS_FILE" ]] && VPS_SSH_HOST=$(grep -m1 '^VPS_SSH_HOST=' "$SECRETS_FILE" | cut -d= -f2- || true)

tmpvps=$(mktemp)
tmpnm=$(mktemp)
trap 'rm -f "$tmpvps" "$tmpnm"' EXIT

# ── WSL disk ─────────────────────────────────────────────────────────────────
export WSL_USED=$(df -h / | awk 'NR==2{print $3}')
export WSL_TOTAL=$(df -h / | awk 'NR==2{print $2}')
export WSL_PCT=$(df -h / | awk 'NR==2{print $5}')

# ── WSL cache sizes ───────────────────────────────────────────────────────────
cache_size() { [[ -d "$1" ]] && du -sh "$1" 2>/dev/null | cut -f1 || echo ""; }

export NPM_PATH=$(npm config get cache 2>/dev/null || echo "${HOME}/.npm")
export NPM_SZ=$(cache_size "$NPM_PATH")
export PIP_SZ=$(cache_size "${HOME}/.cache/pip")
export PNPM_SZ=$(cache_size "${HOME}/.cache/pnpm")
export PLAYWRIGHT_SZ=$(cache_size "${HOME}/.cache/ms-playwright-go")
export NODEGYP_SZ=$(cache_size "${HOME}/.cache/node-gyp")
export PUPPETEER_SZ=$(cache_size "${HOME}/.cache/puppeteer")
export PRISMA_SZ=$(cache_size "${HOME}/.cache/prisma")
export CARGO_SZ=$(cache_size "${HOME}/.cargo/registry/cache")
export GOMOD_SZ=$(cache_size "${HOME}/go/pkg/mod/cache")

# ── VPS ───────────────────────────────────────────────────────────────────────
if [[ -n "$VPS_SSH_HOST" ]] && ssh -o ConnectTimeout=5 -o BatchMode=yes "$VPS_SSH_HOST" "echo ok" &>/dev/null; then
  ssh -o ConnectTimeout=10 "$VPS_SSH_HOST" '
    used=$(df -h / | awk "NR==2{print \$3}")
    total=$(df -h / | awk "NR==2{print \$2}")
    pct=$(df -h / | awk "NR==2{print \$5}")
    docker_df=$(docker system df 2>/dev/null || echo "unavailable")
    printf "{\"available\":true,\"disk\":{\"used\":\"%s\",\"total\":\"%s\",\"percent\":\"%s\"},\"docker_df_raw\":\"%s\"}" \
      "$used" "$total" "$pct" "$(echo "$docker_df" | base64 -w0)"
  ' > "$tmpvps" 2>/dev/null || echo '{"available":false,"error":"ssh failed"}' > "$tmpvps"
else
  reason="$([ -z "$VPS_SSH_HOST" ] && echo 'VPS_SSH_HOST not configured' || echo 'unreachable')"
  echo "{\"available\":false,\"reason\":\"$reason\"}" > "$tmpvps"
fi

# ── Lab node_modules ──────────────────────────────────────────────────────────
find "${HOME}/dev" -maxdepth 4 -name "node_modules" -type d \
  ! -path "*/node_modules/*/node_modules" 2>/dev/null | sort | while read -r nm; do
  parent="${nm%/node_modules}"
  size=$(du -sh "$nm" 2>/dev/null | cut -f1 || echo "?")
  printf '{"path":"%s","size":"%s"}\n' "${parent#"${HOME}/"}" "$size"
done | python3 -c "
import json, sys
print(json.dumps([json.loads(l) for l in sys.stdin if l.strip()]))
" > "$tmpnm" 2>/dev/null || echo '[]' > "$tmpnm"

# ── Combine into final JSON ───────────────────────────────────────────────────
python3 - "$tmpvps" "$tmpnm" <<'PYEOF'
import json, sys, os, base64

with open(sys.argv[1]) as f:
    vps = json.load(f)
with open(sys.argv[2]) as f:
    node_modules = json.load(f)

# Decode docker system df table
if vps.get("available") and vps.get("docker_df_raw"):
    try:
        vps["docker_df"] = base64.b64decode(vps["docker_df_raw"]).decode().strip()
    except Exception:
        vps["docker_df"] = ""
    del vps["docker_df_raw"]

def entry(name, path):
    sz = os.environ.get(name.upper().replace("-", "").replace("_", "") + "_SZ", "")
    # handle special names
    aliases = {"NPM": "NPM_SZ", "PIP": "PIP_SZ", "PNPM": "PNPM_SZ",
               "PLAYWRIGHT": "PLAYWRIGHT_SZ", "NODEGYP": "NODEGYP_SZ",
               "PUPPETEER": "PUPPETEER_SZ", "PRISMA": "PRISMA_SZ",
               "CARGO": "CARGO_SZ", "GOMOD": "GOMOD_SZ"}
    key = name.upper().replace("-", "")
    sz = os.environ.get(aliases.get(key, key + "_SZ"), "")
    return {"name": name, "size": sz if sz else None, "available": bool(sz), "path": path}

result = {
    "wsl": {
        "disk": {
            "used":    os.environ["WSL_USED"],
            "total":   os.environ["WSL_TOTAL"],
            "percent": os.environ["WSL_PCT"]
        },
        "caches": [
            entry("npm",        os.environ.get("NPM_PATH", "~/.npm")),
            entry("pip",        "~/.cache/pip"),
            entry("pnpm",       "~/.cache/pnpm"),
            entry("playwright", "~/.cache/ms-playwright-go"),
            entry("nodegyp",    "~/.cache/node-gyp"),
            entry("puppeteer",  "~/.cache/puppeteer"),
            entry("prisma",     "~/.cache/prisma"),
            entry("cargo",      "~/.cargo/registry/cache"),
            entry("gomod",      "~/go/pkg/mod/cache"),
        ]
    },
    "vps": vps,
    "lab": {"node_modules": node_modules}
}
print(json.dumps(result, indent=2))
PYEOF
