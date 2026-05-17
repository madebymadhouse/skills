# Mad House Skills

Agent skills for Claude Code — ops tooling for WSL + Coolify/Docker VPS setups.

These are generic, modular skills. They work out of the box for any WSL dev machine and any VPS running Docker/Coolify/Traefik. Skills that connect to a remote server use an SSH alias you configure.

## Skills

| Skill | What it does |
|-------|-------------|
| [`wsl-audit`](skills/wsl-audit/) | Full snapshot of your WSL environment — workspace, runtimes, AI tooling, Docker, env vars |
| [`vps-audit`](skills/vps-audit/) | Deep audit of a remote VPS — containers, Traefik routes, disk, firewall, logs |
| [`ops-audit`](skills/ops-audit/) | Both audits at once, cross-environment summary (requires wsl-audit + vps-audit) |
| [`env-sync`](skills/env-sync/) | Detect drift between skill scripts and your actual environment |
| [`skill-audit`](skills/skill-audit/) | Audit your Claude Code skills for quality, structure, and efficiency |
| [`uninstall`](skills/uninstall/) | Completely remove a CLI tool — finds every trace across package managers, configs, caches |

## Install

**Install all skills:**
```bash
git clone https://github.com/madebymadhouse/skills.git /tmp/madhouse-skills
cp -r /tmp/madhouse-skills/skills/* ~/.claude/commands/
```

**Install a single skill:**
```bash
git clone https://github.com/madebymadhouse/skills.git /tmp/madhouse-skills
cp -r /tmp/madhouse-skills/skills/wsl-audit ~/.claude/commands/
```

## Setup

**VPS skills** (`vps-audit`, `ops-audit`, `env-sync`) connect to your server via SSH. Add a `vps` alias to `~/.ssh/config`:

```
Host vps
  HostName your.server.ip
  User root
  IdentityFile ~/.ssh/your_key
```

Or set `VPS_SSH_TARGET=user@host` before running the collection scripts.

## How these skills work

Each skill follows the same pattern:

1. **A `scripts/` script handles all deterministic data collection** — bash, no AI, runs fast
2. **The `SKILL.md` instructs Claude how to synthesize** — judgment, grouping, flagging

This separation means Claude never wastes tokens re-running commands or interpreting raw output — the script does the gathering, Claude does the thinking.

## License

MIT
