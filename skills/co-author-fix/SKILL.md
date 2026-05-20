---
name: co-author-fix
description: Check whether the last git commit in the current repo has the Claude
  co-author trailer. If missing, amend it. Triggers on "add co-author", "fix co-author",
  "missing co-author", "add claude to commit", "co-author trailer".
allowed-tools: Bash
disable_model_invocation: true
---

# co-author-fix

Every commit made during a Claude session should have the co-author trailer.
This skill checks and repairs the last commit if it is missing.

## Tools

### scripts/fix.sh
Checks the last commit for the co-author trailer. Amends if missing.
- Input: `REPO_PATH=<absolute path>` (default: current directory)
- Output: `{had_trailer: bool, amended: bool, commit_hash: string, message_preview: string}`

## Workflow

1. Run `bash scripts/fix.sh`
2. If `had_trailer: true` - report "already present", done
3. If `amended: true` - report the amended hash
4. If the commit is already pushed, warn that the amend requires a force-push

## Co-author format

```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Git trailers require a blank line between the message body and the trailer block.
