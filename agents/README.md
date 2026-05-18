# Agent Registry

Central registry for the Mad House agent fleet.

Agent files live here as `<name>.agent.md`. The `agent-fleet` skill syncs them to `.github/agents/` in target repos.

## Format

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
