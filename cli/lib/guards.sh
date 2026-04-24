#!/usr/bin/env bash
# cli/lib/guards.sh — Context guard, TTY detection, and chat-first ASK helpers
# Part of AI SDLC Platform v2.0.0
# Depends on: logging.sh, config.sh
# -----------------------------------------------------------

# True when stdin is a real terminal (interactive). Cursor/agent runs commands with no TTY.
# Set SDL_FORCE_INTERACTIVE=1 to force prompts (e.g. debugging).
_sdlc_stdin_is_tty() {
  [[ -t 0 ]] || [[ "${SDL_FORCE_INTERACTIVE:-0}" == "1" ]]
}

# ============================================================================
# Chat-first ASK helpers (non-TTY fallback messages)
# ============================================================================

_sdlc_print_ask_in_chat_role() {
  log_error "Missing role — non-interactive session (no terminal stdin)."
  echo "" >&2
  echo -e "  ${CYAN}ASK in chat:${NC} Choose your role in the chat panel (not the terminal)." >&2
  echo "  After you reply, your assistant should run:" >&2
  echo -e "    ${GREEN}sdlc use <role>${NC}  or  ${GREEN}sdlc use <role> --stack=<stack>${NC}" >&2
  echo "" >&2
  echo "  Roles: ${ROLES[*]}" >&2
  log_recovery_footer
}

_sdlc_print_ask_in_chat_stack() {
  log_error "Missing stack — non-interactive session (no terminal stdin)."
  echo "" >&2
  echo -e "  ${CYAN}ASK in chat:${NC} Choose your stack in the chat panel." >&2
  echo "  Then run, e.g.:" >&2
  echo -e "    ${GREEN}sdlc use ${SDLC_ROLE:-<role>} --stack=java${NC}" >&2
  echo "" >&2
  echo "  Stacks: ${STACKS[*]}  (use 0 in terminal only to skip)" >&2
  log_recovery_footer
}

_sdlc_print_ask_in_chat_stage() {
  log_error "Missing stage — non-interactive session (no terminal stdin)."
  echo "" >&2
  echo -e "  ${CYAN}ASK in chat:${NC} Which stage? Then run ${GREEN}sdlc run <stage-id>${NC} (e.g. ${GREEN}04-grooming${NC})" >&2
  log_recovery_footer
}

# ============================================================================
# Context guard: prompt for missing context (TTY) or fail with ASK instructions
# ============================================================================

_context_guard() {
  local needs_role="${1:-false}"
  local needs_stack="${2:-false}"
  local needs_stage="${3:-false}"

  load_config

  if [[ "$needs_role" == "true" && -z "$SDLC_ROLE" ]]; then
    log_warn "No role set. Which role are you working as?"
    echo ""
    for i in "${!ROLES[@]}"; do
      echo "  $((i+1))) ${ROLES[$i]}"
    done
    echo ""
    if ! _sdlc_stdin_is_tty; then
      _sdlc_print_ask_in_chat_role
      return 1
    fi
    read -rp "Enter role number or name: " role_input
    if [[ "$role_input" =~ ^[0-9]+$ ]]; then
      role_input="${ROLES[$((role_input-1))]}"
    fi
    cmd_use "$role_input"
  fi

  if [[ "$needs_stack" == "true" && -z "$SDLC_STACK" ]]; then
    log_warn "No stack set. Which tech stack?"
    echo ""
    for i in "${!STACKS[@]}"; do
      echo "  $((i+1))) ${STACKS[$i]}"
    done
    echo "  0) Skip (no stack needed)"
    echo ""
    if ! _sdlc_stdin_is_tty; then
      _sdlc_print_ask_in_chat_stack
      return 1
    fi
    read -rp "Enter stack number or name: " stack_input
    if [[ "$stack_input" == "0" ]]; then
      SDLC_STACK=""
    elif [[ "$stack_input" =~ ^[0-9]+$ ]]; then
      SDLC_STACK="${STACKS[$((stack_input-1))]}"
    else
      SDLC_STACK="$stack_input"
    fi
    save_config
  fi

  if [[ "$needs_stage" == "true" && -z "$SDLC_STAGE" ]]; then
    log_warn "No stage set. Which stage?"
    echo ""
    for i in "${!STAGES[@]}"; do
      echo "  $((i+1))) ${STAGES[$i]}"
    done
    echo ""
    if ! _sdlc_stdin_is_tty; then
      _sdlc_print_ask_in_chat_stage
      return 1
    fi
    read -rp "Enter stage number or name: " stage_input
    if [[ "$stage_input" =~ ^[0-9]+$ ]]; then
      stage_input="${STAGES[$((stage_input-1))]}"
    fi
    SDLC_STAGE="$stage_input"
    save_config
  fi

  return 0
}
