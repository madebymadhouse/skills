---
name: agent-fleet
description: Manage the Mad House agent fleet. List all agents in the central registry, check which repos have which agents deployed, and sync agents from the registry to target repos. Use when adding a new agent to the fleet, syncing agents across repos, auditing what agents are deployed where, or rebuilding the agent registry. Triggers on "sync agents", "deploy agents", "what agents are deployed", "add agent to repo", "agent fleet", "update agents".
compatibility: Designed for Claude Code at Mad House. Requires ~/dev/mad-house/skills/agents/ as the central registry and gh CLI for repo operations.
allowed-tools: Bash Read Write Edit
disable_model_invocation: true
---

# Agent Fleet

Manages the Mad House agent fleet. The central registry lives at `~/dev/mad-house/skills/agents/`. Agents sync from there into `.github/agents/` of target repos.

## Step 1 — Collect fleet state

```bash
~/.claude/commands/agent-fleet/scripts/collect-fleet.sh
```

## Step 2 — Synthesize

From the script output:

### Registry
List every agent in `~/dev/mad-house/skills/agents/` with its name and one-line description (from the `description:` frontmatter field).

### Deployment State
For each active mad-house repo found, show which registry agents are present in `.github/agents/` and which are missing.

Present as a table:

| Agent | Registry | repo-a | repo-b | repo-c |
|-------|----------|--------|--------|--------|
| coder | yes | deployed | missing | - |

### Gaps
Flag any repo that has zero agents deployed. Flag any agent that exists in a repo but not in the registry (orphaned).

## Step 3 — Act on user intent

**If the user wants to sync all agents to a specific repo:**
Copy every agent from `~/dev/mad-house/skills/agents/` to `~/dev/<repo>/.github/agents/`, then commit and push that repo.

**If the user wants to add a new agent to the registry:**
Write the agent file to `~/dev/mad-house/skills/agents/<name>.agent.md`, then ask if it should be synced anywhere immediately.

**If the user wants to remove a stale agent from a repo:**
Delete the file from `.github/agents/` in that repo and commit.

## Agent file format

```markdown
---
name: Agent Name
description: When to use this agent and what it does.
tools: [read, search, execute, edit, todo, agent]
user-invocable: true
argument-hint: What to pass as an argument.
---

Agent instructions here.
```
