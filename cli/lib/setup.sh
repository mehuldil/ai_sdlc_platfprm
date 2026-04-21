#!/usr/bin/env bash
# ============================================================================
# AI SDLC Platform — Setup Command
# Version: 2.0.0
# ============================================================================
#
# Usage:
#   sdlc setup [--from-env] [--ide=auto|cursor|claude-code|both] [--help]
#
# Works in:
#   • Interactive terminal (prompts for PAT if needed)
#   • Cursor agent / Claude Code agent (no TTY): uses env/.env, env vars, or --from-env
#
# ============================================================================

cmd_setup_help() {
  cat <<'EOF'
sdlc setup — Initialize env/.env, .sdlc/, and optional IDE symlinks

Usage:
  sdlc setup [--from-env] [--ide=MODE]

Options:
  --from-env     Non-interactive: load ADO_* from ~/.sdlc/ado.env, env/.env, and/or the environment.
                 Fails if ADO_PAT (and org/project if not detectable from git) are missing.
  --ide=MODE     IDE integration (symlinks into .cursor / .claude)
                 auto     — detect Cursor vs Claude; if unknown and non-TTY, configure both
                 cursor   — Cursor rules/agents only
                 claude-code — Claude commands/settings only
                 both     — Cursor + Claude (recommended for shared repos)
  --help         Show this help

Chat / agent terminals (no TTY):
  • Put ADO_* in ~/.sdlc/ado.env (recommended) OR copy env/env.template → env/.env OR export ADO_PAT, ADO_ORG, ADO_PROJECT
  • Then: sdlc setup   or   sdlc setup --from-env

Full multi-repo bootstrap: cli/sdlc-setup.sh [project-path]
EOF
}

# Resolve platform root: exported by cli/sdlc.sh when sourced from CLI
_setup_platform_dir() {
  if [[ -n "${PLATFORM_DIR:-}" ]]; then
    echo "$PLATFORM_DIR"
    return
  fi
  # This file is cli/lib/setup.sh → platform is ../..
  (cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
}

# Detect IDE for --ide=auto
_setup_detect_ide() {
  if [[ -n "${CLAUDE_CODE_SESSION:-}" ]]; then
    echo "claude-code"
    return
  fi
  if [[ -n "${CURSOR_SESSION_ID:-}" || -n "${CURSOR_TRACE_ID:-}" ]]; then
    echo "cursor"
    return
  fi
  if [[ "${TERM_PROGRAM:-}" == "vscode" || -n "${VSCODE_INJECTION:-}" ]]; then
    echo "cursor"
    return
  fi
  echo ""
}

cmd_setup() {
  local from_env_only=false
  local ide_mode="auto"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        cmd_setup_help
        return 0
        ;;
      --from-env)
        from_env_only=true
        shift
        ;;
      --ide=*)
        ide_mode="${1#--ide=}"
        shift
        ;;
      *)
        log_error "Unknown option: $1"
        cmd_setup_help
        return 1
        ;;
    esac
  done

  case "$ide_mode" in
    auto|cursor|claude-code|both) ;;
    *)
      log_error "Invalid --ide=$ide_mode (use auto, cursor, claude-code, or both)"
      return 1
      ;;
  esac

  log_section "AI-SDLC Platform Setup"
  echo ""

  local platform_dir
  platform_dir="$(_setup_platform_dir)"

  # Optional: cwd env/.env (merge only non-empty assignments — does not wipe ~/.sdlc/ado.env)
  if [[ -f "env/.env" ]]; then
    _merge_env_file "$(pwd)/env/.env"
    log_info "Merged env/.env from $(pwd) (see ~/.sdlc/ado.env for shared ADO credentials)"
  fi

  # Auto-detect environment label (logging only)
  local ide_label="terminal"
  [[ -n "${CURSOR_SESSION_ID:-}${CURSOR_TRACE_ID:-}" || "${TERM_PROGRAM:-}" == "vscode" ]] && ide_label="cursor"
  [[ -n "${CLAUDE_CODE_SESSION:-}" ]] && ide_label="claude-code"
  if ! _sdlc_stdin_is_tty 2>/dev/null; then
    [[ "$ide_label" == "terminal" ]] && ide_label="agent-chat"
  fi
  log_info "Environment: $ide_label"

  if [[ "$from_env_only" == true ]]; then
    log_info "Mode: --from-env (non-interactive)"
  fi

  if ! _sdlc_stdin_is_tty 2>/dev/null; then
    log_info "Non-TTY: using env/.env and/or ADO_PAT, ADO_ORG, ADO_PROJECT (no prompts)."
  fi

  # Git remote → ADO
  local git_remote ado_org ado_project user_email
  git_remote="$(git remote get-url origin 2>/dev/null || echo "")"
  if echo "$git_remote" | grep -q "dev.azure.com"; then
    ado_org="$(echo "$git_remote" | sed -n 's|.*dev.azure.com/\([^/]*\)/.*|\1|p')"
    ado_project="$(echo "$git_remote" | sed -n 's|.*dev.azure.com/[^/]*/\([^/]*\)/.*|\1|p')"
  fi
  user_email="$(git config user.email 2>/dev/null || echo "")"

  # Env overrides (after env/.env)
  [[ -n "${ADO_ORG:-}" ]] && ado_org="$ADO_ORG"
  [[ -n "${ADO_PROJECT:-}" ]] && ado_project="$ADO_PROJECT"

  log_info "Auto-detected / env:"
  [[ -n "$ado_org" ]] && log_info "  ADO Org: $ado_org" || log_warn "  ADO Org: (not set yet)"
  [[ -n "$ado_project" ]] && log_info "  ADO Project: $ado_project" || log_warn "  ADO Project: (not set yet)"
  [[ -n "$user_email" ]] && log_info "  Git email: $user_email"
  echo ""

  local ado_pat=""
  ado_pat="${ADO_PAT:-}"

  if [[ "$from_env_only" == true && -z "$ado_pat" ]]; then
    log_error "--from-env requires ADO_PAT in env/.env or in the environment."
    return 1
  fi

  if _sdlc_stdin_is_tty 2>/dev/null && [[ "$from_env_only" != true ]]; then
    if [[ -z "$ado_pat" ]]; then
      log_warn "Enter Azure DevOps PAT (input hidden):"
      read -rsp "  PAT: " ado_pat
      echo ""
    fi
  else
    if [[ -z "$ado_pat" ]]; then
      log_error "ADO_PAT is missing (non-interactive)."
      echo ""
      log_info "Do one of the following, then re-run:  sdlc setup   or   sdlc setup --from-env"
      log_info "  1) Create ~/.sdlc/ado.env (see env/ado.env.template) or env/.env from env/env.template"
      log_info "  2) Export: ADO_PAT, ADO_ORG, ADO_PROJECT in the agent environment"
      log_info "  PAT: https://dev.azure.com/_usersSettings/tokens"
      return 1
    fi
  fi

  [[ -z "$ado_pat" ]] && { log_error "PAT required."; return 1; }

  if [[ -z "$ado_org" ]]; then
    if _sdlc_stdin_is_tty 2>/dev/null && [[ "$from_env_only" != true ]]; then
      read -rp "  ADO Organization: " ado_org
    else
      log_error "ADO_ORG is required. Set in env/.env or export ADO_ORG=..."
      return 1
    fi
  fi
  [[ -z "$ado_org" ]] && { log_error "ADO org required."; return 1; }

  if [[ -z "$ado_project" ]]; then
    if _sdlc_stdin_is_tty 2>/dev/null && [[ "$from_env_only" != true ]]; then
      read -rp "  ADO Project: " ado_project
    else
      log_error "ADO_PROJECT is required. Set in env/.env or export ADO_PROJECT=..."
      return 1
    fi
  fi
  [[ -z "$ado_project" ]] && { log_error "ADO project required."; return 1; }

  # Optional fields from env
  local ado_project_id="${ADO_PROJECT_ID:-}"
  local ado_user_name="${ADO_USER_NAME:-}"
  local ado_user_id="${ADO_USER_ID:-}"
  [[ -z "$user_email" && -n "${ADO_USER_EMAIL:-}" ]] && user_email="$ADO_USER_EMAIL"

  echo ""
  log_info "Creating workspace..."

  mkdir -p .sdlc/memory .sdlc/rpi
  touch .sdlc/role .sdlc/stack .sdlc/stage .sdlc/route .sdlc/story-id

  mkdir -p env

  local now_date
  now_date=$(date +%Y-%m-%d)
  cat > env/.env << ENVEOF
# AI-SDLC Platform Environment (sdlc setup — $now_date)
ADO_ORG=$ado_org
ADO_PROJECT=$ado_project
ADO_PROJECT_ID=$ado_project_id
ADO_USER_NAME=$ado_user_name
ADO_USER_EMAIL=$user_email
ADO_USER_ID=$ado_user_id
ADO_PAT=$ado_pat
WIKIJS_URL=${WIKIJS_URL:-https://wiki.jcinternal.com}
WIKIJS_TOKEN=${WIKIJS_TOKEN:-}
WIKI_TOKEN=${WIKI_TOKEN:-}
ES_URL=${ES_URL:-}
ES_USER=${ES_USER:-}
ES_PWD=${ES_PWD:-}
ENVEOF
  log_success "  env/.env written"

  cat > .sdlc/memory/workflow-state.md << 'MEMEOF'
# Workflow State

- task_id: (pending)
- route: (pending)
- current_phase: setup
- current_step: initialized
- gates_passed: []
- gates_pending: [G1,G2,G3,G4,G5,G6,G7,G8,G9,G10]
- blocked_reason: none
- last_updated: (see timestamp in this file)
MEMEOF
  log_success "  .sdlc/ workspace ready"

  # Resolve --ide
  local resolved_ide=""
  case "$ide_mode" in
    cursor)   resolved_ide="cursor" ;;
    claude-code) resolved_ide="claude-code" ;;
    both)     resolved_ide="both" ;;
    auto)
      resolved_ide="$(_setup_detect_ide)"
      if [[ -z "$resolved_ide" ]]; then
        if _sdlc_stdin_is_tty 2>/dev/null; then
          log_info "  IDE: terminal — skip symlinks (use --ide=cursor|claude-code|both to add)"
        else
          resolved_ide="both"
          log_info "  IDE: auto → both (non-TTY) so Cursor and Claude Code can use the same repo"
        fi
      else
        log_info "  IDE: auto → $resolved_ide"
      fi
      ;;
  esac

  if [[ -n "$resolved_ide" ]]; then
    _setup_ide_links "$resolved_ide" "$platform_dir"
  fi

  if [[ -d ".git" ]]; then
    _setup_hooks "$platform_dir"
    if [[ -x "${platform_dir}/scripts/verify-git-hooks.sh" ]]; then
      if ! bash "${platform_dir}/scripts/verify-git-hooks.sh" "."; then
        log_warn "  Git hooks missing — retrying install..."
        _setup_hooks "$platform_dir"
        (cd "${platform_dir}" && [[ -f setup-documentation.sh ]] && bash setup-documentation.sh --silent) || true
        if bash "${platform_dir}/scripts/verify-git-hooks.sh" "."; then
          log_success "  Git hooks installed and verified"
        else
          log_warn "  Git hooks still not verified — run ./setup.sh or sdlc doctor (setup continues)"
        fi
      else
        log_success "  Git hooks verified"
      fi
    fi
  fi

  # Memory / module / semantic bootstrap (non-fatal)
  if [[ -x "${platform_dir}/scripts/bootstrap-sdlc-features.sh" ]]; then
    bash "${platform_dir}/scripts/bootstrap-sdlc-features.sh" "$(pwd)" "$platform_dir" 2>/dev/null || true
  fi

  _setup_gitignore

  # Persist project for CLI (~/.sdlc/config) — load first so we do not clear role/stack
  if command -v load_config &>/dev/null; then
    load_config
  fi
  SDLC_PROJECT_DIR="$(pwd)"
  export SDLC_PROJECT_DIR
  if command -v save_config &>/dev/null; then
    save_config
  fi

  echo ""
  log_info "Validating..."
  _validate_setup "$ado_org" "$ado_project" "$ado_pat"

  echo ""
  log_success "Setup complete!"
  log_info "Next steps:"
  log_info "  1. sdlc use <role> [--stack=<stack>]"
  log_info "  2. sdlc run 01-requirement-intake [--story=US-…]"
  log_info "  3. Reload MCP in Cursor if you use Azure DevOps tools"
  echo ""
  log_info "Roles: product | backend | frontend | qa | performance | ui | tpm | boss"
  log_info "Stacks: java-tej | kotlin-android | swift-ios | react-native | jmeter | figma-design"
}

_setup_ide_links() {
  local ide="$1"
  local platform_dir="$2"

  case "$ide" in
    both)
      _setup_ide_links_one "claude-code" "$platform_dir"
      _setup_ide_links_one "cursor" "$platform_dir"
      return
      ;;
    cursor|claude-code)
      _setup_ide_links_one "$ide" "$platform_dir"
      ;;
    *)
      return
      ;;
  esac
}

_setup_ide_links_one() {
  local ide="$1"
  local platform_dir="$2"

  if [[ "$ide" == "claude-code" ]]; then
    mkdir -p .claude
    for dir in agents skills hooks; do
      if [[ -d "$platform_dir/$dir" ]]; then
        ln -sfn "$platform_dir/$dir" ".claude/$dir" 2>/dev/null || true
      fi
    done
    if [[ -d "$platform_dir/.claude/commands" ]]; then
      ln -sfn "$platform_dir/.claude/commands" ".claude/commands" 2>/dev/null || true
    fi
    if [[ -f "$platform_dir/.claude/settings.json" ]]; then
      cp -f "$platform_dir/.claude/settings.json" .claude/settings.json 2>/dev/null || true
    fi
    log_success "  Claude Code: .claude/ linked"
  elif [[ "$ide" == "cursor" ]]; then
    mkdir -p .cursor/rules
    ln -sfn "$platform_dir" ".cursor/platform" 2>/dev/null || true
    local rule
    for rule in "$platform_dir"/rules/*.md; do
      if [[ -f "$rule" ]]; then
        ln -sfn "$rule" ".cursor/rules/rule-$(basename "$rule")" 2>/dev/null || true
      fi
    done
    for agent in "$platform_dir"/agents/shared/*.md; do
      if [[ -f "$agent" ]]; then
        ln -sfn "$agent" ".cursor/rules/agent-$(basename "$agent")" 2>/dev/null || true
      fi
    done
    if [[ -f "$platform_dir/mcp.json" ]]; then
      ln -sfn "$platform_dir/mcp.json" ".cursor/mcp.json" 2>/dev/null || true
      ln -sfn "$platform_dir/mcp.json" ".mcp.json" 2>/dev/null || true
    fi
    log_success "  Cursor: .cursor/ linked (rules + mcp.json)"
  fi
}

_setup_hooks() {
  local platform_dir="$1"
  local hooks_dir=".git/hooks"
  mkdir -p "$hooks_dir"

  cat > "$hooks_dir/pre-commit" << HOOKEOF
#!/usr/bin/env bash
SDLC_HOOKS="$platform_dir/hooks"
[ -f "\$SDLC_HOOKS/pre-commit.sh" ] && bash "\$SDLC_HOOKS/pre-commit.sh" "\$@"
[ -f "\$SDLC_HOOKS/token-guard.sh" ] && bash "\$SDLC_HOOKS/token-guard.sh" "\$@"
HOOKEOF
  chmod +x "$hooks_dir/pre-commit"
  log_success "  Git hooks installed"
}

_setup_gitignore() {
  local gi=".gitignore"
  local entries=("env/.env" ".token-usage.log" ".sdlc/rpi/*/research.md" ".sdlc/rpi/*/plan.md" ".gate-audit.log")

  local entry
  for entry in "${entries[@]}"; do
    if [[ -f "$gi" ]]; then
      grep -qxF "$entry" "$gi" 2>/dev/null || echo "$entry" >> "$gi"
    else
      echo "$entry" >> "$gi"
    fi
  done
}

_validate_setup() {
  local org="$1" project="$2" pat="$3"
  local pass=0 fail=0

  if [[ -d ".sdlc" ]]; then
    log_success "  .sdlc/ exists"
    ((pass++)) || true
  else
    log_error "  .sdlc/ missing"
    ((fail++)) || true
  fi

  if [[ -f "env/.env" ]]; then
    log_success "  env/.env exists"
    ((pass++)) || true
  else
    log_error "  env/.env missing"
    ((fail++)) || true
  fi

  if [[ -n "$pat" ]]; then
    log_success "  ADO PAT configured"
    ((pass++)) || true
  else
    log_error "  ADO PAT missing"
    ((fail++)) || true
  fi

  local ado_test
  ado_test=$(curl -s -o /dev/null -w "%{http_code}" -u ":$pat" "https://dev.azure.com/$org/$project/_apis/wit/workitemtypes?api-version=7.0" 2>/dev/null || echo "000")

  if [[ "$ado_test" == "200" ]]; then
    log_success "  ADO connectivity: OK"
    ((pass++)) || true
  else
    log_warn "  ADO connectivity: could not verify (HTTP $ado_test)"
  fi

  echo ""
  log_info "Validation: $pass passed, $fail failed"
}
