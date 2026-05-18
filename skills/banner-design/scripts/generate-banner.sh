#!/usr/bin/env bash
# banner-design/scripts/generate-banner.sh
# Generates an SVG hero banner for a GitHub README.
#
# All parameters via env vars:
#   BANNER_TITLE       — main large title (default: "Mad House")
#   BANNER_SUBTITLE    — secondary label (default: "")
#   BANNER_TAGLINE     — small muted line below (default: "written with love")
#   BANNER_OUTPUT      — output file path (default: ./assets/banner.svg)
#   BANNER_WIDTH       — SVG width in px (default: 900)
#   BANNER_HEIGHT      — SVG height in px (default: 160)
#   BANNER_BG          — background color (default: #0d0d0d)
#   BANNER_ACCENT      — accent/highlight color (default: #cc2200)
#   BANNER_TEXT        — main text color (default: #ffffff)
#   BANNER_MUTED       — muted text color (default: #555555)
#
# Output: writes SVG file to BANNER_OUTPUT, prints path to stdout

set -euo pipefail

BANNER_TITLE="${BANNER_TITLE:-Mad House}"
BANNER_SUBTITLE="${BANNER_SUBTITLE:-}"
BANNER_TAGLINE="${BANNER_TAGLINE:-written with love}"
BANNER_OUTPUT="${BANNER_OUTPUT:-./assets/banner.svg}"
BANNER_WIDTH="${BANNER_WIDTH:-900}"
BANNER_HEIGHT="${BANNER_HEIGHT:-160}"
BANNER_BG="${BANNER_BG:-#0d0d0d}"
BANNER_ACCENT="${BANNER_ACCENT:-#cc2200}"
BANNER_TEXT="${BANNER_TEXT:-#ffffff}"
BANNER_MUTED="${BANNER_MUTED:-#555555}"

BANNER_OUTPUT="${BANNER_OUTPUT/#\~/$HOME}"
mkdir -p "$(dirname "$BANNER_OUTPUT")"

# Vertical layout math
TITLE_Y=80
SUBTITLE_Y=112
TAGLINE_Y=140
if [[ -z "$BANNER_SUBTITLE" ]]; then
  TITLE_Y=85
  TAGLINE_Y=118
fi

SUBTITLE_BLOCK=""
if [[ -n "$BANNER_SUBTITLE" ]]; then
  SUBTITLE_BLOCK="<text x=\"56\" y=\"$SUBTITLE_Y\" font-family=\"Inter, 'Helvetica Neue', Arial, sans-serif\" font-size=\"18\" font-weight=\"600\" letter-spacing=\"3\" fill=\"$BANNER_ACCENT\">$(echo "$BANNER_SUBTITLE" | tr '[:lower:]' '[:upper:]')</text>"
fi

cat > "$BANNER_OUTPUT" <<SVG
<svg width="$BANNER_WIDTH" height="$BANNER_HEIGHT" viewBox="0 0 $BANNER_WIDTH $BANNER_HEIGHT" xmlns="http://www.w3.org/2000/svg">
  <!-- Background -->
  <rect width="$BANNER_WIDTH" height="$BANNER_HEIGHT" fill="$BANNER_BG"/>

  <!-- Red vertical accent bar -->
  <rect x="32" y="44" width="3" height="$(( BANNER_HEIGHT - 88 ))" rx="1.5" fill="$BANNER_ACCENT"/>

  <!-- Top accent line -->
  <rect x="0" y="0" width="$BANNER_WIDTH" height="2" fill="$BANNER_ACCENT" opacity="0.6"/>

  <!-- Main title -->
  <text
    x="56"
    y="$TITLE_Y"
    font-family="Inter, 'Helvetica Neue', Arial, sans-serif"
    font-size="32"
    font-weight="700"
    letter-spacing="-0.5"
    fill="$BANNER_TEXT">$(echo "$BANNER_TITLE" | tr '[:lower:]' '[:upper:]')</text>

  $SUBTITLE_BLOCK

  <!-- Tagline -->
  <text
    x="56"
    y="$TAGLINE_Y"
    font-family="Inter, 'Helvetica Neue', Arial, sans-serif"
    font-size="12"
    font-weight="400"
    letter-spacing="0.5"
    fill="$BANNER_MUTED">$BANNER_TAGLINE</text>
</svg>
SVG

python3 -c "
import json, os
print(json.dumps({
  'generated': True,
  'output': os.path.abspath('$BANNER_OUTPUT'),
  'title': '$BANNER_TITLE',
  'subtitle': '$BANNER_SUBTITLE',
  'dimensions': '${BANNER_WIDTH}x${BANNER_HEIGHT}'
}))
"
