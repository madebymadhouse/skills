---
name: coolify-deploy
description: Deploy, restart, or check status of any application or service on the Coolify VPS. Lists all deployable resources, triggers deploys, tails logs, and confirms the container comes up healthy. Use when deploying a new version, restarting a service, checking deploy status, or reading deployment logs. Triggers on "deploy", "restart service", "push to production", "deploy to vps", "check deploy status", "deployment logs", "is it deployed".
argument-hint: <service-name> — partial name is fine, will fuzzy match
compatibility: Requires COOLIFY_API_BASE and COOLIFY_API_TOKEN in ~/.secrets/master.env.
allowed-tools: Bash Read
---

# Coolify Deploy

Triggers and monitors deployments on the Coolify VPS via the REST API.

## Arguments

Service to deploy: $ARGUMENTS

## Tools

Each script is a single-purpose tool that returns JSON.

### `scripts/list.sh`

List all applications and services.

```
Input:  (none)
Output: { applications: [{ uuid, name, status, fqdn }], services: [{ uuid, name, status, fqdn }] }
```

### `scripts/search.sh <query>`

Fuzzy match an application by name (case-insensitive substring).

```
Input:  query (string, required)
Output: { matched: bool, uuid: string, name: string, candidates: [{ uuid, name, status }] }
```

`matched: true` means exactly one result — `uuid` and `name` are set.
`matched: false` means zero or multiple results — `candidates` lists all options (or all apps if no matches).

### `scripts/start.sh <uuid>`

Trigger a deploy/start for an application.

```
Input:  uuid (string, required)
Output: { triggered: bool, uuid: string, name: string }
```

### `scripts/status.sh <uuid>`

Get the current status of an application.

```
Input:  uuid (string, required)
Output: { uuid, name, status, healthy: bool }
```

`status` values: `running`, `exited`, `stopped`, `starting`, `unknown`

### `scripts/logs.sh <uuid> [--lines N]`

Fetch recent deployment logs.

```
Input:  uuid (string, required), --lines N (optional, default 20)
Output: { uuid: string, lines: [string] }
```

## Workflow

**If no argument was given** — list all services and ask the user which one:

```bash
~/.claude/commands/coolify-deploy/scripts/list.sh
```

Show a clean table of name, status, fqdn. Let the user pick one by name.

**If a service name was given** — fuzzy match, then deploy:

1. Run `search.sh` with the argument:

```bash
~/.claude/commands/coolify-deploy/scripts/search.sh "$ARGUMENTS"
```

   - `matched: false`, empty candidates: run `list.sh` and show the full table, ask the user to clarify
   - `matched: false`, candidates present: show the candidates and ask the user to pick
   - `matched: true`: confirm the name and UUID, then proceed

2. Trigger the deploy:

```bash
~/.claude/commands/coolify-deploy/scripts/start.sh <uuid>
```

3. Poll status every 5 seconds until `healthy: true` or a failed state. Run up to 24 polls (2 minutes):

```bash
~/.claude/commands/coolify-deploy/scripts/status.sh <uuid>
```

4. If status is `running` / `healthy: true`: confirm success.

5. If status is `exited` or `stopped`, or after timeout: fetch logs and show why it failed:

```bash
~/.claude/commands/coolify-deploy/scripts/logs.sh <uuid> --lines 30
```

## Report

One clear outcome: deployed and healthy, or failed with the reason from logs.
