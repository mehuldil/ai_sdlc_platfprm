#!/usr/bin/env bash
# ado-mac.sh — Lightweight ADO helper for macOS / Linux (no full sdlc setup needed)
# No admin required. Needs: bash, curl (built into macOS/Linux).
#
# USAGE (from repo root):
#   bash scripts/ado-mac.sh description 863476 --file=stories/MS-FamilyHub-Phase1.md
#   bash scripts/ado-mac.sh show       863476
#   bash scripts/ado-mac.sh comment    863476 "Approved"
#   bash scripts/ado-mac.sh update     863476 --state=Active
#   bash scripts/ado-mac.sh push-story stories/SS-FamilyHub-01.md [--parent=863476]
#   bash scripts/ado-mac.sh list       [--type="User Story"]
#   bash scripts/ado-mac.sh link       863476 863480

set -euo pipefail

# ── Load ADO credentials (repo env/.env, then ~/.sdlc/ado.env) ───────────────
_load_env() {
  local dir="$PWD"
  for _ in 1 2 3 4 5; do
    if [[ -f "$dir/env/.env" ]]; then
      # shellcheck disable=SC1090
      set -a; source "$dir/env/.env"; set +a
      return 0
    fi
    dir="$(dirname "$dir")"
    [[ "$dir" == "/" ]] && break
  done
  if [[ -n "${SDL_AZURE_DEVOPS_ENV_FILE:-}" && -f "${SDL_AZURE_DEVOPS_ENV_FILE}" ]]; then
    set -a; source "${SDL_AZURE_DEVOPS_ENV_FILE}"; set +a
    return 0
  fi
  if [[ -f "${HOME}/.sdlc/ado.env" ]]; then
    set -a; source "${HOME}/.sdlc/ado.env"; set +a
    return 0
  fi
  echo "WARN: env/.env not found — set ADO_PAT, ADO_ORG, ADO_PROJECT in repo env/.env or ~/.sdlc/ado.env" >&2
}
_load_env

ADO_PAT="${ADO_PAT:-}"
ADO_ORG="${ADO_ORG:-}"
ADO_PROJECT="${ADO_PROJECT:-}"

_assert_creds() {
  if [[ -z "$ADO_PAT" || -z "$ADO_ORG" || -z "$ADO_PROJECT" ]]; then
    echo "ERROR: ADO_PAT, ADO_ORG, ADO_PROJECT must be set in env/.env" >&2; exit 1
  fi
}

# ── HTTP helpers ───────────────────────────────────────────────────────────────
_ado_curl() {
  curl -s -u ":${ADO_PAT}" "$@"
}

_wi_url() { echo "https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${1}?api-version=7.0"; }

_check_success() {
  local raw="$1" wiId="$2"
  if echo "$raw" | grep -q "\"id\".*$wiId\|\"id\":$wiId"; then
    local rev; rev=$(echo "$raw" | grep -o '"rev":[0-9]*' | head -1 | tr -dc '0-9')
    echo "SUCCESS — WI $wiId updated (rev $rev)"
  elif echo "$raw" | grep -q '"message"'; then
    echo "ADO ERROR: $(echo "$raw" | grep -o '"message":"[^"]*"')" >&2
  else
    echo "$raw" | head -c 600 >&2
  fi
}

_json_escape() {
  # Minimal JSON string escaping using Python if available, else sed
  if command -v python3 &>/dev/null; then
    python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$1"
  else
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//'
    # wrap in quotes handled by caller
  fi
}

# ── Markdown → HTML ────────────────────────────────────────────────────────────
_md_to_html() {
  # Uses awk for portability — no Python/pandoc needed
  awk '
  BEGIN { in_ul=0; in_table=0; first_row=1 }

  /^---+$/ {
    if(in_ul)    { print "</ul>"; in_ul=0 }
    if(in_table) { print "</table>"; in_table=0 }
    print "<hr/>"; next
  }

  /^#{1,6} / {
    if(in_ul)    { print "</ul>"; in_ul=0 }
    if(in_table) { print "</table>"; in_table=0 }
    match($0, /^(#+) (.*)/, a)
    n=length(a[1]); txt=a[2]
    printf "<h%d>%s</h%d>\n", n, txt, n; next
  }

  /^\|/ {
    if(in_ul) { print "</ul>"; in_ul=0 }
    if(!in_table) { print "<table border=\"1\" cellpadding=\"4\" style=\"border-collapse:collapse\">"; in_table=1; first_row=1 }
    # skip separator rows
    if($0 ~ /^\|[-: |]+\|$/) next
    tag = first_row ? "th" : "td"; first_row=0
    n=split($0, cells, "|")
    printf "<tr>"
    for(i=2; i<n; i++) { gsub(/^ +| +$/, "", cells[i]); printf "<%s>%s</%s>", tag, cells[i], tag }
    print "</tr>"; next
  }

  /^[-*] / || /^  [-*] / {
    if(in_table) { print "</table>"; in_table=0 }
    if(!in_ul)   { print "<ul>"; in_ul=1 }
    sub(/^[ ]*[-*] /, ""); print "<li>" $0 "</li>"; next
  }

  /^$/ {
    if(in_ul)    { print "</ul>"; in_ul=0 }
    if(in_table) { print "</table>"; in_table=0 }
    next
  }

  {
    if(in_table) { print "</table>"; in_table=0 }
    if(in_ul)    { print "</ul>"; in_ul=0 }
    print "<p>" $0 "</p>"
  }

  END {
    if(in_ul)    print "</ul>"
    if(in_table) print "</table>"
  }
  ' "$1" | \
  sed 's/\*\*\([^*]*\)\*\*/<strong>\1<\/strong>/g' | \
  sed 's/`\([^`]*\)`/<code>\1<\/code>/g' | \
  sed 's/\[\([^]]*\)\](\([^)]*\))/<a href="\2">\1<\/a>/g'
}

_build_patch_json() {
  local field="$1" value="$2"
  if command -v python3 &>/dev/null; then
    python3 -c "
import json,sys
field=sys.argv[1]; value=open(sys.argv[2]).read()
print(json.dumps([{'op':'add','path':'/fields/'+field,'value':value}]))
" "$field" "$value"
  else
    local esc; esc=$(printf '%s' "$(cat "$value")" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
    echo "[{\"op\":\"add\",\"path\":\"/fields/${field}\",\"value\":\"${esc}\"}]"
  fi
}

# ── Commands ───────────────────────────────────────────────────────────────────
cmd_show() {
  _assert_creds
  local wiId="$1"
  echo "Fetching WI $wiId…"
  local raw; raw=$(_ado_curl "$(_wi_url "$wiId")")
  local title state wtype
  title=$(echo "$raw" | grep -o '"System.Title":"[^"]*"' | cut -d'"' -f4)
  state=$(echo "$raw" | grep -o '"System.State":"[^"]*"' | cut -d'"' -f4)
  wtype=$(echo "$raw" | grep -o '"System.WorkItemType":"[^"]*"' | cut -d'"' -f4)
  echo "ID:    $wiId"
  echo "Type:  $wtype"
  echo "State: $state"
  echo "Title: $title"
  echo "URL:   https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_workitems/edit/$wiId"
}

cmd_description() {
  _assert_creds
  local wiId="$1" filePath="$2"
  [[ -z "$filePath" || ! -f "$filePath" ]] && { echo "ERROR: file not found: $filePath" >&2; exit 1; }
  echo "Converting '$filePath' to HTML…"
  local tmpHtml; tmpHtml=$(mktemp /tmp/ado-html-XXXXXX.html)
  _md_to_html "$filePath" > "$tmpHtml"
  echo "HTML: $(wc -c < "$tmpHtml") bytes — building JSON…"
  local tmpJson; tmpJson=$(mktemp /tmp/ado-body-XXXXXX.json)
  _build_patch_json "System.Description" "$tmpHtml" > "$tmpJson"
  echo "Sending to ADO…"
  local raw; raw=$(_ado_curl -X PATCH \
    -H "Content-Type: application/json-patch+json" \
    --data-binary "@$tmpJson" \
    "$(_wi_url "$wiId")")
  rm -f "$tmpHtml" "$tmpJson"
  _check_success "$raw" "$wiId"
}

cmd_comment() {
  _assert_creds
  local wiId="$1" text="$2"
  [[ -z "$text" ]] && { echo "Usage: ado-mac.sh comment <id> <text>" >&2; exit 1; }
  local tmpJson; tmpJson=$(mktemp /tmp/ado-body-XXXXXX.json)
  echo "$text" > "$tmpJson.txt"
  _build_patch_json "System.History" "$tmpJson.txt" > "$tmpJson"
  local raw; raw=$(_ado_curl -X PATCH \
    -H "Content-Type: application/json-patch+json" \
    --data-binary "@$tmpJson" \
    "$(_wi_url "$wiId")")
  rm -f "$tmpJson" "$tmpJson.txt"
  _check_success "$raw" "$wiId"
}

cmd_update() {
  _assert_creds
  local wiId="$1" stateVal="$2"
  [[ -z "$stateVal" ]] && { echo "Usage: ado-mac.sh update <id> --state=<state>" >&2; exit 1; }
  local tmpJson; tmpJson=$(mktemp /tmp/ado-body-XXXXXX.json)
  echo "$stateVal" > "$tmpJson.txt"
  _build_patch_json "System.State" "$tmpJson.txt" > "$tmpJson"
  local raw; raw=$(_ado_curl -X PATCH \
    -H "Content-Type: application/json-patch+json" \
    --data-binary "@$tmpJson" \
    "$(_wi_url "$wiId")")
  rm -f "$tmpJson" "$tmpJson.txt"
  _check_success "$raw" "$wiId"
}

cmd_push_story() {
  _assert_creds
  local filePath="$1" parentId="${2:-}"
  local wi_kind="${3:-story}"
  wi_kind=$(printf '%s' "$wi_kind" | tr '[:upper:]' '[:lower:]')
  [[ -z "$filePath" || ! -f "$filePath" ]] && { echo "ERROR: file not found: $filePath" >&2; exit 1; }
  local storyTitle; storyTitle=$(grep '^# ' "$filePath" | head -1 | sed 's/^#* //')
  [[ -z "$storyTitle" ]] && storyTitle="$(basename "$filePath" .md)"
  echo "Creating work item ($wi_kind): $storyTitle"
  local tmpHtml tmpJson
  tmpHtml=$(mktemp /tmp/ado-html-XXXXXX.html)
  tmpJson=$(mktemp /tmp/ado-body-XXXXXX.json)
  _md_to_html "$filePath" > "$tmpHtml"
  local htmlContent; htmlContent=$(cat "$tmpHtml")
  if command -v python3 &>/dev/null; then
    python3 -c "
import json,sys
title=sys.argv[1]; html=open(sys.argv[2]).read(); parent=sys.argv[3]
patch=[{'op':'add','path':'/fields/System.Title','value':title},
       {'op':'add','path':'/fields/System.Description','value':html}]
if parent:
    patch.append({'op':'add','path':'/relations/-','value':{
        'rel':'System.LinkTypes.Hierarchy-Reverse',
        'url':'https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_apis/wit/workitems/'+parent}})
print(json.dumps(patch))
" "$storyTitle" "$tmpHtml" "$parentId" > "$tmpJson"
  else
    echo "[{\"op\":\"add\",\"path\":\"/fields/System.Title\",\"value\":\"$storyTitle\"}]" > "$tmpJson"
  fi
  local wi_suffix='$User%20Story'
  case "$wi_kind" in
    feature) wi_suffix='$Feature' ;;
    epic)    wi_suffix='$Epic' ;;
    story|*) wi_suffix='$User%20Story' ;;
  esac
  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${wi_suffix}?api-version=7.0"
  local raw; raw=$(_ado_curl -X POST \
    -H "Content-Type: application/json-patch+json" \
    --data-binary "@$tmpJson" "$url")
  rm -f "$tmpHtml" "$tmpJson"
  local newId; newId=$(echo "$raw" | grep -o '"id":[0-9]*' | head -1 | tr -dc '0-9')
  if [[ -n "$newId" ]]; then
    echo "SUCCESS — Created WI $newId: $storyTitle"
    echo "URL: https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_workitems/edit/$newId"
  else
    echo "$raw" | head -c 600 >&2
  fi
}

cmd_help() {
  cat <<'EOF'
ado-mac.sh — Lightweight ADO helper for macOS / Linux
No admin required. Needs: bash, curl (both built in on macOS).
Reads env/.env automatically.

COMMANDS
  description <id> --file=<path.md>   Update WI description from markdown file
  show        <id>                     Show WI title, state, URL
  comment     <id> <text>             Add comment
  update      <id> --state=<state>    Change state (Active, Resolved, Closed…)
  push-story  <file.md> [--parent=id] [--type=story|feature|epic]  Create WI from markdown (default: User Story)
  link        <id1> <id2>             Link id2 as parent of id1

EXAMPLES
  bash scripts/ado-mac.sh description 863476 --file=stories/MS-FamilyHub-Phase1.md
  bash scripts/ado-mac.sh show 863476
  bash scripts/ado-mac.sh comment 863476 "Reviewed OK"
  bash scripts/ado-mac.sh update 863476 --state=Active
  bash scripts/ado-mac.sh push-story stories/SS-01.md --parent=863476
  bash scripts/ado-mac.sh push-story stories/MS-scope.md --type=feature
EOF
}

# ── Parse args & dispatch ──────────────────────────────────────────────────────
CMD="${1:-help}"; shift || true
POSITIONAL=(); FILE=""; STATE=""; PARENT=""; TYPE="story"

for arg in "$@"; do
  case "$arg" in
    --file=*)   FILE="${arg#--file=}" ;;
    --state=*)  STATE="${arg#--state=}" ;;
    --parent=*) PARENT="${arg#--parent=}" ;;
    --type=*)   TYPE="${arg#--type=}" ;;
    *)          POSITIONAL+=("$arg") ;;
  esac
done

case "$CMD" in
  show)        cmd_show "${POSITIONAL[0]:-}" ;;
  description) cmd_description "${POSITIONAL[0]:-}" "${FILE:-${POSITIONAL[1]:-}}" ;;
  comment)     cmd_comment "${POSITIONAL[0]:-}" "${POSITIONAL[1]:-}" ;;
  update)      cmd_update "${POSITIONAL[0]:-}" "$STATE" ;;
  push-story)  cmd_push_story "${FILE:-${POSITIONAL[0]:-}}" "$PARENT" "$TYPE" ;;
  link)        echo "Not yet implemented — use sdlc ado link" ;;
  help|--help) cmd_help ;;
  *)           echo "Unknown command: $CMD" >&2; cmd_help; exit 1 ;;
esac
