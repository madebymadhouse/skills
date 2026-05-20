#!/usr/bin/env bash
set -euo pipefail

SURFACE="${1:-all}"
DIRECTION="${2:-canonical-to-live}"
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

LIVE_VAULT="$(resolve_live_vault)"

case "$DIRECTION" in
  canonical-to-live)
    SRC="$CANONICAL_VAULT"
    DST="$LIVE_VAULT"
    ;;
  live-to-canonical)
    SRC="$LIVE_VAULT"
    DST="$CANONICAL_VAULT"
    ;;
  *)
    echo "Unknown direction: $DIRECTION" >&2
    exit 1
    ;;
esac

declare -a FILES=()

add_graph() {
  FILES+=(
    ".obsidian/graph.json"
    ".obsidian/plugins/extended-graph/data.json"
  )
}

add_plugins() {
  FILES+=(
    ".obsidian/community-plugins.json"
    ".obsidian/core-plugins.json"
    ".obsidian/plugins/manual-sorting/data.json"
    ".obsidian/plugins/obsidian-git/data.json"
    ".obsidian/plugins/obsidian-file-color/data.json"
    ".obsidian/plugins/obsidian-icon-folder/data.json"
    ".obsidian/plugins/lean-terminal/data.json"
  )
}

add_dashboards() {
  while IFS= read -r file; do
    FILES+=("${file#$SRC/}")
  done < <(find "$SRC/dashboards" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
}

case "$SURFACE" in
  graph) add_graph ;;
  plugins) add_plugins ;;
  dashboards) add_dashboards ;;
  all)
    add_graph
    add_plugins
    add_dashboards
    ;;
  *)
    echo "Unknown surface: $SURFACE" >&2
    exit 1
    ;;
esac

copied=0
declare -A seen=()

for rel in "${FILES[@]}"; do
  [[ -n "${seen[$rel]:-}" ]] && continue
  seen[$rel]=1
  if [[ ! -e "$SRC/$rel" ]]; then
    echo "SKIP missing: $SRC/$rel"
    continue
  fi
  mkdir -p "$DST/$(dirname "$rel")"
  cp -f "$SRC/$rel" "$DST/$rel"
  echo "COPIED $rel"
  copied=$((copied + 1))
done

echo "copied=$copied surface=$SURFACE direction=$DIRECTION"

if [[ "$copied" -eq 0 ]]; then
  exit 1
fi
