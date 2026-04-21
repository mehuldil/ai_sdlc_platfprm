# CLI Enhancements for ai-sdlc-platform v2.0

This document outlines key modifications to `cli/sdlc.sh` to integrate all new systems.

---

## Overview of Enhancements

| Feature | Status | File | Impact |
|---------|--------|------|--------|
| State persistence | ✓ Ready | `sdlc-state.sh` | `.sdlc/state.json` replaces empty files |
| Token blocking | ✓ Ready | `token-blocker.sh` | `cmd_run` checks budget before execution |
| Gate informant | ✓ Ready | `agents/shared/gate-informant.md` | `cmd_run` calls gate-check automatically |
| Role-agent mapping | ✓ Ready | `agents/agent-registry.json` | No CLI changes needed (JSON-based) |
| Skills discovery | ✓ Ready | `skills/SKILL.md` | New `sdlc skills` commands |
| Template registry | ✓ Ready | `templates/TEMPLATE_REGISTRY.md` | New `sdlc template` commands |
| Variant loading | ✓ Ready | `stages/*/variants/*.md` | Auto-loaded by `cmd_run --stack=<s>` |

---

## Key Changes to sdlc.sh

### 1. Load State Management

At top of `cli/sdlc.sh`, after loading config:

```bash
# Source state management
STATE_SH="${PLATFORM_DIR}/cli/sdlc-state.sh"
[[ -f "$STATE_SH" ]] && source "$STATE_SH"

# Initialize state on first run
init_state
```

### 2. Load and Call Token Blocker

Before `cmd_run()`, source token-blocker:

```bash
# Source token enforcement
BLOCKER_SH="${PLATFORM_DIR}/scripts/token-blocker.sh"
[[ -f "$BLOCKER_SH" ]] && source "$BLOCKER_SH"
```

Modify `cmd_run()` to check budget:

```bash
cmd_run() {
  local stage="$1"
  
  # Load state first
  load_context
  
  # Validate stage
  validate_stage "$stage" || { log_error "Invalid stage: $stage"; return 1; }
  
  # Initialize state
  init_state
  
  # **NEW**: Check token budget (BLOCKING)
  local expected_tokens=5000  # Average per stage
  if ! check_token_limit "$stage" "${SDLC_ROLE:-product}" "$expected_tokens"; then
    log_error "Token budget check failed. Use --acknowledge-overage to proceed at your own risk."
    return 1
  fi
  
  # **NEW**: Call gate-check (informational, not blocking)
  local ado_id="${ADO_WORK_ITEM:-}"
  if [[ -n "$ado_id" ]]; then
    log_section "Checking Gates for Stage $stage"
    # Call gate-informant agent
    # (This logs to ADO but doesn't block)
  fi
  
  # ... rest of stage execution
  
  # **NEW**: Save context after stage
  save_context "${SDLC_ROLE:-}" "${SDLC_STACK:-}" "$stage"
}
```

### 3. Implement Stub Commands

Replace stub `cmd_sync`, `cmd_publish`, `cmd_tokens`:

```bash
cmd_sync() {
  log_section "Syncing Memory to Git"
  
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_warn "Not a git repo — memory is local only"
    return 0
  fi
  
  local mem_dir="${SDLC_PROJECT_DIR:-.}/.sdlc/memory"
  [[ -d "$mem_dir" ]] || { log_warn "No memory files to sync"; return 0; }
  
  git add "$mem_dir" 2>/dev/null || true
  
  if git diff --cached --quiet "$mem_dir"; then
    log_success "Memory already synced"
  else
    git commit -m "sdlc: sync memory at $(date +%Y-%m-%d\ %H:%M:%S)" || log_warn "Nothing to commit"
    log_success "Memory synced to git"
  fi
  
  # Push if origin exists
  if git remote | grep -q origin; then
    git push origin HEAD 2>/dev/null && log_success "Pushed to origin" || log_warn "Push failed"
  fi
}

cmd_publish() {
  log_section "Publishing Stage Output"
  
  local stage="${SDLC_STAGE:-}"
  [[ -z "$stage" ]] && { log_error "No active stage. Use: sdlc run <stage>"; return 1; }
  
  local out_file="${SDLC_PROJECT_DIR:-.}/.sdlc/memory/${stage}-output.md"
  [[ -f "$out_file" ]] || { log_error "No output found for $stage"; return 1; }
  
  local ado_id="${1:-}"
  if [[ -z "$ado_id" ]]; then
    log_warn "No ADO ID provided. Output saved locally:"
    cat "$out_file"
    return 0
  fi
  
  log_info "Publishing $stage output to ADO #$ado_id..."
  
  # Check ADO_PAT
  if [[ -z "$ADO_PAT" ]]; then
    log_error "ADO_PAT not set in env/.env"
    return 1
  fi
  
  # Call ADO API to post comment
  local comment_text="$(cat "$out_file")"
  _ado_add_comment "$ado_id" "$comment_text" && log_success "Published to ADO #$ado_id"
}

cmd_tokens() {
  log_section "Token Usage Report"
  
  local state_file="${SDLC_PROJECT_DIR:-.}/.sdlc/state.json"
  
  if ! command -v jq &> /dev/null; then
    log_error "jq required for token reporting"
    return 1
  fi
  
  if [[ ! -f "$state_file" ]]; then
    log_warn "No token history. Run a stage to track usage."
    return 0
  fi
  
  log_info "Token Spend Summary:"
  echo ""
  
  # Show daily breakdown
  local role="${SDLC_ROLE:-product}"
  jq -r ".token_spent | to_entries[] | select(.key | contains(\"$role\")) | \"\(.key): \(.value) tokens\"" "$state_file"
  
  echo ""
  log_info "To see detailed report:"
  log_info "  sdlc token-usage --role=$role --detail"
}
```

### 4. Add New Commands

Add to main dispatcher (around line 1260):

```bash
case "$cmd" in
  use)                cmd_use "$@" ;;
  context)            cmd_context ;;
  init)               cmd_init ;;
  run)                cmd_run "$@" ;;
  route)              cmd_route "$@" ;;
  flow)               cmd_flow "$@" ;;
  sync)               cmd_sync ;;
  publish)            cmd_publish "$@" ;;
  memory)
    case "${1:-}" in
      show) cmd_memory_show ;;
      *) log_error "Usage: sdlc memory show"; return 1 ;;
    esac ;;
  ado)                cmd_ado "$@" ;;
  agent)              cmd_agent "$@" ;;        # **NEW**
  skills)             cmd_skills "$@" ;;       # **NEW**
  template)           cmd_template "$@" ;;     # **NEW**
  gate-check)         cmd_gate_check "$@" ;;   # **NEW**
  status)             cmd_status ;;
  resume)             cmd_resume ;;
  doctor)             cmd_doctor ;;
  help)               cmd_help ;;
  *)                  log_error "Unknown command: $cmd"; cmd_help; return 1 ;;
esac
```

### 5. Implement New Commands

```bash
# Agent discovery & invocation
cmd_agent() {
  local sub="${1:-list}"
  shift
  
  case "$sub" in
    list)
      # List agents from agent-registry.json
      if command -v jq &> /dev/null; then
        jq '.tier_1_universal, .tier_2_domain | to_entries[] | .value | to_entries[] | "\(.key): \(.value.description)"' \
          "${PLATFORM_DIR}/agents/agent-registry.json"
      else
        log_warn "jq required for agent listing"
      fi
      ;;
    show)
      local agent="$1"
      if command -v jq &> /dev/null; then
        jq ".tier_1_universal.$agent, .tier_2_domain[][] | select(.key == \"$agent\") | .value" \
          "${PLATFORM_DIR}/agents/agent-registry.json"
      fi
      ;;
    invoke)
      local agent="$1"
      shift
      log_info "Invoking agent: $agent"
      # Invoke agent with params: --role, --stage, --ado-id
      ;;
    *)
      log_error "Usage: sdlc agent {list | show <agent-id> | invoke <agent-id>}"
      return 1
      ;;
  esac
}

# Skills discovery
cmd_skills() {
  local sub="${1:-list}"
  shift
  
  case "$sub" in
    list)
      log_section "Available Skills"
      # List from skills/SKILL.md files
      # Parse SKILL.md for each skill in skills/ dirs
      find "${PLATFORM_DIR}/skills" -name "SKILL.md" -type f | while read skill_file; do
        skill_dir=$(dirname "$skill_file")
        skill_name=$(basename "$skill_dir")
        echo "  $skill_name"
      done
      ;;
    show)
      local skill="$1"
      # Show skill metadata from skills/{skill}/SKILL.md
      cat "${PLATFORM_DIR}/skills/${skill}/SKILL.md" 2>/dev/null || log_error "Skill not found: $skill"
      ;;
    invoke)
      local skill="$1"
      shift
      log_info "Invoking skill: $skill"
      # Invoke skill with params
      ;;
    *)
      log_error "Usage: sdlc skills {list | show <skill> | invoke <skill>}"
      return 1
      ;;
  esac
}

# Template discovery & validation
cmd_template() {
  local sub="${1:-list}"
  shift
  
  case "$sub" in
    list)
      log_section "Available Templates"
      ls -1 "${PLATFORM_DIR}/templates"/*.md | xargs basename -a
      ;;
    validate)
      local file="$1"
      [[ -f "$file" ]] || { log_error "File not found: $file"; return 1; }
      
      log_info "Validating template: $file"
      # Run appropriate validator based on template type
      # E.g., if prd-template.md, run check-prd-sections.sh
      ;;
    generate)
      local type="$1"
      local output="${2:-.}"
      log_info "Generating $type template to $output"
      # Copy template to output location
      ;;
    *)
      log_error "Usage: sdlc template {list | validate <file> | generate <type> <output>}"
      return 1
      ;;
  esac
}

# Gate checking (informational)
cmd_gate_check() {
  local stage="${1:-}"
  local ado_id="${2:-}"
  
  [[ -z "$stage" ]] && { log_error "Usage: sdlc gate-check <stage> [ado-id]"; return 1; }
  
  log_section "Gate Check: Stage $stage"
  
  # Call gate-informant agent logic
  # Gate check is informational, user can acknowledge or not
  # Never blocks execution (only token budget blocks)
}
```

### 6. Update cmd_status

Show new state information:

```bash
cmd_status() {
  load_context  # Load from state.json
  
  log_section "Current Context"
  
  echo -e "${ROLE_ICON}  Role:       ${SDLC_ROLE:-"(not set)"}"
  echo -e "${STACK_ICON}  Stack:      ${SDLC_STACK:-"(default)"}"
  echo -e "${STAGE_ICON}  Stage:      ${SDLC_STAGE:-"(not in stage)"}"
  echo -e "${BLUE}📁  Project:    ${SDLC_PROJECT_DIR:-"(not set)"}"
  echo -e "${BLUE}🏢  Platform:   ${SDLC_PLATFORM_DIR:-$PLATFORM_DIR}"
  
  # **NEW**: Show state.json contents
  if [[ -f "${SDLC_PROJECT_DIR:-.}/.sdlc/state.json" ]]; then
    echo ""
    log_info "Recent Context History:"
    if command -v jq &> /dev/null; then
      jq '.history[-3:] | reverse | .[] | "  \(.timestamp): \(.role) / \(.stack) / \(.stage)"' \
        "${SDLC_PROJECT_DIR:-.}/.sdlc/state.json"
    fi
  fi
  
  # Show local memory
  if [[ -n "$SDLC_PROJECT_DIR" && -d "$SDLC_PROJECT_DIR/.sdlc" ]]; then
    echo ""
    log_info "Local Memory:"
    ls -lh "$SDLC_PROJECT_DIR/.sdlc/" 2>/dev/null | tail -5 | sed 's/^/     /'
  fi
  
  # **NEW**: Show token usage
  log_info "Token Budget Status:"
  if [[ -f "${SDLC_PROJECT_DIR:-.}/.sdlc/state.json" ]]; then
    # Call token-blocker to show current spend
    source "${PLATFORM_DIR}/scripts/token-blocker.sh"
    if command -v jq &> /dev/null; then
      local daily_spend=$(_get_daily_spend "${SDLC_ROLE:-product}" "${SDLC_PROJECT_DIR:-.}/.sdlc/state.json")
      local daily_budget=${DAILY_BUDGET[${SDLC_ROLE:-product}]}
      echo "  Daily: $daily_spend / $daily_budget tokens ($(( daily_spend * 100 / daily_budget ))%)"
    fi
  fi
}
```

### 7. Update Help Text

Include new commands in `cmd_help`:

```bash
cmd_help() {
  log_section "AI-SDLC AI-SDLC CLI v${SDLC_VERSION}"
  
  echo -e "${CYAN}SETUP${NC}"
  echo "  sdlc init                       Initialize local SDLC workspace"
  echo ""
  echo -e "${CYAN}ROLE / CONTEXT MANAGEMENT${NC}"
  echo "  sdlc use <role>                 Switch role (product, backend, etc.)"
  echo "  sdlc context                    Show current context"
  echo "  sdlc status                     Show full status + token usage"
  echo ""
  echo -e "${CYAN}STAGE EXECUTION${NC}"
  echo "  sdlc run <stage>                Execute stage"
  echo "  sdlc run <stage> --gate-check   Check gates before executing"
  echo "  sdlc route <task>               Route task to correct stage"
  echo "  sdlc gate-check <stage>         Check gate status (informational)"
  echo ""
  echo -e "${CYAN}AGENTS & SKILLS${NC}"
  echo "  sdlc agent list                 List all agents"
  echo "  sdlc agent show <agent>         Show agent details"
  echo "  sdlc agent invoke <agent>       Invoke agent"
  echo "  sdlc skills list                List all skills"
  echo "  sdlc skills show <skill>        Show skill details"
  echo "  sdlc skills invoke <skill>      Invoke skill"
  echo ""
  echo -e "${CYAN}TEMPLATES${NC}"
  echo "  sdlc template list              List templates"
  echo "  sdlc template validate <file>   Validate template file"
  echo "  sdlc template generate <type>   Generate template"
  echo ""
  echo -e "${CYAN}MEMORY & SYNC${NC}"
  echo "  sdlc memory show                Show memory contents"
  echo "  sdlc sync                       Sync memory to git"
  echo "  sdlc publish <ado-id>           Publish stage output to ADO"
  echo ""
  echo -e "${CYAN}AZURE DEVOPS${NC}"
  echo "  sdlc ado list --type=<type>     List work items"
  echo "  sdlc ado create <type>          Create work item"
  echo "  sdlc ado show <id>              Show work item"
  echo ""
  echo -e "${CYAN}TOKENS & BUDGETS${NC}"
  echo "  sdlc tokens                     Show token usage"
  echo ""
  echo -e "${CYAN}MAINTENANCE${NC}"
  echo "  sdlc doctor                     Diagnose issues"
  echo "  sdlc help                       Show this help"
  echo ""
}
```

---

## Integration Testing

After implementing these changes:

```bash
# 1. Test state persistence
sdlc init
sdlc use backend --stack=java-tej
sdlc context  # Should show backend, java-tej
# Kill shell and restart
sdlc context  # Should still show backend, java-tej ✓

# 2. Test token blocking
sdlc run 05 --role=product  # Should check token budget
# If over budget, should refuse execution ✓

# 3. Test gate informant
sdlc gate-check 08 --ado-id=US-123
# Should show gate status, accept ack ✓

# 4. Test new commands
sdlc agent list
sdlc skills list
sdlc template list
sdlc tokens
```

---

## See Also

- **State Management**: `cli/sdlc-state.sh`
- **Token Blocking**: `scripts/token-blocker.sh`
- **Gate Informant**: `agents/shared/gate-informant.md`
- **Agent Registry**: `agents/agent-registry.json`
- **Skills**: `skills/SKILL.md`
- **Templates**: `templates/TEMPLATE_REGISTRY.md`
