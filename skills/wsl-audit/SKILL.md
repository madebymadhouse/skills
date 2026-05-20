---
name: wsl-audit
description: Deep audit of a WSL environment. Use when the user wants to understand what's running on their local machine, see the dev workspace, check runtimes, AI tooling, shell config, SSH keys, Docker state, or get an eagle-eye view of WSL. Triggers on phrases like "audit wsl", "what's on my machine", "check my local setup", "what projects do I have", or "show me my dev workspace".
compatibility: Designed for Claude Code on WSL (Windows Subsystem for Linux). Requires bash, find, and standard GNU tools.
allowed-tools: Bash Read
---

# WSL Audit

All data collection runs via `scripts/collect-wsl.sh`. Your job is to synthesize the structured output into a report - do not re-run collection commands yourself.

## Step 1 - Collect

```bash
~/.claude/commands/wsl-audit/scripts/collect-wsl.sh
```

## Step 2 - Synthesize

Read the labeled sections and produce the following report. Use only what the script returned.

---

### System Identity
From SYSTEM: hostname, OS, kernel, user, groups, sudo access.

### Hardware / Resources
From RESOURCES: CPU cores, RAM total/used/free, disk used/total, swap if present.

### Shell & Environment
From BASHRC_ENV_VAR_NAMES: list env var names defined (never print values - names only).
From BASHRC_AUTOSTARTS: describe what each auto-started process does.
Note any PATH extensions that look unusual.

### Dev Workspace Map
Use DEV_TREE and PROJECT_LANGS. Group repos by top-level org directory found in ~/dev.

For each repo: name, detected runtime(s), whether a CF worker or docker-compose is present.
For any project with no detected runtime, call it out - may be docs-only or non-standard structure.

### AI Tooling Ecosystem
From AI_CLIENTS and OLLAMA_MODELS:
- Which AI client dirs are present in home
- Ollama: running? which models?
- Claude Code skills from SKILLS section
- Agent manifest summary from AGENT_MANIFEST

### Language Runtimes
From RUNTIMES: Node (NVM versions), Rust, Python, others. Note anything `not found`.

### SSH & Auth
From SSH: key names (not contents), config hosts, Git credential helper from GIT_CONFIG.

### Docker
From DOCKER: running containers if daemon is up; note if daemon is down.
From COMPOSE_AND_WRANGLER: list compose and wrangler files found.

### Custom Tooling
From SKILLS, CUSTOM_BIN, MCP_FILES: skills, scripts in ~/bin, MCP servers.

### Flags / Concerns
- Secrets-sounding env var names defined directly in bashrc (not via secret manager)
- Projects with no detected runtime
- Docker daemon not running
- Anything unexpected in RUNNING_PROCESSES
- SSH keys whose purpose isn't obvious from the name

Keep the report dense and actionable. No padding.
