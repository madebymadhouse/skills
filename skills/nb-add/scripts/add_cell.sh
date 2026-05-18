#!/usr/bin/env bash
# nb-add/scripts/add_cell.sh
# Appends a cell to an existing Jupyter notebook
set -euo pipefail

NB_ABS_PATH="${NB_ABS_PATH:-}"
CELL_TYPE="${CELL_TYPE:-markdown}"
CELL_CONTENT="${CELL_CONTENT:-}"

if [[ -z "$NB_ABS_PATH" || ! -f "$NB_ABS_PATH" ]]; then
  python3 -c "import json; print(json.dumps({'appended':False,'error':'NB_ABS_PATH required and must exist'}))"
  exit 1
fi

export NB_ABS_PATH CELL_TYPE CELL_CONTENT

python3 <<'PYEOF'
import json, os, uuid

nb_path = os.environ["NB_ABS_PATH"]
cell_type = os.environ.get("CELL_TYPE", "markdown")
content = os.environ.get("CELL_CONTENT", "")

with open(nb_path) as f:
    nb = json.load(f)

cell_id = uuid.uuid4().hex[:8]

if cell_type == "code":
    cell = {
        "cell_type": "code",
        "id": cell_id,
        "metadata": {},
        "execution_count": None,
        "outputs": [],
        "source": content
    }
else:
    cell = {
        "cell_type": "markdown",
        "id": cell_id,
        "metadata": {},
        "source": content
    }

nb["cells"].append(cell)

with open(nb_path, "w") as f:
    json.dump(nb, f, indent=1)

print(json.dumps({
    "appended": True,
    "path": nb_path,
    "cell_count": len(nb["cells"]),
    "cell_id": cell_id
}))
PYEOF
