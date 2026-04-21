#!/usr/bin/env bash
# remember.sh — Unified memory surface (remember / recall / doctor)
#
# Principle: 3 memory layers stay (they serve different purposes), but the user
# only deals with ONE command. A lightweight router decides where the note goes.
#
# Layers (unchanged physical storage):
#   (A) semantic  — .sdlc/memory/semantic-memory.sqlite3 + team JSONL
#                   → decisions, rationales, QA notes, cross-cutting context
#   (B) module    — .sdlc/module/contracts/{api,data,events,dependencies}.yaml
#                   → API / schema / event / dependency facts for THIS module
#   (C) shared    — .sdlc/memory/shared/*.md
#                   → cross-team files: service-registry, dependency-graph, etc.
#
# Commands:
#   sdlc remember "<text>" [--to=semantic|module|shared] [--kind=api|data|events|deps|decision|note]
#   sdlc recall  "<query>" [--scope=all|this|cross] [--limit=10]
#   sdlc memory doctor [--fix]     # deprecate empty .sdlc/module-kb/, verify layout
#
# Examples:
#   sdlc remember "POST /v1/photos requires X-Tenant-Id header"      # → module/api
#   sdlc remember "Decided: use Redis for session store" --kind=decision # → semantic
#   sdlc remember "tejsecurity depends on TejAuthService /token"     # → shared/deps
#   sdlc recall  "photo upload limits"                                # → federated

set -eo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[mem]${NC} $*"; }
ok()   { echo -e "${GREEN}[mem]${NC} $*"; }
warn() { echo -e "${YELLOW}[mem]${NC} $*"; }
err()  { echo -e "${RED}[mem]${NC} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

SUB="${1:-help}"; shift 2>/dev/null || true

# ── auto-route heuristic ─────────────────────────────────────────────────────
# Classifies free text into (layer, kind). Explicit --to / --kind always wins.
# Lightweight keyword rules — no LLM call on the hot path.
classify() {
  local txt="$1"
  local lc
  lc="$(echo "$txt" | tr '[:upper:]' '[:lower:]')"

  # Shared / cross-module dependency — MUST run before API/data keywords
  # because "depends on <svc> endpoint" should not be routed to module:api.
  if echo "$lc" | grep -Eq '\bdepends on|cross-pod|cross-team|service-registry\b'; then
    echo "shared:deps"; return
  fi

  # Module / API
  if echo "$lc" | grep -Eq '\b(get|post|put|delete|patch) +/'; then
    echo "module:api"; return
  fi
  if echo "$lc" | grep -Eq '\bendpoint|route|header|status code|openapi|swagger\b'; then
    echo "module:api"; return
  fi

  # Module / data
  if echo "$lc" | grep -Eq '\bschema|migration|table|column|foreign key|index|constraint\b'; then
    echo "module:data"; return
  fi

  # Module / events
  if echo "$lc" | grep -Eq '\bkafka|topic|event|publisher|consumer|queue|pubsub|rabbit\b'; then
    echo "module:events"; return
  fi

  # Decisions / ADR
  if echo "$lc" | grep -Eq '\bdecided|decision|rationale|adr|chose|picked|will use|will not use\b'; then
    echo "semantic:decision"; return
  fi

  # Default: free-form note → semantic
  echo "semantic:note"
}

# ── remember ─────────────────────────────────────────────────────────────────
cmd_remember() {
  local text=""
  local explicit_to=""
  local explicit_kind=""
  local yes=0

  # First positional = text
  if [[ -n "${1:-}" && ! "$1" =~ ^-- ]]; then
    text="$1"; shift
  fi

  for arg in "$@"; do
    case "$arg" in
      --to=*)   explicit_to="${arg#--to=}" ;;
      --kind=*) explicit_kind="${arg#--kind=}" ;;
      --yes|-y) yes=1 ;;
      --text=*) text="${arg#--text=}" ;;
    esac
  done

  if [[ -z "$text" ]]; then
    err "Usage: sdlc remember \"<text>\" [--to=semantic|module|shared] [--kind=api|data|events|deps|decision|note]"
    return 2
  fi

  local layer kind
  if [[ -n "$explicit_to" && -n "$explicit_kind" ]]; then
    layer="$explicit_to"; kind="$explicit_kind"
  else
    local cls; cls="$(classify "$text")"
    layer="${explicit_to:-${cls%%:*}}"
    kind="${explicit_kind:-${cls##*:}}"
  fi

  log "Routing → layer=$layer  kind=$kind"
  if [[ $yes -eq 0 ]] && [[ -t 0 ]]; then
    read -r -p "Confirm save? [Y/n/s=switch layer] " ans
    case "$ans" in
      n|N) warn "Cancelled."; return 1 ;;
      s|S)
        read -r -p "New layer (semantic|module|shared): " layer
        read -r -p "New kind  (api|data|events|deps|decision|note): " kind
        ;;
    esac
  fi

  case "$layer" in
    semantic)
      local sem="$PLATFORM_DIR/scripts/semantic-memory.py"
      if [[ ! -f "$sem" ]]; then err "semantic-memory.py not found"; return 1; fi
      local py; py="$(command -v python3 || command -v python || true)"
      [[ -z "$py" ]] && { err "python3 required for semantic layer"; return 1; }
      "$py" "$sem" upsert --text "$text" --namespace "$kind" || return 1
      ok "Saved to semantic memory (namespace=$kind)"
      ;;
    module)
      local mod="$REPO_ROOT/.sdlc/module"
      if [[ ! -d "$mod" ]]; then
        err "No .sdlc/module/ in $REPO_ROOT. Run 'sdlc module init' first."
        return 1
      fi
      local yaml
      case "$kind" in
        api)     yaml="$mod/contracts/api.yaml" ;;
        data)    yaml="$mod/contracts/data.yaml" ;;
        events)  yaml="$mod/contracts/events.yaml" ;;
        deps)    yaml="$mod/contracts/dependencies.yaml" ;;
        *)       yaml="$mod/knowledge/notes.md" ;;
      esac
      mkdir -p "$(dirname "$yaml")"
      {
        echo ""
        echo "# remembered $(date -u +%Y-%m-%dT%H:%M:%SZ) by ${USER:-unknown}"
        echo "# kind: $kind"
        if [[ "$yaml" == *.md ]]; then
          echo "- $text"
        else
          echo "# $text"
        fi
      } >> "$yaml"
      ok "Appended to $yaml"
      log "Review + normalize via 'sdlc module update' when you commit."
      ;;
    shared)
      local sh="$REPO_ROOT/.sdlc/memory/shared"
      mkdir -p "$sh"
      local file
      case "$kind" in
        deps)    file="$sh/cross-team-dependencies.md" ;;
        *)       file="$sh/notes.md" ;;
      esac
      {
        echo ""
        echo "## $(date -u +%Y-%m-%dT%H:%M:%SZ) — $(basename "$REPO_ROOT")"
        echo "- $text"
      } >> "$file"
      ok "Appended to $file"
      log "Publish to team via 'sdlc memory publish' (or let pre-commit hook do it)."
      ;;
    *)
      err "Unknown layer: $layer (use semantic|module|shared)"
      return 2
      ;;
  esac
}

# ── recall (federated read) ──────────────────────────────────────────────────
cmd_recall() {
  local query=""
  local scope="all"
  local limit=10

  if [[ -n "${1:-}" && ! "$1" =~ ^-- ]]; then query="$1"; shift; fi
  for arg in "$@"; do
    case "$arg" in
      --scope=*) scope="${arg#--scope=}" ;;
      --limit=*) limit="${arg#--limit=}" ;;
      --query=*) query="${arg#--query=}" ;;
    esac
  done

  if [[ -z "$query" ]]; then
    err "Usage: sdlc recall \"<query>\" [--scope=all|this|cross] [--limit=N]"
    return 2
  fi

  echo ""
  log "recall: \"$query\"  scope=$scope  limit=$limit"
  echo ""

  # (A) semantic
  if [[ "$scope" == "all" || "$scope" == "this" ]]; then
    local sem="$PLATFORM_DIR/scripts/semantic-memory.py"
    local py; py="$(command -v python3 || command -v python || true)"
    if [[ -f "$sem" && -n "$py" ]]; then
      echo "── semantic memory ──"
      "$py" "$sem" query --text "$query" --limit "$limit" 2>/dev/null || echo "  (empty or error)"
      echo ""
    fi
  fi

  # (B) module (this repo only — distributed principle)
  if [[ "$scope" == "all" || "$scope" == "this" ]]; then
    local mod="$REPO_ROOT/.sdlc/module"
    if [[ -d "$mod" ]]; then
      echo "── module ($(basename "$REPO_ROOT")) ──"
      # grep in YAML + knowledge md; tiny context
      grep -rniH --include="*.yaml" --include="*.md" "$query" "$mod" 2>/dev/null | head -n "$limit" || echo "  (no matches)"
      echo ""
    fi
  fi

  # (C) shared — cross-module read (latest main/dev, per trust model)
  if [[ "$scope" == "all" || "$scope" == "cross" ]]; then
    local sh="$REPO_ROOT/.sdlc/memory/shared"
    if [[ -d "$sh" ]]; then
      echo "── shared / cross-team ──"
      grep -rniH --include="*.md" "$query" "$sh" 2>/dev/null | head -n "$limit" || echo "  (no matches)"
      echo ""
    fi
  fi
}

# ── doctor: clean up dead module-kb folders + sanity-check layout ───────────
cmd_doctor() {
  local fix=0
  for arg in "$@"; do [[ "$arg" == "--fix" ]] && fix=1; done

  local root="$REPO_ROOT"
  log "Doctor checking: $root"
  local issues=0

  # Dead .sdlc/module-kb/
  if [[ -d "$root/.sdlc/module-kb" ]]; then
    if [[ -z "$(ls -A "$root/.sdlc/module-kb" 2>/dev/null)" ]]; then
      warn "Found deprecated empty folder: .sdlc/module-kb/"
      issues=$((issues+1))
      if [[ $fix -eq 1 ]]; then
        rmdir "$root/.sdlc/module-kb" && ok "Removed .sdlc/module-kb/"
      else
        log "Run with --fix to remove."
      fi
    else
      warn "Found .sdlc/module-kb/ with contents — investigate manually before deletion."
      issues=$((issues+1))
    fi
  fi

  # Module system present?
  if [[ ! -f "$root/.sdlc/module/meta.json" ]]; then
    warn "No .sdlc/module/meta.json — run 'sdlc module init' to initialize module KB."
    issues=$((issues+1))
  fi

  # Semantic memory scaffolded?
  if [[ ! -d "$root/.sdlc/memory" ]]; then
    warn "No .sdlc/memory/ — run 'sdlc setup' or 'sdlc workspace init'."
    issues=$((issues+1))
  fi

  if [[ $issues -eq 0 ]]; then
    ok "No issues. Memory layout clean."
    return 0
  fi
  log "Total issues: $issues"
  return 1
}

case "$SUB" in
  remember) cmd_remember "$@" ;;
  recall)   cmd_recall "$@" ;;
  doctor)   cmd_doctor "$@" ;;
  help|--help|-h)
    sed -n '3,22p' "${BASH_SOURCE[0]}" | sed 's/^# //; s/^#//'
    ;;
  *)
    err "Unknown: $SUB (use remember|recall|doctor)"
    exit 2
    ;;
esac
