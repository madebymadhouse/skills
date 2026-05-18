---
name: confirm-gate
description: Surface your interpretation of the task before writing any code or making any changes. Use this at the START of any Build mode task — before opening a single file to edit. Critical when the request contained multiple ideas, was written in fragments, affects more than 2 files, or has any ambiguity about scope. Triggers on "build", "create", "add", "implement", "write", "make", "fix", "update" when the request is non-trivial. Do not skip this step to save time — a wrong interpretation wastes more time than a confirmation.
allowed-tools: Read
user_invocable: false
---

# Confirm Gate

Before touching anything, surface your interpretation. Output exactly this structure and stop:

---

**Mode:** [Plan / Build / Debug / Review — pick one]

**I'm reading this as:** [one sentence — what you think the actual task is, stripped of noise]

**I'll touch:**
- [specific file or component]
- [specific file or component]

**I won't touch:** [anything explicitly out of scope, or "nothing excluded" if full scope]

**First step after confirmation:** [the single next action]

**Ambiguities:** [anything unclear that would change the plan — or "none"]

---

Then stop. Do not proceed until the user responds.

If the user confirms ("yes", "go", "proceed", "looks right") — execute.
If the user corrects anything — update your interpretation and confirm again before proceeding.
If the user says "just do it" — execute but note what assumption you made.
