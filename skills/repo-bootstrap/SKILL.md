---
name: repo-bootstrap
description: Bootstrap a new GitHub repo with all standard files. Creates the repo,
  clones it locally, and writes README, .gitignore, .env.example, Dockerfile, and
  CHANGELOG. Triggers on "new repo", "bootstrap a repo", "create a new project",
  "start a new repo", "scaffold repo".
allowed-tools: Bash, Write, Read
---

# repo-bootstrap

One command from idea to a push-ready local repo with all standard files.

## Tools

### scripts/scaffold.sh
Creates a GitHub repo and writes all standard files.
- Input: `REPO_ORG=<github-org-or-user>` — the GitHub org or user to create the repo under
- Input: `REPO_NAME=<kebab-case-name>`
- Input: `REPO_DESC=<one sentence>`
- Input: `LOCAL_PARENT=<absolute path>` — where to clone locally (default: `$HOME/dev`)
- Input: `REPO_VISIBILITY=public|private` (default: public)
- Input: `REPO_TYPE=service|lib|bot|tool` (default: tool)
- Output: `{created: bool, local_path: string, github_url: string}`

## Workflow

1. Collect: org, name, one-line description, where to clone locally, visibility, type
2. Run `scripts/scaffold.sh`
3. Report the local path and GitHub URL
4. Do NOT make the initial commit — the user reviews the files first

## Standard files written

| File | Always | Service/Bot |
|------|--------|-------------|
| README.md | Yes | Yes |
| .gitignore | Yes | Yes |
| CHANGELOG.md | Yes | Yes |
| .env.example | | Yes |
| Dockerfile | | Yes |
