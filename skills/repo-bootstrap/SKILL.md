---
name: repo-bootstrap
description: Bootstrap a new GitHub repo with all standard Mad House files. Creates
  the repo, clones it locally under the correct org path, and writes README, .gitignore,
  .env.example, Dockerfile, CHANGELOG, and AGENTS.md template. Triggers on "new repo",
  "bootstrap a repo", "create a new project", "start a new repo", "scaffold repo".
allowed-tools: Bash, Write, Read
disable_model_invocation: true
---

# repo-bootstrap

One command from idea to a push-ready local repo with all standard files.

## Tools

### scripts/scaffold.sh
Creates a GitHub repo and writes all standard files.
- Input: `REPO_ORG=madebymadhouse|orinadus-systems|samhcus`
- Input: `REPO_NAME=<kebab-case-name>`
- Input: `REPO_DESC=<one sentence>`
- Input: `REPO_VISIBILITY=public|private` (default: public)
- Input: `REPO_TYPE=service|lib|bot|tool` (default: tool)
- Output: `{created: bool, local_path: string, github_url: string}`

## Workflow

1. Collect: org, name, one-line description, visibility, type (service/lib/bot/tool)
2. Run `scripts/scaffold.sh`
3. Report the local path and GitHub URL
4. Do NOT make the initial commit - the user reviews the files first

## Standard files written

| File | Always | Service | Bot |
|------|--------|---------|-----|
| README.md | Yes | Yes | Yes |
| .gitignore | Yes | Yes | Yes |
| CHANGELOG.md | Yes | Yes | Yes |
| .env.example | | Yes | Yes |
| Dockerfile | | Yes | Yes |

## Org paths

| Org | Local path |
|-----|-----------|
| madebymadhouse | ~/dev/mad-house/<name> |
| orinadus-systems | ~/dev/orinadus/<name> |
| samhcus | ~/dev/personal/<name> |
