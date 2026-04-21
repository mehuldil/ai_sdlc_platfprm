#!/usr/bin/env bash
# cli/lib/skill-router.sh — Skill routing, caching, and validation
# Part of AI SDLC Platform v2.1.0
# Routes skills to appropriate implementations based on context
# -----------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL_REGISTRY="${PLATFORM_DIR}/skills/registry.json"
CACHE_DIR="${SDLC_PROJECT_DIR:-$PWD}/.sdlc/cache/skills"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# SKILL ROUTING
# ============================================================================

route_skill() {
  local skill_id="$1"
  local context_json="${2:-{}}"
  local prefer_composed="${3:-true}"
  
  log_debug "Routing skill: $skill_id"
  
  # Check if registry exists
  if [[ ! -f "$SKILL_REGISTRY" ]]; then
    log_warn "Skill registry not found, using legacy path"
    echo "legacy:$skill_id"
    return 0
  fi
  
  # Extract skill config from registry
  local skill_config
  skill_config=$(jq -r ".skills.\"$skill_id\" // empty" "$SKILL_REGISTRY" 2>/dev/null || echo "")
  
  if [[ -z "$skill_config" ]] || [[ "$skill_config" == "null" ]]; then
    log_warn "Skill '$skill_id' not in registry, using legacy path"
    echo "legacy:$skill_id"
    return 0
  fi
  
  # Determine best implementation
  local stack=$(echo "$context_json" | jq -r '.stack // "generic"')
  local role=$(echo "$context_json" | jq -r '.role // "generic"')
  
  log_debug "Context: stack=$stack, role=$role"
  
  # Try composed first if preferred
  if [[ "$prefer_composed" == "true" ]]; then
    local composed_path
    composed_path=$(echo "$skill_config" | jq -r '.implementations.composed.path // empty')
    if [[ -n "$composed_path" ]] && [[ "$composed_path" != "null" ]]; then
      local full_path="${PLATFORM_DIR}/${composed_path}"
      if [[ -f "$full_path" ]]; then
        log_info "Using composed implementation: $composed_path"
        echo "composed:${skill_id}:${full_path}"
        return 0
      fi
    fi
  fi
  
  # Try stack-specific implementation
  local stack_impl
  stack_impl=$(echo "$skill_config" | jq -r ".implementations.\"$stack\".path // empty")
  if [[ -n "$stack_impl" ]] && [[ "$stack_impl" != "null" ]]; then
    local full_path="${PLATFORM_DIR}/${stack_impl}"
    if [[ -f "$full_path" ]]; then
      log_info "Using stack-specific implementation: $stack"
      echo "stack:${skill_id}:${full_path}"
      return 0
    fi
  fi
  
  # Fallback to generic
  local generic_impl
  generic_impl=$(echo "$skill_config" | jq -r '.implementations.generic.path // empty')
  if [[ -n "$generic_impl" ]] && [[ "$generic_impl" != "null" ]]; then
    local full_path="${PLATFORM_DIR}/${generic_impl}"
    if [[ -f "$full_path" ]]; then
      log_info "Using generic implementation"
      echo "generic:${skill_id}:${full_path}"
      return 0
    fi
  fi
  
  # Ultimate fallback: legacy
  log_warn "No implementation found in registry, using legacy"
  echo "legacy:${skill_id}"
  return 0
}

# ============================================================================
# SKILL CACHE
# ============================================================================

get_cache_key() {
  local skill_id="$1"
  local input_json="$2"
  local git_head
  
  git_head=$(git rev-parse HEAD 2>/dev/null || echo "nogit")
  
  # Create deterministic hash
  echo "${skill_id}:${input_json}:${git_head}" | sha256sum | cut -d' ' -f1
}

execute_with_cache() {
  local skill_id="$1"
  local input_json="$2"
  local execution_fn="$3"
  
  # Check if skill is cacheable
  local cacheable
  cacheable=$(jq -r ".skills.\"$skill_id\".cacheable // false" "$SKILL_REGISTRY" 2>/dev/null || echo "false")
  
  if [[ "$cacheable" != "true" ]]; then
    # Not cacheable, execute directly
    $execution_fn "$skill_id" "$input_json"
    return $?
  fi
  
  # Compute cache key
  local cache_key
  cache_key=$(get_cache_key "$skill_id" "$input_json")
  local cache_file="${CACHE_DIR}/${cache_key}.json"
  
  # Check cache TTL
  local ttl_seconds
  ttl_seconds=$(jq -r ".skills.\"$skill_id\".cache_ttl_seconds // 3600" "$SKILL_REGISTRY")
  
  if [[ -f "$cache_file" ]]; then
    local cache_age
    cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
    
    if [[ $cache_age -lt $ttl_seconds ]]; then
      log_info "Cache hit for $skill_id (${cache_age}s old)"
      cat "$cache_file"
      return 0
    fi
  fi
  
  # Execute and cache
  log_info "Cache miss for $skill_id, executing..."
  mkdir -p "$CACHE_DIR"
  
  local result
  if result=$($execution_fn "$skill_id" "$input_json"); then
    echo "$result" > "$cache_file"
    echo "$result"
    return 0
  else
    return $?
  fi
}

clear_skill_cache() {
  local skill_id="${1:-all}"
  
  if [[ "$skill_id" == "all" ]]; then
    rm -rf "${CACHE_DIR:?}"/*
    log_success "Cleared all skill caches"
  else
    # Remove specific skill caches
    find "$CACHE_DIR" -name "*.json" -exec sh -c '
      if grep -q "\"skill\":\"$1\"" "$2" 2>/dev/null; then
        rm "$2"
      fi
    ' _ "$skill_id" {} \;
    log_success "Cleared cache for skill: $skill_id"
  fi
}

# ============================================================================
# SCHEMA VALIDATION
# ============================================================================

validate_skill_input() {
  local skill_id="$1"
  local input_json="$2"
  local strict="${3:-false}"
  
  local schema
  schema=$(jq -r ".skills.\"$skill_id\".input_schema // empty" "$SKILL_REGISTRY" 2>/dev/null || echo "")
  
  if [[ -z "$schema" ]] || [[ "$schema" == "null" ]]; then
    # No schema defined
    if [[ "$strict" == "true" ]]; then
      log_error "No input schema defined for $skill_id (strict mode)"
      return 1
    fi
    return 0
  fi
  
  # Basic JSON validation
  if ! echo "$input_json" | jq . > /dev/null 2>&1; then
    log_error "Invalid JSON input for skill $skill_id"
    return 1
  fi
  
  # Check required fields
  local required_fields
  required_fields=$(echo "$schema" | jq -r '.required // empty | .[]' 2>/dev/null || echo "")
  
  for field in $required_fields; do
    local value
    value=$(echo "$input_json" | jq -r ".${field} // empty")
    if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
      log_error "Missing required field: $field"
      return 1
    fi
  done
  
  log_debug "Input validation passed for $skill_id"
  return 0
}

validate_skill_output() {
  local skill_id="$1"
  local output_json="$2"
  
  local schema
  schema=$(jq -r ".skills.\"$skill_id\".output_schema // empty" "$SKILL_REGISTRY" 2>/dev/null || echo "")
  
  if [[ -z "$schema" ]] || [[ "$schema" == "null" ]]; then
    return 0
  fi
  
  # Check required fields
  local required_fields
  required_fields=$(echo "$schema" | jq -r '.required // empty | .[]' 2>/dev/null || echo "")
  
  for field in $required_fields; do
    local value
    value=$(echo "$output_json" | jq -r ".${field} // empty")
    if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
      log_warn "Missing required output field: $field"
      return 1
    fi
  done
  
  return 0
}

# ============================================================================
# COMPOSED SKILL EXECUTION
# ============================================================================

execute_composed_skill() {
  local composition_file="$1"
  local input_json="$2"
  
  log_info "Executing composed skill: $composition_file"
  
  # Parse composition YAML
  # This is a simplified version - full implementation would use yq or python
  
  # For now, delegate to python composition engine
  python3 "${PLATFORM_DIR}/cli/lib/composition-engine.py" \
    --composition "$composition_file" \
    --input "$input_json"
}

# ============================================================================
# SKILL DISCOVERY
# ============================================================================

discover_skills() {
  local filter_role="${1:-}"
  local filter_stage="${2:-}"
  local filter_category="${3:-}"
  
  local query=".skills | to_entries | .[]"
  
  if [[ -n "$filter_role" ]]; then
    query="$query | select(.value.accepts_roles | contains([\"$filter_role\"]) or contains([\"*\"]))"
  fi
  
  if [[ -n "$filter_stage" ]]; then
    query="$query | select(.value.accepts_stages | contains([\"$filter_stage\"]))"
  fi
  
  if [[ -n "$filter_category" ]]; then
    query="$query | select(.value.category == \"$filter_category\")"
  fi
  
  jq -r "$query | \\n    \"ID: \" + .key + \\\n    \"\\n  Description: \" + .value.description + \\\n    \"\\n  Universal: \" + (.value.universal | tostring) + \\\n    \"\\n  Cacheable: \" + (.value.cacheable | tostring) + \\\n    \"\\n  Cost: \" + (.value.token_budget.output | tostring) + \" tokens\\n\"" \
    "$SKILL_REGISTRY" 2>/dev/null || echo ""
}

list_skill_categories() {
  jq -r '.skills | group_by(.category) | .[] | .[0].category' "$SKILL_REGISTRY" 2>/dev/null | sort -u
}

# ============================================================================
# REGISTRY MANAGEMENT
# ============================================================================

register_skill() {
  local skill_file="$1"
  
  # Validate skill file exists
  if [[ ! -f "$skill_file" ]]; then
    log_error "Skill file not found: $skill_file"
    return 1
  fi
  
  # Parse skill metadata from frontmatter
  local skill_id
  skill_id=$(grep -E "^id:" "$skill_file" | head -1 | cut -d: -f2 | xargs || echo "")
  
  if [[ -z "$skill_id" ]]; then
    # Derive from filename
    skill_id=$(basename "$skill_file" .md)
  fi
  
  log_info "Registering skill: $skill_id"
  
  # Add to registry (would use jq in production)
  # This is a simplified version
  log_warn "Auto-registration requires manual registry update"
  log_info "Add this to skills/registry.json:"
  echo "  \"$skill_id\": { ... }"
  
  return 0
}

# ============================================================================
# LEGACY FALLBACK
# ============================================================================

execute_legacy_skill() {
  local skill_path="$1"
  local input_json="$2"
  
  log_info "Executing legacy skill: $skill_path"
  
  # Legacy execution: source the skill markdown and execute
  # This maintains backward compatibility
  
  if [[ -f "${PLATFORM_DIR}/skills/${skill_path}.md" ]]; then
    # Use existing skill execution logic
    echo "Legacy execution not yet implemented"
    return 1
  fi
  
  log_error "Legacy skill not found: $skill_path"
  return 1
}

# ============================================================================
# LOGGING HELPERS
# ============================================================================

log_debug() { [[ "${SDL_DEBUG:-0}" == "1" ]] && echo -e "${BLUE}[DEBUG]${NC} $*" >&2 || true; }
log_info() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}✓${NC} $*" >&2; }
