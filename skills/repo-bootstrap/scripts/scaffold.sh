#!/usr/bin/env bash
# repo-bootstrap/scripts/scaffold.sh
# Creates a GitHub repo and writes standard files
set -euo pipefail

REPO_ORG="${REPO_ORG:-madebymadhouse}"
REPO_NAME="${REPO_NAME:-}"
REPO_DESC="${REPO_DESC:-}"
REPO_VISIBILITY="${REPO_VISIBILITY:-public}"
REPO_TYPE="${REPO_TYPE:-tool}"

if [[ -z "$REPO_NAME" ]]; then
  echo '{"created":false,"error":"REPO_NAME is required"}'; exit 1
fi

# Determine local parent path
case "$REPO_ORG" in
  madebymadhouse)   LOCAL_PARENT="${HOME}/dev/mad-house" ;;
  orinadus-systems) LOCAL_PARENT="${HOME}/dev/orinadus" ;;
  samhcharles)      LOCAL_PARENT="${HOME}/dev/personal" ;;
  *) echo "{\"created\":false,\"error\":\"unknown org: $REPO_ORG\"}"; exit 1 ;;
esac

LOCAL_PATH="${LOCAL_PARENT}/${REPO_NAME}"

if [[ -d "$LOCAL_PATH" ]]; then
  echo "{\"created\":false,\"error\":\"directory already exists: $LOCAL_PATH\"}"; exit 1
fi

# Create GitHub repo
VISIBILITY_FLAG="--${REPO_VISIBILITY}"
gh repo create "${REPO_ORG}/${REPO_NAME}" \
  --description "${REPO_DESC}" \
  $VISIBILITY_FLAG \
  --clone \
  --clone-dir "$LOCAL_PATH" 2>&1 | grep -v "^Cloning" >&2 || true

GITHUB_URL="https://github.com/${REPO_ORG}/${REPO_NAME}"

# Write .gitignore
cat > "${LOCAL_PATH}/.gitignore" << 'EOF'
# Secrets
.env
*.env.*
!.env.example

# Agent context (never public)
AGENTS.md
CLAUDE.md
GEMINI.md

# OS and editor
.DS_Store
.idea/
.vscode/settings.json

# Python
__pycache__/
*.pyc
venv/
.venv/
*.egg-info/
dist/
build/

# Node
node_modules/
.next/
dist/

# Rust
target/

# Jupyter
.ipynb_checkpoints/
EOF

# Write CHANGELOG.md
cat > "${LOCAL_PATH}/CHANGELOG.md" << EOF
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
EOF

# Write README.md
cat > "${LOCAL_PATH}/README.md" << EOF
# ${REPO_NAME}

${REPO_DESC}

## Quick start

\`\`\`bash
git clone https://github.com/${REPO_ORG}/${REPO_NAME}.git
cd ${REPO_NAME}
\`\`\`

## Development

_Add development instructions here._

## License

MIT
EOF

# Write .env.example and Dockerfile for service/bot types
if [[ "$REPO_TYPE" == "service" || "$REPO_TYPE" == "bot" ]]; then
  cat > "${LOCAL_PATH}/.env.example" << 'EOF'
# Copy this file to .env and fill in values
# Never commit .env

# Example:
# API_KEY=your-key-here
EOF

  cat > "${LOCAL_PATH}/Dockerfile" << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m appuser
USER appuser

CMD ["python", "-m", "app.main"]
EOF
fi

python3 -c "
import json
print(json.dumps({
  'created': True,
  'local_path': '${LOCAL_PATH}',
  'github_url': '${GITHUB_URL}',
  'org': '${REPO_ORG}',
  'type': '${REPO_TYPE}'
}))
"
