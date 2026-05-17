# Mad House Skills

Agent skills for Claude Code — ops and workspace tooling for WSL + Coolify/Docker VPS setups.

## Skills

### Infrastructure Auditing
| Skill | What it does |
|-------|-------------|
| [`wsl-audit`](skills/wsl-audit/) | Full snapshot of your WSL environment — workspace, runtimes, AI tooling, Docker, env vars |
| [`vps-audit`](skills/vps-audit/) | Deep audit of a remote VPS — containers, Traefik routes, disk, firewall, logs |
| [`ops-audit`](skills/ops-audit/) | Both audits at once with a cross-environment summary |
| [`env-sync`](skills/env-sync/) | Detect drift between skill scripts and your actual environment |

### Workspace Management
| Skill | What it does |
|-------|-------------|
| [`workspace-audit`](skills/workspace-audit/) | Check all git repos for dirty state, unpushed commits, and exposed secrets |
| [`workspace-sync`](skills/workspace-sync/) | Fast-forward pull all clean repos in one shot |
| [`workspace-drift`](skills/workspace-drift/) | Health check across git repos, live services, VPS, Coolify, and npm packages |
| [`wsl-debloat`](skills/wsl-debloat/) | Free disk space — clear npm/pip/pnpm/playwright caches, prune Docker on VPS |

### Developer Tooling
| Skill | What it does |
|-------|-------------|
| [`skill-audit`](skills/skill-audit/) | Audit your Claude Code skills for quality, structure, and efficiency |
| [`uninstall`](skills/uninstall/) | Completely remove a CLI tool — every trace across package managers, configs, caches |
| [`incubate`](skills/incubate/) | Mad House project lifecycle manager — new, list, stage, promote, ship, archive |

## Install

```bash
git clone https://github.com/madebymadhouse/skills.git /tmp/madhouse-skills
cp -r /tmp/madhouse-skills/skills/* ~/.claude/commands/
```

Or install a single skill:
```bash
cp -r /tmp/madhouse-skills/skills/wsl-audit ~/.claude/commands/
```

## Setup

**VPS skills** (`vps-audit`, `ops-audit`, `env-sync`, `wsl-debloat`, `workspace-drift`) connect to your server via SSH. Add a `vps` alias to `~/.ssh/config`:

```
Host vps
  HostName your.server.ip
  User root
  IdentityFile ~/.ssh/your_key
```

**Service health checks** (`workspace-drift`, `wsl-debloat`) read config from `~/.secrets/master.env`:
```
VPS_SSH_HOST=user@your.server.ip
COOLIFY_API_URL=http://your.server.ip:8000
COOLIFY_API_TOKEN=your_token
DASHBOARD_URL=https://your-dashboard-url
```

## How these skills work

Every skill follows the same pattern: a `scripts/` bash script handles all deterministic operations, and the `SKILL.md` tells Claude how to synthesize or act on the output. Claude never re-runs commands inline — the script does the work, Claude does the thinking.

## License

MIT
