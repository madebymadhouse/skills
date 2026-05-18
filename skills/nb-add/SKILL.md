---
name: nb-add
description: Add a new cell (markdown or code) to an existing Jupyter notebook in the
  how-to repo. Use when the user wants to extend an existing notebook with a new section,
  example, or code block. Triggers on "add a section to", "extend the notebook", "add
  cell to", "add content to the notebook".
allowed-tools: Bash, Read
---

# nb-add

Appends a new cell to an existing `.ipynb` without breaking the JSON structure.

## Tools

### scripts/add_cell.sh
Appends a new cell to an existing notebook.
- Input: `NB_ABS_PATH=<absolute path to .ipynb>`
- Input: `CELL_TYPE=markdown|code` (default: markdown)
- Input: `CELL_CONTENT=<cell source text>`
- Output: `{appended: bool, path: string, cell_count: int}`

## Workflow

1. Identify the target notebook (ask if ambiguous)
2. Determine cell type and content from user request
3. Run `NB_ABS_PATH="..." CELL_TYPE="..." CELL_CONTENT="..." bash scripts/add_cell.sh`
4. Report success and new cell count

## Notes

- Markdown cells accept GFM
- Code cells default to Python
- The cell is always appended at the end. Use nb-add multiple times to add several cells.
