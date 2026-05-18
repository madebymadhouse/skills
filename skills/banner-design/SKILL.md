---
name: banner-design
description: Generate SVG banners and navigation buttons for GitHub README files. Creates repeatable, customizable SVG assets — hero banners with title, subtitle, and tagline, and sets of rounded-corner navigation buttons with Inter font. Use when building or refreshing a repo README, updating branding, or generating any SVG visual assets. Triggers on "generate banner", "create svg banner", "make readme buttons", "banner for the readme", "design banner", "add banner to readme".
allowed-tools: Bash, Read, Write
---

# Banner Design

Generates SVG hero banners and navigation button sets for GitHub READMEs. All output is repeatable — run again to regenerate with different parameters.

## Tools

### scripts/generate-banner.sh
Generates a hero SVG banner (dark background, red accent, Inter font).
- Input (env vars):
  - `BANNER_TITLE` — main title text (uppercased in output)
  - `BANNER_SUBTITLE` — secondary red label below title
  - `BANNER_TAGLINE` — small muted line (default: "written with love")
  - `BANNER_OUTPUT` — output path (default: `./assets/banner.svg`)
  - `BANNER_ACCENT` — accent color (default: `#cc2200`)
  - `BANNER_WIDTH` / `BANNER_HEIGHT` — dimensions (default: 900x160)
- Output: `{generated, output, title, subtitle, dimensions}`

### scripts/generate-buttons.sh
Generates a set of SVG navigation buttons — one file per label.
- Input (env vars):
  - `BUTTONS_LABELS` — comma-separated button labels
  - `BUTTONS_OUTPUT_DIR` — where to write files (default: `./assets/buttons/`)
  - `BTN_BG` — background color (default: `#cc2200`)
  - `BTN_RADIUS` — corner radius (default: `4` — slightly rounded)
  - `BTN_HEIGHT` / `BTN_FONT_SIZE` / `BTN_PADDING` — size tuning
- Output: JSON manifest with `{generated, output_dir, buttons: [{label, slug, file}]}`

## Workflow

### Generating a banner

```bash
BANNER_TITLE="Mad House" BANNER_SUBTITLE="How-Tos" BANNER_TAGLINE="written with love" \
  BANNER_OUTPUT="~/dev/mad-house/how-tos/assets/banner.svg" \
  bash scripts/generate-banner.sh
```

### Generating navigation buttons

```bash
BUTTONS_LABELS="Vibe Coding,VPS & Server,Bots,Incubation,Org Setup" \
  BUTTONS_OUTPUT_DIR="~/dev/mad-house/how-tos/assets/buttons/" \
  bash scripts/generate-buttons.sh
```

### Using in a README

Reference the SVGs as relative paths in Markdown:

```markdown
![Mad House How-Tos](assets/banner.svg)

<a href="#vibe-coding"><img src="assets/buttons/btn-vibe-coding.svg" /></a>
<a href="#vps--server"><img src="assets/buttons/btn-vps--server.svg" /></a>
```

## Rules

- Always run from the repo root so relative paths resolve correctly
- If regenerating, existing files are overwritten — safe to re-run
- `BANNER_TITLE` and button labels are uppercased in the SVG output automatically
- SVGs use Inter with system font fallbacks — works on GitHub's renderer without external resources
