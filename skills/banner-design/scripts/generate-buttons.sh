#!/usr/bin/env bash
# banner-design/scripts/generate-buttons.sh
# Generates a set of SVG navigation buttons for a GitHub README.
#
# Parameters via env vars:
#   BUTTONS_LABELS     — newline or comma-separated button labels
#                        e.g. "Vibe Coding,VPS & Server,Bots,Incubation,Org Setup"
#   BUTTONS_OUTPUT_DIR — directory to write SVG files (default: ./assets/buttons/)
#   BTN_BG             — button background color (default: #cc2200)
#   BTN_TEXT           — button text color (default: #ffffff)
#   BTN_RADIUS         — corner radius in px (default: 4)
#   BTN_HEIGHT         — button height in px (default: 30)
#   BTN_FONT_SIZE      — font size (default: 11)
#   BTN_PADDING        — horizontal padding on each side (default: 14)
#
# Output: writes one SVG per label to BUTTONS_OUTPUT_DIR, prints JSON manifest

set -euo pipefail

BUTTONS_LABELS="${BUTTONS_LABELS:-}"
BUTTONS_OUTPUT_DIR="${BUTTONS_OUTPUT_DIR:-./assets/buttons/}"
BTN_BG="${BTN_BG:-#cc2200}"
BTN_TEXT="${BTN_TEXT:-#ffffff}"
BTN_RADIUS="${BTN_RADIUS:-4}"
BTN_HEIGHT="${BTN_HEIGHT:-30}"
BTN_FONT_SIZE="${BTN_FONT_SIZE:-11}"
BTN_PADDING="${BTN_PADDING:-14}"

BUTTONS_OUTPUT_DIR="${BUTTONS_OUTPUT_DIR/#\~/$HOME}"
mkdir -p "$BUTTONS_OUTPUT_DIR"

if [[ -z "$BUTTONS_LABELS" ]]; then
  echo '{"error":"BUTTONS_LABELS is required. Comma-separated list of button labels."}' >&2
  exit 1
fi

# Normalize labels: split on commas or newlines
IFS=',' read -ra LABELS <<< "$BUTTONS_LABELS"

# Approximate text width: ~6.5px per char at font-size 11, bold
char_width=6.5

FILES=()

for raw_label in "${LABELS[@]}"; do
  label="${raw_label#"${raw_label%%[![:space:]]*}"}"  # ltrim
  label="${label%"${label##*[![:space:]]}"}"          # rtrim

  if [[ -z "$label" ]]; then continue; fi

  # Slug for filename: lowercase, spaces→hyphens, strip special chars
  slug=$(echo "$label" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
  filename="${BUTTONS_OUTPUT_DIR}/btn-${slug}.svg"

  # Calculate width
  char_count=${#label}
  text_width=$(python3 -c "import math; print(math.ceil($char_count * $char_width))")
  width=$(( text_width + (BTN_PADDING * 2) ))
  text_x=$(( width / 2 ))
  text_y=$(( (BTN_HEIGHT / 2) + (BTN_FONT_SIZE / 2) - 1 ))

  display_label=$(echo "$label" | tr '[:lower:]' '[:upper:]')

  cat > "$filename" <<SVG
<svg width="$width" height="$BTN_HEIGHT" viewBox="0 0 $width $BTN_HEIGHT" xmlns="http://www.w3.org/2000/svg">
  <rect width="$width" height="$BTN_HEIGHT" rx="$BTN_RADIUS" fill="$BTN_BG"/>
  <text
    x="$text_x"
    y="$text_y"
    text-anchor="middle"
    font-family="Inter, 'Helvetica Neue', Arial, sans-serif"
    font-size="$BTN_FONT_SIZE"
    font-weight="600"
    letter-spacing="0.8"
    fill="$BTN_TEXT">$display_label</text>
</svg>
SVG

  FILES+=("{\"label\":\"$label\",\"slug\":\"$slug\",\"file\":\"$filename\"}")
done

# JSON manifest
echo "{"
echo "  \"generated\": ${#FILES[@]},"
echo "  \"output_dir\": \"$BUTTONS_OUTPUT_DIR\","
echo "  \"buttons\": ["
for i in "${!FILES[@]}"; do
  comma=","; [[ $i -eq $(( ${#FILES[@]} - 1 )) ]] && comma=""
  echo "    ${FILES[$i]}$comma"
done
echo "  ]"
echo "}"
