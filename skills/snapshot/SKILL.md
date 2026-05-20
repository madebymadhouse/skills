---
name: snapshot
description: Take a visual screenshot of the Windows screen and read it. Claude can see and analyze whatever is currently displayed -- the Overseer TUI, a terminal, an error, anything. Use when asked to see the current state of the screen, debug a TUI, analyze what's displayed, or verify something visually.
allowed-tools: Bash Read
disable_model_invocation: false
triggers:
  - "take a screenshot"
  - "snapshot"
  - "what's on screen"
  - "take a snap"
  - "show me the screen"
  - "what does the TUI look like"
  - "what's wrong with the TUI"
  - "screenshot the overseer"
  - "capture the screen"
  - "look at the screen"
  - "what am I seeing"
---

# Snapshot

Take a visual screenshot of the Windows screen and analyze it.

## Capture

```bash
bash ~/.claude/commands/snapshot/scripts/win-snap.sh
```

The script saves the screenshot to `/tmp/snap.png`.

If PowerShell is unavailable, fall back to terminal text:

```bash
bash ~/.claude/commands/snapshot/scripts/tmux-snap.sh
```

## Read and analyze

After capture, read the image:

```
Read /tmp/snap.png
```

Then describe what you see. Be specific:
- What application is open / what terminal content is visible
- Any errors, warnings, or unexpected state
- What looks correct and what looks wrong
- Concrete next step if something needs fixing

## For Overseer TUI specifically

Look for:
- Status line content (provider, tokens, elapsed time)
- Any error messages or stack traces
- Whether the TUI is rendering correctly (no garbled output)
- Model name displayed vs expected model
