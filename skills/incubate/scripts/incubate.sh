#!/bin/bash
# incubate.sh — project lifecycle manager for Mad House
#
# Every project is incubatable: code, games, creative tools, experiments, content, bots.
# No rigid gates. Stages describe where something is, not what it's allowed to be.
#
# Usage:
#   incubate new <name> [--type code|game|creative|tool|experiment|content] [--desc "..."]
#   incubate list [--all]
#   incubate stage <name> <concept|prototype|building|shipped|maintained|archived>
#   incubate promote <name> [--org madebymadhouse|orinadus-systems|samhcharles] [--public]
#   incubate ship <name>
#   incubate archive <name> [--reason "..."]
#   incubate info <name>

set -euo pipefail

LAB_ROOT="$HOME/dev/mad-house/lab"
DEFAULT_ORG="madebymadhouse"

STAGES=("concept" "prototype" "building" "shipped" "maintained" "archived")
TYPES=("code" "game" "creative" "tool" "experiment" "content" "bot")

# Stage label colors (GitHub hex, no #)
declare -A STAGE_COLORS=(
  [concept]="c5def5"
  [prototype]="e4e669"
  [building]="f9d0c4"
  [shipped]="0e8a16"
  [maintained]="006b75"
  [archived]="cfd3d7"
)

# Stage label descriptions
declare -A STAGE_DESCS=(
  [concept]="Idea captured, not yet started"
  [prototype]="Early exploration, proof of concept"
  [building]="Active development"
  [shipped]="Live and usable by someone"
  [maintained]="Stable, receiving updates as needed"
  [archived]="Retired gracefully"
)

usage() {
  echo "incubate — project lifecycle manager"
  echo ""
  echo "Commands:"
  echo "  new <name>         Capture a new project in the lab"
  echo "  list [--all]       Show active incubations (--all includes archived)"
  echo "  stage <name> <s>   Move to: concept|prototype|building|shipped|maintained|archived"
  echo "  promote <name>     Create GitHub repo from lab project"
  echo "  ship <name>        Mark shipped, print ship checklist"
  echo "  archive <name>     Retire gracefully"
  echo "  info <name>        Show full metadata"
  echo ""
  echo "Options for 'new':"
  echo "  --type  code|game|creative|tool|experiment|content|bot"
  echo "  --desc  One-line description"
  echo "  --stage Starting stage (default: concept)"
}

# ── helpers ─────────────────────────────────────────────────────────────────

slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-'
}

find_project() {
  local name
  name=$(slug "$1")
  local dir="$LAB_ROOT/$name"
  if [[ ! -d "$dir" ]]; then
    # also check if it only exists on GitHub
    echo ""
    return
  fi
  echo "$dir"
}

read_meta() {
  local dir="$1"
  local field="$2"
  python3 -c "
import sys, json
try:
  d = json.load(open('$dir/metadata.json'))
  print(d.get('$field', ''))
except:
  print('')
" 2>/dev/null
}

write_meta() {
  local dir="$1"
  shift
  local tmp
  tmp=$(mktemp)
  python3 - "$dir" "$@" <<'EOF'
import sys, json, os
from datetime import datetime

path = os.path.join(sys.argv[1], 'metadata.json')
try:
    d = json.load(open(path)) if os.path.exists(path) else {}
except:
    d = {}

args = sys.argv[2:]
i = 0
while i < len(args):
    key = args[i].lstrip('-').replace('-', '_')
    val = args[i+1]
    d[key] = val
    i += 2

d['updated'] = datetime.utcnow().strftime('%Y-%m-%d')
if 'started' not in d:
    d['started'] = d['updated']

print(json.dumps(d, indent=2))
EOF
}

update_meta() {
  local dir="$1"
  shift
  python3 - "$dir/metadata.json" "$@" <<'EOF' > /tmp/meta_new.json
import sys, json, os
from datetime import datetime

path = sys.argv[1]
try:
    d = json.load(open(path)) if os.path.exists(path) else {}
except:
    d = {}

args = sys.argv[2:]
i = 0
while i < len(args):
    key = args[i]
    val = args[i+1]
    d[key] = val
    i += 2

d['updated'] = datetime.utcnow().strftime('%Y-%m-%d')
if 'started' not in d:
    d['started'] = d['updated']

print(json.dumps(d, indent=2))
EOF
  mv /tmp/meta_new.json "$dir/metadata.json"
}

ensure_labels() {
  local repo="$1"
  for stage in "${STAGES[@]}"; do
    local label="stage: $stage"
    local color="${STAGE_COLORS[$stage]}"
    local desc="${STAGE_DESCS[$stage]}"
    gh label create "$label" \
      --color "$color" \
      --description "$desc" \
      --repo "$repo" 2>/dev/null || \
    gh label edit "$label" \
      --color "$color" \
      --description "$desc" \
      --repo "$repo" 2>/dev/null || true
  done
}

# ── commands ─────────────────────────────────────────────────────────────────

cmd_new() {
  local raw_name=""
  local type="experiment"
  local desc=""
  local stage="concept"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --type) type="$2"; shift 2 ;;
      --desc) desc="$2"; shift 2 ;;
      --stage) stage="$2"; shift 2 ;;
      *) raw_name="$1"; shift ;;
    esac
  done

  if [[ -z "$raw_name" ]]; then
    echo "error: name required"
    exit 1
  fi

  local name
  name=$(slug "$raw_name")
  local dir="$LAB_ROOT/$name"

  if [[ -d "$dir" ]]; then
    echo "error: $name already exists at $dir"
    exit 1
  fi

  mkdir -p "$dir"

  python3 - "$dir" "$raw_name" "$type" "$desc" "$stage" <<'EOF'
import sys, json
from datetime import datetime
dir, name, ptype, desc, stage = sys.argv[1:]
today = datetime.utcnow().strftime('%Y-%m-%d')
meta = {
  "name": name,
  "type": ptype,
  "description": desc,
  "stage": stage,
  "org": "",
  "repo": "",
  "public": False,
  "started": today,
  "updated": today,
  "notes": ""
}
json.dump(meta, open(dir + '/metadata.json', 'w'), indent=2)
EOF

  echo "created: $dir"
  echo "stage:   $stage"
  echo "type:    $type"
  [[ -n "$desc" ]] && echo "desc:    $desc"
  echo ""
  echo "next: incubate stage $name prototype  (when you start building)"
}

cmd_list() {
  local show_all=false
  [[ "${1:-}" == "--all" ]] && show_all=true

  printf "%-24s %-12s %-14s %-40s\n" "project" "type" "stage" "description"
  printf "%-24s %-12s %-14s %-40s\n" "-------" "----" "-----" "-----------"

  for dir in "$LAB_ROOT"/*/; do
    [[ -f "$dir/metadata.json" ]] || continue
    local stage type name desc
    stage=$(read_meta "$dir" "stage")
    type=$(read_meta "$dir" "type")
    name=$(read_meta "$dir" "name")
    desc=$(read_meta "$dir" "description")

    [[ "$show_all" == false && "$stage" == "archived" ]] && continue

    printf "%-24s %-12s %-14s %-40s\n" "$name" "$type" "$stage" "${desc:0:40}"
  done
}

cmd_stage() {
  local raw_name="$1"
  local new_stage="${2:-}"

  if [[ -z "$new_stage" ]]; then
    echo "error: stage required. options: ${STAGES[*]}"
    exit 1
  fi

  local valid=false
  for s in "${STAGES[@]}"; do [[ "$s" == "$new_stage" ]] && valid=true; done
  if [[ "$valid" == false ]]; then
    echo "error: invalid stage '$new_stage'. options: ${STAGES[*]}"
    exit 1
  fi

  local name
  name=$(slug "$raw_name")
  local dir="$LAB_ROOT/$name"

  if [[ ! -d "$dir" ]]; then
    echo "error: project not found in lab: $name"
    exit 1
  fi

  local prev_stage
  prev_stage=$(read_meta "$dir" "stage")
  update_meta "$dir" "stage" "$new_stage"

  echo "$name: $prev_stage  ->  $new_stage"

  # Sync to GitHub if repo is wired
  local repo
  repo=$(read_meta "$dir" "repo")
  if [[ -n "$repo" ]]; then
    local prev_label="stage: $prev_stage"
    local new_label="stage: $new_stage"
    ensure_labels "$repo"
    # Update open issues with stage label
    local issues
    issues=$(gh issue list --repo "$repo" --label "$prev_label" --json number --jq '.[].number' 2>/dev/null || echo "")
    for issue in $issues; do
      gh issue edit "$issue" --repo "$repo" --remove-label "$prev_label" --add-label "$new_label" 2>/dev/null || true
    done
    [[ -n "$issues" ]] && echo "updated GitHub issues: $issues"
  fi
}

cmd_promote() {
  local raw_name=""
  local org="$DEFAULT_ORG"
  local public=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --org) org="$2"; shift 2 ;;
      --public) public=true; shift ;;
      *) raw_name="$1"; shift ;;
    esac
  done

  local name
  name=$(slug "$raw_name")
  local dir="$LAB_ROOT/$name"

  if [[ ! -d "$dir" ]]; then
    echo "error: project not found: $name"
    exit 1
  fi

  local desc
  desc=$(read_meta "$dir" "description")

  # Create GitHub repo
  local visibility_flag=""
  [[ "$public" == true ]] && visibility_flag="--public" || visibility_flag="--private"

  gh repo create "$org/$name" $visibility_flag --description "$desc" --confirm 2>/dev/null || \
  gh repo create "$org/$name" $visibility_flag --description "$desc" 2>/dev/null || true

  # Wire remote if lab dir has git
  if [[ -d "$dir/.git" ]]; then
    cd "$dir"
    git remote remove origin 2>/dev/null || true
    git remote add origin "git@github.com:$org/$name.git"
    echo "remote wired: git@github.com:$org/$name.git"
  fi

  # Update metadata
  update_meta "$dir" "org" "$org" "repo" "$org/$name" "public" "$public"
  ensure_labels "$org/$name"

  echo "promoted: $org/$name"
  echo "next: cd $dir && git push -u origin main"
}

cmd_ship() {
  local raw_name="$1"
  local name
  name=$(slug "$raw_name")
  local dir="$LAB_ROOT/$name"

  if [[ -d "$dir" ]]; then
    update_meta "$dir" "stage" "shipped"
  fi

  local project_type="code"
  [[ -d "$dir" ]] && project_type=$(read_meta "$dir" "type")

  echo ""
  echo "shipped: $name"
  echo ""
  echo "ship checklist for type: $project_type"
  echo "─────────────────────────────────────"

  case "$project_type" in
    code|tool|bot)
      echo "  [ ] README covers what it does, how to run it, one example"
      echo "  [ ] Public repo (or confirmed private with reason)"
      echo "  [ ] Works from a clean clone"
      echo "  [ ] Dependabot enabled"
      echo "  [ ] No secrets in git history"
      ;;
    game)
      echo "  [ ] Playable in browser or has a binary download"
      echo "  [ ] Basic instructions visible before play starts"
      echo "  [ ] Deployed URL or itch.io page"
      echo "  [ ] Works on mobile or documents platform requirement"
      ;;
    creative|content)
      echo "  [ ] Published to the intended platform"
      echo "  [ ] Attribution and licensing clear"
      echo "  [ ] Linked from Mad House profile or relevant channel"
      ;;
    experiment)
      echo "  [ ] Result documented (even if null result)"
      echo "  [ ] Repo or gist with the code"
      echo "  [ ] What was learned written down"
      ;;
    *)
      echo "  [ ] Someone else can find and use this"
      echo "  [ ] What it is and how to get it is documented"
      ;;
  esac

  echo ""
  echo "after shipping: incubate stage $name maintained  (or 'archived' if no further work)"
}

cmd_archive() {
  local raw_name=""
  local reason=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --reason) reason="$2"; shift 2 ;;
      *) raw_name="$1"; shift ;;
    esac
  done

  local name
  name=$(slug "$raw_name")
  local dir="$LAB_ROOT/$name"

  if [[ -d "$dir" ]]; then
    update_meta "$dir" "stage" "archived"
    [[ -n "$reason" ]] && update_meta "$dir" "archive_reason" "$reason"
  fi

  local repo
  [[ -d "$dir" ]] && repo=$(read_meta "$dir" "repo") || repo=""
  if [[ -n "$repo" ]]; then
    ensure_labels "$repo"
    echo "note: run 'gh repo archive $repo' if the GitHub repo should be read-only"
  fi

  echo "archived: $name"
  [[ -n "$reason" ]] && echo "reason:   $reason"
  echo ""
  echo "archives are valid outcomes. nothing is wasted."
}

cmd_info() {
  local name
  name=$(slug "$1")
  local dir="$LAB_ROOT/$name"

  if [[ ! -f "$dir/metadata.json" ]]; then
    echo "error: no metadata found for $name"
    exit 1
  fi

  cat "$dir/metadata.json"
}

# ── entry ────────────────────────────────────────────────────────────────────

[[ $# -eq 0 ]] && { usage; exit 0; }

CMD="$1"; shift
case "$CMD" in
  new)      cmd_new "$@" ;;
  list)     cmd_list "$@" ;;
  stage)    cmd_stage "$@" ;;
  promote)  cmd_promote "$@" ;;
  ship)     cmd_ship "$@" ;;
  archive)  cmd_archive "$@" ;;
  info)     cmd_info "$@" ;;
  help|--help|-h) usage ;;
  *)        echo "unknown command: $CMD"; usage; exit 1 ;;
esac
