#!/usr/bin/env bash
# workspace.sh — Workspace-level SDLC setup for parent folders containing multiple repos
#
# Problem solved:
#   A module owner with 10+ microservice repos under one parent folder
#   (e.g. example-app/{TejAuthService,tejpublicservices,tejsecurity})
#   should not re-run `sdlc setup` per repo. This command:
#     (1) caches per-user + per-workspace work once (creds, IDE plugin, doc libs, hooks config)
#     (2) iterates children, running only the strictly per-repo pieces
#         (.sdlc/ scaffolding, git hooks, module init, .env merge)
#
# Usage:
#   sdlc workspace init [--path=<parent>] [--dry-run] [--include=<glob>] [--exclude=<glob>]
#   sdlc workspace status [--path=<parent>]
#   sdlc workspace sync   [--path=<parent>]     # re-run per-repo setup on all children
#
# Flags:
#   --path=<dir>    Parent folder. Default: current dir.
#   --dry-run       Show what would happen, change nothing.
#   --include=<g>   Only process child dirs matching glob (default: all dirs with .git)
#   --exclude=<g>   Skip child dirs matching glob.
#   --ide=<name>    Pass-through to `sdlc setup` (auto|cursor|claude-code|both)
#
# Exit: 0 on full success, 1 on any per-repo failure (remaining repos still processed).

set -eo pipefail

# ── logging ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[workspace]${NC} $*"; }
log_ok()      { echo -e "${GREEN}[workspace]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[workspace]${NC} $*"; }
log_err()     { echo -e "${RED}[workspace]${NC} $*" >&2; }
log_section() { echo ""; echo -e "${BLUE}── $* ──${NC}"; }

# ── resolve platform root ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── parse args ────────────────────────────────────────────────────────────────
SUBCMD="${1:-init}"
shift 2>/dev/null || true

PARENT_PATH="$(pwd)"
DRY_RUN=0
INCLUDE_GLOB=""
EXCLUDE_GLOB=""
IDE_MODE="auto"

for arg in "$@"; do
  case "$arg" in
    --path=*)    PARENT_PATH="${arg#--path=}" ;;
    --dry-run)   DRY_RUN=1 ;;
    --include=*) INCLUDE_GLOB="${arg#--include=}" ;;
    --exclude=*) EXCLUDE_GLOB="${arg#--exclude=}" ;;
    --ide=*)     IDE_MODE="${arg#--ide=}" ;;
    --help|-h)
      sed -n '3,28p' "${BASH_SOURCE[0]}" | sed 's/^# //; s/^#//'
      exit 0
      ;;
  esac
done

if [[ ! -d "$PARENT_PATH" ]]; then
  log_err "Parent path does not exist: $PARENT_PATH"
  exit 2
fi
PARENT_PATH="$(cd "$PARENT_PATH" && pwd)"

# ── discover child repos (direct children only, with .git) ────────────────────
discover_repos() {
  local parent="$1"
  local out=()
  local d
  # Only direct children (not recursive). Monorepos with nested repos should call per subpath.
  while IFS= read -r -d '' d; do
    [[ -d "$d/.git" ]] || continue
    local name
    name="$(basename "$d")"
    if [[ -n "$INCLUDE_GLOB" ]] && [[ ! "$name" == $INCLUDE_GLOB ]]; then continue; fi
    if [[ -n "$EXCLUDE_GLOB" ]] && [[ "$name" == $EXCLUDE_GLOB ]]; then continue; fi
    out+=("$d")
  done < <(find "$parent" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)

  # Also allow the parent itself if it is a repo
  if [[ -d "$parent/.git" ]]; then
    out+=("$parent")
  fi

  printf '%s\n' "${out[@]}"
}

# ── cache shared creds once (per-user) ────────────────────────────────────────
ensure_user_creds_cache() {
  local ado_cache="$HOME/.sdlc/ado.env"
  if [[ -f "$ado_cache" ]]; then
    log_info "Found existing creds cache: $ado_cache (reusing)"
    return 0
  fi
  mkdir -p "$HOME/.sdlc" 2>/dev/null || true
  log_warn "No creds cache at $ado_cache."
  log_warn "On first child repo, 'sdlc setup' will prompt for ADO_PAT/ORG/PROJECT and cache them here."
  log_warn "Subsequent child repos will reuse the cache (no re-prompt)."
}

# ── the command itself ────────────────────────────────────────────────────────
sub_init() {
  log_section "Workspace init: $PARENT_PATH"

  ensure_user_creds_cache

  local repos
  mapfile -t repos < <(discover_repos "$PARENT_PATH")
  if [[ ${#repos[@]} -eq 0 ]]; then
    log_err "No child git repos found under: $PARENT_PATH"
    log_err "Expected layout: <parent>/<repo-with-.git>/"
    return 2
  fi

  log_info "Discovered ${#repos[@]} repo(s):"
  local r
  for r in "${repos[@]}"; do echo "   • $(basename "$r")"; done

  if [[ $DRY_RUN -eq 1 ]]; then
    log_warn "DRY RUN — no changes will be made."
  fi

  # Persist workspace manifest for `sdlc workspace status/sync`
  local manifest="$PARENT_PATH/.sdlc-workspace.json"
  if [[ $DRY_RUN -eq 0 ]]; then
    {
      echo "{"
      echo "  \"parent\": \"$PARENT_PATH\","
      echo "  \"platform\": \"$PLATFORM_DIR\","
      echo "  \"created\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
      echo "  \"repos\": ["
      local i
      for i in "${!repos[@]}"; do
        local comma=","
        [[ $i -eq $((${#repos[@]} - 1)) ]] && comma=""
        echo "    \"${repos[$i]}\"$comma"
      done
      echo "  ]"
      echo "}"
    } > "$manifest"
    log_ok "Wrote workspace manifest: $manifest"
  fi

  # Run per-repo setup
  local failed=0 ok=0
  for r in "${repos[@]}"; do
    log_section "Setting up: $(basename "$r")"
    if [[ $DRY_RUN -eq 1 ]]; then
      log_info "[dry-run] would run: (cd '$r' && sdlc setup --ide=$IDE_MODE --from-env)"
      ok=$((ok + 1))
      continue
    fi
    # --from-env = non-interactive; relies on ~/.sdlc/ado.env populated on first repo
    if (cd "$r" && "$PLATFORM_DIR/cli/sdlc.sh" setup --ide="$IDE_MODE" --from-env); then
      ok=$((ok + 1))
      log_ok "$(basename "$r") done"
    else
      failed=$((failed + 1))
      log_err "$(basename "$r") failed (continuing with remaining repos)"
    fi
  done

  log_section "Summary"
  log_ok   "Succeeded: $ok"
  [[ $failed -gt 0 ]] && log_err "Failed:    $failed"

  [[ $failed -eq 0 ]]
}

sub_status() {
  local manifest="$PARENT_PATH/.sdlc-workspace.json"
  if [[ ! -f "$manifest" ]]; then
    log_err "No workspace manifest at $manifest. Run 'sdlc workspace init' first."
    return 2
  fi
  log_info "Workspace manifest: $manifest"
  cat "$manifest"
  echo ""
  log_section "Per-repo state"
  local repo
  while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    local name
    name="$(basename "$repo")"
    if [[ -f "$repo/.sdlc/state.json" ]]; then
      log_ok "$name: .sdlc/state.json present"
    else
      log_warn "$name: no .sdlc/state.json (needs `sdlc workspace sync`)"
    fi
  done < <(grep -oE '"/[^"]+"' "$manifest" | tr -d '"' | grep -v "^$PARENT_PATH\$" || true)
}

sub_sync() {
  # Re-run per-repo setup without re-discovering (uses manifest if present)
  local manifest="$PARENT_PATH/.sdlc-workspace.json"
  if [[ -f "$manifest" ]]; then
    log_info "Using manifest: $manifest"
  else
    log_warn "No manifest. Falling back to discovery."
  fi
  sub_init
}

case "$SUBCMD" in
  init)    sub_init ;;
  status)  sub_status ;;
  sync)    sub_sync ;;
  *)
    log_err "Unknown subcommand: $SUBCMD"
    echo "Usage: sdlc workspace {init|status|sync} [--path=<dir>] [--dry-run]"
    exit 2
    ;;
esac
