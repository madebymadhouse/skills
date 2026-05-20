#!/usr/bin/env bash
# Capture current tmux pane content as text. Fallback when PowerShell is unavailable.
set -uo pipefail

OUTPUT="/tmp/snap.txt"

if ! command -v tmux &>/dev/null; then
  echo "ERROR: tmux not available"
  exit 1
fi

# Try to capture the current active pane, else the first available
if tmux capture-pane -p 2>/dev/null | grep -q .; then
  tmux capture-pane -p > "$OUTPUT"
  echo "terminal text captured to $OUTPUT"
else
  # List sessions and give context
  {
    echo "=== tmux sessions ==="
    tmux list-sessions 2>/dev/null || echo "(no sessions)"
    echo ""
    echo "=== first pane content ==="
    tmux capture-pane -p -t 0 2>/dev/null || echo "(no pane 0)"
  } > "$OUTPUT"
  echo "terminal context captured to $OUTPUT"
fi

echo "Read $OUTPUT to see the terminal content"
