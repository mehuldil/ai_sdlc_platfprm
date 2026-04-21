#!/usr/bin/env bash
# cli/lib/skill-discovery.sh — Interactive skill discovery and composition
# Part of AI SDLC Platform v2.1.0
# -----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logging.sh"

SKILL_REGISTRY="${PLATFORM_DIR}/skills/registry.json"

# ============================================================================
# SKILL DISCOVERY UI
# ============================================================================

cmd_skills_discover() {
  local filter_role=""
  local filter_stage=""
  local filter_category=""
  
  # Parse arguments
  for arg in "$@"; do
    case "$arg" in
      --for-role=*) filter_role="${arg#--for-role=}" ;;
      --for-stage=*) filter_stage="${arg#--for-stage=}" ;;
      --category=*) filter_category="${arg#--category=}" ;;
    esac
  done
  
  log_section "Skill Discovery"
  
  # Build query
  local query=".skills | to_entries | .[]"
  
  if [[ -n "$filter_role" ]]; then
    log_info "Filtering for role: $filter_role"
    query="$query | select(.value.accepts_roles | contains([\"$filter_role\"]) or contains([\"*\"]))"
  fi
  
  if [[ -n "$filter_stage" ]]; then
    log_info "Filtering for stage: $filter_stage"
    query="$query | select(.value.accepts_stages | contains([\"$filter_stage\"]))"
  fi
  
  if [[ -n "$filter_category" ]]; then
    log_info "Filtering for category: $filter_category"
    query="$query | select(.value.category == \"$filter_category\")"
  fi
  
  # Display results
  echo ""
  echo "┌─────────────────────────────────────────────────────────────────┐"
  echo "│ Available Skills                                                │"
  echo "├─────────────────────────────────────────────────────────────────┤"
  
  local skills_count=0
  while IFS= read -r line; do
    local id=$(echo "$line" | jq -r '.key')
    local desc=$(echo "$line" | jq -r '.value.description')
    local cost=$(echo "$line" | jq -r '.value.token_budget.output // 0')
    local universal=$(echo "$line" | jq -r '.value.universal')
    local cacheable=$(echo "$line" | jq -r '.value.cacheable')
    
    printf "│ %-20s │ %5s tokens │ %-9s │ %-7s │\n" \
      "${id:0:20}" "$cost" \
      "$([[ "$universal" == "true" ]] && echo "universal" || echo "role-specific")" \
      "$([[ "$cacheable" == "true" ]] && echo "cached" || echo "no-cache")"
    printf "│ %-63s │\n" "  ${desc:0:60}"
    echo "├─────────────────────────────────────────────────────────────────┤"
    ((skills_count++))
  done < <(jq -c "$query" "$SKILL_REGISTRY" 2>/dev/null)
  
  echo "└─────────────────────────────────────────────────────────────────┘"
  echo ""
  log_info "Found $skills_count skills"
  
  # Prompt for composition
  echo ""
  echo "Compose workflow from skills (enter numbers, comma-separated):"
  echo "Example: 1,2,5"
  read -r selection
  
  if [[ -n "$selection" ]]; then
    compose_workflow "$selection"
  fi
}

compose_workflow() {
  local selection="$1"
  
  log_section "Creating Custom Workflow"
  
  # Parse selection
  IFS=',' read -ra indices <<< "$selection"
  
  # Get skill IDs
  local skills=()
  local i=1
  while IFS= read -r line; do
    local id=$(echo "$line" | jq -r '.key')
    for idx in "${indices[@]}"; do
      if [[ "$i" == "$idx" ]]; then
        skills+=("$id")
      fi
    done
    ((i++))
  done < <(jq -c ".skills | to_entries | .[]" "$SKILL_REGISTRY")
  
  echo "Selected skills:"
  for skill in "${skills[@]}"; do
    echo "  - $skill"
  done
  
  # Get workflow name
  echo ""
  echo "Workflow name:"
  read -r workflow_name
  
  # Create composition YAML
  local output_file="${SDLC_PROJECT_DIR:-$PWD}/.sdlc/user-composed-skills/${workflow_name}.yaml"
  mkdir -p "$(dirname "$output_file")"
  
  cat > "$output_file" << EOF
name: $workflow_name
version: 1.0.0
description: User-composed workflow
created_by: $(whoami)
created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
shared: false

composition:
EOF

  i=1
  for skill in "${skills[@]}"; do
    cat >> "$output_file" << EOF
  - id: step-$i
    name: $skill
    skill: $skill
    input: {}
    output: output_$i
EOF
    ((i++))
  done

  log_success "Created workflow: $output_file"
  echo ""
  echo "Execute with:"
  echo "  sdlc skills invoke-composed $output_file"
}

# ============================================================================
# SKILL REGISTRATION
# ============================================================================

cmd_skills_register() {
  local skill_file="$1"
  
  if [[ -z "$skill_file" ]]; then
    log_error "Usage: sdlc skills register <skill-file.md>"
    return 1
  fi
  
  if [[ ! -f "$skill_file" ]]; then
    log_error "File not found: $skill_file"
    return 1
  fi
  
  log_section "Registering Skill"
  
  # Extract metadata from skill file
  local skill_id
  skill_id=$(grep -E "^id:" "$skill_file" | head -1 | cut -d: -f2 | xargs)
  
  if [[ -z "$skill_id" ]]; then
    skill_id=$(basename "$skill_file" .md)
    log_warn "No 'id:' found in frontmatter, using filename: $skill_id"
  fi
  
  local category
  category=$(grep -E "^category:" "$skill_file" | head -1 | cut -d: -f2 | xargs)
  category="${category:-general}"
  
  local universal
  universal=$(grep -E "^universal:" "$skill_file" | head -1 | cut -d: -f2 | xargs)
  universal="${universal:-false}"
  
  log_info "Skill ID: $skill_id"
  log_info "Category: $category"
  log_info "Universal: $universal"
  
  # Compute relative path from platform dir
  local rel_path="${skill_file#$PLATFORM_DIR/}"
  
  # Create registry entry
  local entry=$(jq -n \
    --arg id "$skill_id" \
    --arg category "$category" \
    --arg universal "$universal" \
    --arg path "$rel_path" \
    '{
      ($id): {
        id: $id,
        category: $category,
        universal: ($universal == "true"),
        accepts_roles: ["*"],
        accepts_stages: [],
        model: "sonnet-4-6",
        token_budget: {input: 4000, output: 2000},
        implementations: {
          generic: {
            path: $path,
            cost: 200,
            format: "monolithic"
          }
        },
        cacheable: false
      }
    }')
  
  echo ""
  echo "Add this to skills/registry.json:"
  echo "$entry" | jq '.'
  
  echo ""
  log_warn "Auto-registration not yet implemented. Please manually add to registry."
  
  # Offer to update registries
  echo ""
  read -p "Update skill registries now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "${PLATFORM_DIR}/scripts/regenerate-registries.sh" --update
  fi
}

cmd_agent_register() {
  local agent_file="$1"
  
  if [[ -z "$agent_file" ]]; then
    log_error "Usage: sdlc agent register <agent-file.md>"
    return 1
  fi
  
  log_section "Registering Agent"
  
  # Extract agent name from file
  local agent_name
  agent_name=$(basename "$agent_file" .md)
  
  # Determine tier and role from path
  local tier="2"
  local role="shared"
  
  if [[ "$agent_file" == *"/shared/"* ]]; then
    tier="1"
    role="shared"
  elif [[ "$agent_file" == *"/backend/"* ]]; then
    tier="2"
    role="backend"
  elif [[ "$agent_file" == *"/frontend/"* ]]; then
    tier="2"
    role="frontend"
  elif [[ "$agent_file" == *"/qa/"* ]]; then
    tier="2"
    role="qa"
  fi
  
  log_info "Agent: $agent_name"
  log_info "Tier: $tier"
  log_info "Role: $role"
  
  # Compute relative path
  local rel_path="${agent_file#$PLATFORM_DIR/}"
  
  # Create registry entry
  local entry=$(jq -n \
    --arg name "$agent_name" \
    --argjson tier "$tier" \
    --arg role "$role" \
    --arg path "$rel_path" \
    '{
      ($name): {
        path: $path,
        tier: $tier,
        primary_role: $role,
        description: "[Auto-registered] Agent",
        tags: ["auto-registered"],
        accepts_roles: ["*"],
        output_cost_tokens: 500,
        required_env: []
      }
    }')
  
  echo ""
  echo "Add this to agents/agent-registry.json:"
  echo "$entry" | jq '.'
  
  log_warn "Please manually add to agent-registry.json"
}

cmd_stage_register() {
  local stage_file="$1"
  
  if [[ -z "$stage_file" ]]; then
    log_error "Usage: sdlc stage register <stage-directory>"
    return 1
  fi
  
  log_section "Registering Stage"
  
  # Stage directory should contain STAGE.md
  if [[ ! -f "$stage_file/STAGE.md" ]]; then
    log_error "No STAGE.md found in $stage_file"
    return 1
  fi
  
  # Extract stage number from directory name
  local stage_num
  stage_num=$(basename "$stage_file" | grep -oE '^[0-9]+' || echo "")
  
  if [[ -z "$stage_num" ]]; then
    log_error "Stage directory must start with number (e.g., 16-new-stage)"
    return 1
  fi
  
  log_info "Stage number: $stage_num"
  
  # Check for composition.yaml
  if [[ -f "$stage_file/composition.yaml" ]]; then
    log_success "Found composition.yaml (v2.0 format)"
  else
    log_warn "No composition.yaml - using STAGE.md (legacy format)"
  fi
  
  # Update cli/lib/config.sh STAGES array
  log_info "Add to cli/lib/config.sh:"
  echo "  STAGES+=(\"${stage_num}-$(basename "$stage_file" | sed 's/^[0-9]*-//')\")"
  
  log_warn "Please manually update config.sh"
}

# ============================================================================
# COMPOSITION EXECUTION
# ============================================================================

cmd_skills_invoke_composed() {
  local composition_file="$1"
  local input_json="${2:-{}}"
  
  if [[ -z "$composition_file" ]]; then
    log_error "Usage: sdlc skills invoke-composed <composition.yaml> [input-json]"
    return 1
  fi
  
  if [[ ! -f "$composition_file" ]]; then
    log_error "Composition file not found: $composition_file"
    return 1
  fi
  
  log_section "Executing Composed Skill"
  log_info "Composition: $composition_file"
  
  # Execute via Python composition engine
  python3 "${PLATFORM_DIR}/cli/lib/composition-engine.py" \
    --composition "$composition_file" \
    --input "$input_json" \
    --platform-dir "$PLATFORM_DIR" \
    --project-dir "${SDLC_PROJECT_DIR:-$PWD}"
}

# ============================================================================
# UTILITY COMMANDS
# ============================================================================

cmd_skills_list_categories() {
  log_section "Skill Categories"
  
  jq -r '.skills | group_by(.category) | .[] | .[0].category' "$SKILL_REGISTRY" | \
    sort -u | \
    while read -r cat; do
      local count
      count=$(jq -r "[.skills | to_entries | .[] | select(.value.category == \"$cat\")] | length" "$SKILL_REGISTRY")
      echo "  $cat: $count skills"
    done
}

cmd_skills_show() {
  local skill_id="$1"
  
  if [[ -z "$skill_id" ]]; then
    log_error "Usage: sdlc skills show <skill-id>"
    return 1
  fi
  
  log_section "Skill: $skill_id"
  
  # Show from registry
  jq -r ".skills.\"$skill_id\" // empty" "$SKILL_REGISTRY" | jq '.'
  
  # Show implementations
  echo ""
  echo "Implementations:"
  jq -r ".skills.\"$skill_id\".implementations | to_entries | .[] | \"  \\(.key): \\(.value.path)\"" "$SKILL_REGISTRY" 2>/dev/null || echo "  None found"
}

cmd_skills_cache_clear() {
  local skill_id="${1:-all}"
  
  local cache_dir="${SDLC_PROJECT_DIR:-$PWD}/.sdlc/cache/skills"
  
  if [[ "$skill_id" == "all" ]]; then
    if [[ -d "$cache_dir" ]]; then
      rm -rf "${cache_dir:?}"/*
      log_success "Cleared all skill caches"
    else
      log_info "No cache directory found"
    fi
  else
    # Remove specific skill caches
    find "$cache_dir" -name "*.json" -exec sh -c '
      if grep -q "\"step_id\":\"[^\"]*'$1'" "$2" 2>/dev/null || \
         grep -q "\"skill\":\"'$1'\"" "$2" 2>/dev/null; then
        rm "$2"
        echo "Removed: $2"
      fi
    ' _ "$skill_id" {} \;
    log_success "Cleared cache for skill: $skill_id"
  fi
}
