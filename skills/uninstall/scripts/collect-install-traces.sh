#!/usr/bin/env bash
# Find all filesystem traces of a tool/package. No AI. Called by uninstall skill.
# Usage: collect-install-traces.sh <tool-name>

set -uo pipefail

TOOL="${1:?Usage: $0 <tool-name>}"

echo "=== BINARY ==="
which "$TOOL" 2>/dev/null || echo "(not in PATH)"
find /usr/local/bin /usr/bin ~/.local/bin -name "$TOOL" 2>/dev/null || true

echo ""
echo "=== NPM_GLOBAL ==="
npm list -g 2>/dev/null | grep -i "$TOOL" || echo "(not found in npm globals)"
find ~/.nvm/versions -name "$TOOL" -type f 2>/dev/null | head -10 || true
find ~/.nvm/versions/node/*/lib/node_modules -maxdepth 2 -iname "*${TOOL}*" -type d 2>/dev/null | head -10 || true

echo ""
echo "=== PIP_PIPX ==="
pip show "$TOOL" 2>/dev/null || echo "(pip: not installed)"
pipx list 2>/dev/null | grep -i "$TOOL" || echo "(pipx: not installed or not found)"

echo ""
echo "=== CARGO ==="
ls ~/.cargo/bin/ 2>/dev/null | grep -i "$TOOL" || echo "(not found in cargo bin)"

echo ""
echo "=== CONFIG_DIRS ==="
for d in ~/."$TOOL" ~/.config/"$TOOL" ~/.local/share/"$TOOL" ~/.local/state/"$TOOL" ~/.cache/"$TOOL"; do
  [ -e "$d" ] && echo "$d" || true
done
echo "(end of config dirs)"

echo ""
echo "=== NPX_CACHE ==="
find ~/.npm/_npx -maxdepth 4 -iname "*${TOOL}*" -type d 2>/dev/null | head -10 || echo "(none)"
find ~/.local/share/zed/node/cache/_npx -maxdepth 4 -iname "*${TOOL}*" -type d 2>/dev/null | head -5 || echo "(none)"

echo ""
echo "=== VSCODE_EXTENSIONS ==="
find ~/.vscode-server/extensions -maxdepth 1 -iname "*${TOOL}*" -type d 2>/dev/null || echo "(none)"
find ~/.vscode-server/data/CachedExtensionVSIXs -maxdepth 1 -iname "*${TOOL}*" 2>/dev/null || echo "(none)"

echo ""
echo "=== HOME_FILES ==="
# Shallow scan — avoid traversing huge trees
find ~/ -maxdepth 3 -iname "*${TOOL}*" \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/dev/*" \
  2>/dev/null | head -30 || echo "(none)"

echo ""
echo "=== SYSTEMD_UNITS ==="
systemctl --user list-units 2>/dev/null | grep -i "$TOOL" || echo "(none in user units)"
systemctl list-units 2>/dev/null | grep -i "$TOOL" || echo "(none in system units)"
