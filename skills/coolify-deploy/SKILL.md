---
name: coolify-deploy
description: Deploy, restart, or check status of any application or service on the Coolify VPS. Lists all deployable resources, triggers deploys, tails logs, and confirms the container comes up healthy. Use when deploying a new version, restarting a service, checking deploy status, or reading deployment logs. Triggers on "deploy", "restart service", "push to production", "deploy to vps", "check deploy status", "deployment logs", "is it deployed".
argument-hint: <service-name> - partial name is fine, will fuzzy match
compatibility: Requires COOLIFY_API_BASE and COOLIFY_API_TOKEN in ~/.secrets/master.env.
allowed-tools: Bash Read
disable_model_invocation: true
---

# Coolify Deploy

Triggers and monitors deployments on the Coolify VPS via the REST API.

## Arguments

Service to deploy: $ARGUMENTS

## Step 1 - Run

If no argument was given, list all deployable services and ask the user which one:

```bash
~/.claude/commands/coolify-deploy/scripts/deploy.sh list
```

If a service name was given:

```bash
~/.claude/commands/coolify-deploy/scripts/deploy.sh deploy "$ARGUMENTS"
```

## Step 2 - Report

For `list`: show a clean table of all applications and services with their current status. Let the user pick one.

For `deploy`:
- Confirm which service was matched (name + UUID)
- Report deploy triggered
- Show the status polling output until the deploy completes or fails
- If it fails, show the last 20 lines of logs so the user knows why
- If it succeeds, confirm the service is healthy

One clear outcome: deployed and healthy, or failed with reason.
