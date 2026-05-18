# Mad House Skills

**A build house, incubating in the open.**

We make tools. These are the ones we use every day in [Claude Code](https://claude.ai/code). They're yours too.

A skill is a superpower for Claude. You describe what you want, Claude picks up the right tool and handles it. No setup required, no commands to memorize. Just tell Claude what you need.

---

## What's in the box

### See what's going on

| Skill | What it does |
|-------|-------------|
| [wsl-audit](skills/wsl-audit/) | X-ray your WSL machine. See every project, runtime, AI tool, and open connection. |
| [vps-audit](skills/vps-audit/) | X-ray your server. Every container, every route, every open port. |
| [ops-audit](skills/ops-audit/) | Both at once. Your local machine and your server, side by side. |

### Keep things clean

| Skill | What it does |
|-------|-------------|
| [workspace-audit](skills/workspace-audit/) | Check all your git repos at once. Find dirty changes, unpushed commits, and accidentally tracked secrets. |
| [workspace-sync](skills/workspace-sync/) | Pull every repo that's behind upstream. One ask, all repos. |
| [wsl-debloat](skills/wsl-debloat/) | Free up disk space. Clears npm, pip, pnpm, and playwright caches. Prunes Docker on your server too. |

### Stay sharp

| Skill | What it does |
|-------|-------------|
| [workspace-drift](skills/workspace-drift/) | Health check everything at once: repos, live services, your server, npm packages. |
| [env-sync](skills/env-sync/) | Makes sure your skill scripts still match what's actually on your machine. Finds the gaps. |
| [skill-audit](skills/skill-audit/) | Audits the skills themselves. Finds dead weight, duplicated logic, and weak descriptions. |

### Build things

| Skill | What it does |
|-------|-------------|
| [incubate](skills/incubate/) | Mad House project tracker. Take an idea from concept to shipped, one stage at a time. |
| [uninstall](skills/uninstall/) | Completely remove any tool. Finds every trace across package managers, config folders, and caches. |

### Ship things

| Skill | What it does |
|-------|-------------|
| [coolify-deploy](skills/coolify-deploy/) | Deploy or restart any Coolify service from chat. Lists what's running, triggers a deploy, and tails logs if it fails. |
| [skill-publish](skills/skill-publish/) | Package a local skill and push it to the public skills repo. Scrubs internals, updates the README, commits, and pushes. |
| [agent-fleet](skills/agent-fleet/) | Manage your agent fleet. See what agents are deployed where, sync the registry to any repo, or add new agents. |

---

## Installing a skill

Paste either of these into Claude and it will handle the rest.

```
Install all skills from github.com/madebymadhouse/skills into my Claude Code setup
```

```
Install the [skill-name] skill from github.com/madebymadhouse/skills into my Claude Code setup
```

---

## If you prefer to do it yourself

```bash
git clone https://github.com/madebymadhouse/skills.git /tmp/madhouse-skills
cp -r /tmp/madhouse-skills/skills/* ~/.claude/commands/
```

---

## A note on setup

Skills that talk to a remote server need an SSH alias called `vps` in `~/.ssh/config`:

```
Host vps
  HostName your.server.ip
  User root
  IdentityFile ~/.ssh/your_key
```

Skills that check live services read from `~/.secrets/master.env`:

```
VPS_SSH_HOST=user@your.server.ip
COOLIFY_API_URL=http://your.server.ip:8000
COOLIFY_API_TOKEN=your_token
DASHBOARD_URL=https://your-dashboard-url
```

---

## How it works

Every skill has two parts: a bash script that collects information or performs a task, and a `SKILL.md` that tells Claude what to do with it. The script does the deterministic work. Claude does the thinking.

This means Claude never wastes time re-running commands or guessing at output. It reads structured data and gives you a useful answer.

---

Built with love at [Mad House](https://github.com/madebymadhouse).
