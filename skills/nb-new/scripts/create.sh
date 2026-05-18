#!/usr/bin/env bash
# nb-new/scripts/create.sh
# Creates a new Jupyter notebook in ~/dev/mad-house/how-to/
set -euo pipefail

HOW_TO_ROOT="${HOME}/dev/mad-house/how-to"
NB_PATH="${NB_PATH:-}"
NB_TITLE="${NB_TITLE:-Untitled}"

if [[ -z "$NB_PATH" ]]; then
  echo '{"created":false,"error":"NB_PATH is required"}' >&1
  exit 1
fi

# Strip trailing slash, extract filename
NB_PATH="${NB_PATH%/}"
NB_DIR="${HOW_TO_ROOT}/$(dirname "$NB_PATH")"
NB_BASENAME="$(basename "$NB_PATH")"
NB_FILE="${NB_DIR}/${NB_BASENAME}.ipynb"

mkdir -p "$NB_DIR"

if [[ -f "$NB_FILE" ]]; then
  python3 -c "import json; print(json.dumps({'created':False,'error':'file already exists','path':'${NB_PATH}.ipynb','abs_path':'${NB_FILE}'}))"
  exit 0
fi

# Generate a short unique id prefix
ID_PREFIX=$(python3 -c "import uuid; print(uuid.uuid4().hex[:8])")

python3 - <<PYEOF
import json, sys

title = """${NB_TITLE}"""
id1 = "${ID_PREFIX}0001"
id2 = "${ID_PREFIX}0002"
nb_file = "${NB_FILE}"
nb_path = "${NB_PATH}.ipynb"

notebook = {
    "nbformat": 4,
    "nbformat_minor": 5,
    "metadata": {
        "kernelspec": {
            "display_name": "Python 3",
            "language": "python",
            "name": "python3"
        },
        "language_info": {
            "name": "python",
            "version": "3.11.0"
        }
    },
    "cells": [
        {
            "cell_type": "markdown",
            "id": id1,
            "metadata": {},
            "source": f"# {title}\n\n_Add introduction here._"
        },
        {
            "cell_type": "markdown",
            "id": id2,
            "metadata": {},
            "source": "## Section 1\n\n_Add content here._"
        }
    ]
}

with open(nb_file, "w") as f:
    json.dump(notebook, f, indent=1)

print(json.dumps({"created": True, "path": nb_path, "abs_path": nb_file}))
PYEOF
