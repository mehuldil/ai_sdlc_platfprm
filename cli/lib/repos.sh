#!/usr/bin/env bash
# cli/lib/repos.sh — Multi-Repository Management
# Part of AI SDLC Platform v2.0.0
# -----------------------------------------------------------

# ============================================================================
# CONFIGURATION
# ============================================================================

REPOS_FILE="${CONFIG_DIR}/repos.json"
REPOS_DIR="${CONFIG_DIR}/repos.d"

# ============================================================================
# REPO REGISTRY MANAGEMENT
# ============================================================================

# Initialize repos.json if missing
_repos_init() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$REPOS_DIR"
    
    if [[ ! -f "$REPOS_FILE" ]]; then
        cat > "$REPOS_FILE" << 'EOF'
{
  "version": "2.0.0",
  "last_updated": "",
  "repos": [],
  "default_repo": ""
}
EOF
    fi
}

# Get repo ID from path
_repos_get_id() {
    local path="$1"
    basename "$path" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g'
}

# Detect repo info from directory
_repos_detect_info() {
    local path="$1"
    local repo_id=$(_repos_get_id "$path")
    local name=$(basename "$path")
    local stack="unknown"
    local type="unknown"
    local detected="false"
    
    # Only detect if it's a real project
    if [[ -f "$path/pom.xml" ]] || [[ -f "$path/build.gradle" ]] || [[ -f "$path/build.gradle.kts" ]]; then
        stack="java-tej"
        type="microservice"
        detected="true"
    elif [[ -f "$path/package.json" ]]; then
        if grep -q "react-native" "$path/package.json" 2>/dev/null; then
            stack="react-native"
        else
            stack="javascript"
        fi
        type="frontend"
        detected="true"
    elif [[ -f "$path/go.mod" ]]; then
        stack="go"
        type="microservice"
        detected="true"
    elif [[ -d "$path/ios" ]] && [[ -f "$path/Podfile" ]]; then
        stack="swift-ios"
        type="mobile"
        detected="true"
    elif [[ -f "$path/build.gradle" ]] && [[ -d "$path/src/main/kotlin" ]]; then
        stack="kotlin-android"
        type="mobile"
        detected="true"
    fi
    
    # Check if git repo
    if [[ -d "$path/.git" ]]; then
        detected="true"
    fi
    
    # Output as JSON
    jq -n \
        --arg id "$repo_id" \
        --arg name "$name" \
        --arg path "$path" \
        --arg type "$type" \
        --arg stack "$stack" \
        --arg detected "$detected" \
        '{id: $id, name: $name, path: $path, type: $type, stack: $stack, detected: $detected, dependencies: [], dependents: [], team: "default", ado_project: "", active: false}'
}

# Auto-detect repos in common directories
_repos_auto_detect() {
    _repos_init
    
    local search_dirs=(
        "${HOME}/projects"
        "${HOME}/workspace"
        "${HOME}/code"
        "${HOME}/src"
        "${HOME}/development"
        "${HOME}/YourAzureProject"
    )
    
    # Also check common parent of platform
    local platform_parent=$(dirname "$PLATFORM_DIR")
    if [[ -d "$platform_parent" ]] && [[ "$platform_parent" != "$HOME" ]]; then
        search_dirs+=("$platform_parent")
    fi
    
    # Add SDL_PROJECTS_ROOT if set
    if [[ -n "${SDL_PROJECTS_ROOT:-}" ]]; then
        search_dirs+=("$SDL_PROJECTS_ROOT")
    fi
    
    log_info "Searching for repos..."
    local found=0
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            # Look for subdirectories that look like repos
            while IFS= read -r -d '' repo_path; do
                # Skip hidden dirs and platform itself
                local repo_name=$(basename "$repo_path")
                if [[ "$repo_name" == .* ]] || [[ "$repo_path" == "$PLATFORM_DIR" ]]; then
                    continue
                fi
                
                # Detect repo info
                local repo_info=$(_repos_detect_info "$repo_path")
                local is_detected=$(echo "$repo_info" | jq -r '.detected')
                
                if [[ "$is_detected" == "true" ]]; then
                    # Add if not already registered
                    local repo_id=$(echo "$repo_info" | jq -r '.id')
                    if ! _repos_exists "$repo_id"; then
                        _repos_add_json "$repo_info"
                        ((found++))
                        log_info "Found: $repo_name ($repo_id)"
                    fi
                fi
            done < <(find "$dir" -maxdepth 1 -type d -print0 2>/dev/null)
        fi
    done
    
    log_success "Auto-detected $found repos"
}

# Check if repo exists in registry
_repos_exists() {
    local repo_id="$1"
    jq -e ".repos | map(select(.id == \"$repo_id\")) | length > 0" "$REPOS_FILE" >/dev/null 2>&1
}

# Add repo JSON to registry
_repos_add_json() {
    local repo_json="$1"
    
    local tmp=$(mktemp)
    jq ".repos += [$repo_json] | .last_updated = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$REPOS_FILE" > "$tmp"
    mv "$tmp" "$REPOS_FILE"
}

# Add current/specified repo to registry
cmd_repos_add() {
    local repo_path="${1:-$(pwd)}"
    
    # Resolve path
    repo_path=$(cd "$repo_path" 2>/dev/null && pwd) || {
        log_error "Path not found: $repo_path"
        return 1
    }
    
    _repos_init
    
    local repo_info=$(_repos_detect_info "$repo_path")
    local repo_id=$(echo "$repo_info" | jq -r '.id')
    local repo_name=$(echo "$repo_info" | jq -r '.name')
    
    if _repos_exists "$repo_id"; then
        # Update existing
        local tmp=$(mktemp)
        jq ".repos |= map(if .id == \"$repo_id\" then .path = \"$repo_path\" else . end)" "$REPOS_FILE" > "$tmp"
        mv "$tmp" "$REPOS_FILE"
        log_warn "Updated: $repo_name (already registered)"
    else
        # Add new
        _repos_add_json "$repo_info"
        log_success "Added: $repo_name ($repo_id)"
    fi
    
    # Auto-initialize .sdlc if missing
    if [[ ! -d "$repo_path/.sdlc" ]] && [[ -f "$PLATFORM_DIR/cli/sdlc-setup.sh" ]]; then
        log_info "Initializing .sdlc for $repo_name..."
        bash "$PLATFORM_DIR/cli/sdlc-setup.sh" "$repo_path" 2>/dev/null || true
    fi
}

# List all registered repos
cmd_repos_list() {
    _repos_init
    
    local count=$(jq '.repos | length' "$REPOS_FILE")
    if [[ "$count" -eq 0 ]]; then
        log_warn "No repos registered. Run: sdlc repos add"
        return 0
    fi
    
    local default_repo=$(jq -r '.default_repo // ""' "$REPOS_FILE")
    
    log_section "Registered Repositories ($count)"
    
    jq -r --arg default "$default_repo" '.repos[] | 
        (if .id == $default then "→ " else "  " end) +
        .id + " (" + .stack + ")" +
        "\n   Path: " + .path +
        "\n   Type: " + .type + " | Team: " + .team +
        (if (.dependencies | length) > 0 then "\n   Deps: " + (.dependencies | join(", ")) else "" end) +
        (if (.dependents | length) > 0 then "\n   Used by: " + (.dependents | join(", ")) else "" end) +
        "\n"' \
        "$REPOS_FILE"
}

# Switch to a repo (set as default)
cmd_repos_switch() {
    local repo_id="$1"
    
    if [[ -z "$repo_id" ]]; then
        log_error "Usage: sdlc repos switch <repo-id>"
        return 1
    fi
    
    _repos_init
    
    if ! _repos_exists "$repo_id"; then
        log_error "Repo '$repo_id' not found. Run: sdlc repos list"
        return 1
    fi
    
    # Update default
    local tmp=$(mktemp)
    jq ".default_repo = \"$repo_id\"" "$REPOS_FILE" > "$tmp"
    mv "$tmp" "$REPOS_FILE"
    
    # Get path
    local repo_path=$(jq -r ".repos[] | select(.id == \"$repo_id\") | .path" "$REPOS_FILE")
    
    # Update shell config
    echo "SDLC_PROJECT_DIR=$repo_path" >> "${CONFIG_DIR}/config"
    
    log_success "Switched to: $repo_id"
    log_info "Path: $repo_path"
    log_info "Run: cd $repo_path"
}

# Show dependency graph
cmd_repos_deps() {
    _repos_init
    
    log_section "Repository Dependencies"
    
    local has_deps=false
    
    # Show dependencies
    jq -r '.repos[] | select(.dependencies | length > 0) | 
        .id + " → " + (.dependencies | join(", "))' \
        "$REPOS_FILE" 2>/dev/null | while read line; do
            if [[ -n "$line" ]]; then
                echo "  $line"
                has_deps=true
            fi
        done
    
    # Show dependents
    jq -r '.repos[] | select(.dependents | length > 0) | 
        .id + " ← " + (.dependents | join(", "))' \
        "$REPOS_FILE" 2>/dev/null | while read line; do
            if [[ -n "$line" ]]; then
                echo "  $line"
                has_deps=true
            fi
        done
    
    if [[ "$has_deps" == "false" ]]; then
        log_info "No dependencies set. Use: sdlc repos depend <from> <to>"
    fi
}

# Set dependency between repos
cmd_repos_depend() {
    local from_repo="$1"
    local to_repo="$2"
    
    if [[ -z "$from_repo" ]] || [[ -z "$to_repo" ]]; then
        log_error "Usage: sdlc repos depend <repo> <depends-on-repo>"
        log_info "Example: sdlc repos depend tej-auth-service tej-security"
        return 1
    fi
    
    _repos_init
    
    # Validate repos exist
    if ! _repos_exists "$from_repo"; then
        log_error "Repo '$from_repo' not found"
        return 1
    fi
    if ! _repos_exists "$to_repo"; then
        log_error "Repo '$to_repo' not found"
        return 1
    fi
    
    # Update from_repo dependencies
    local tmp=$(mktemp)
    jq ".repos |= map(if .id == \"$from_repo\" then .dependencies += [\"$to_repo\"] | .dependencies |= unique else . end)" \
        "$REPOS_FILE" > "$tmp"
    mv "$tmp" "$REPOS_FILE"
    
    # Update to_repo dependents
    tmp=$(mktemp)
    jq ".repos |= map(if .id == \"$to_repo\" then .dependents += [\"$from_repo\"] | .dependents |= unique else . end)" \
        "$REPOS_FILE" > "$tmp"
    mv "$tmp" "$REPOS_FILE"
    
    log_success "Dependency set: $from_repo → $to_repo"
}

# Check for breaking changes before commit
cmd_repos_check() {
    local repo_id="${1:-}"
    
    # Auto-detect current repo if not specified
    if [[ -z "$repo_id" ]]; then
        repo_id=$(_repos_get_id "$(pwd)")
    fi
    
    _repos_init
    
    if ! _repos_exists "$repo_id"; then
        log_error "Repo '$repo_id' not found"
        return 1
    fi
    
    local dependents=$(jq -r ".repos[] | select(.id == \"$repo_id\") | .dependents | join(\", \")" "$REPOS_FILE")
    
    log_section "Breaking Change Check: $repo_id"
    
    if [[ -z "$dependents" ]] || [[ "$dependents" == "null" ]]; then
        log_success "No dependent repos — changes are safe"
        return 0
    fi
    
    log_warn "Changes may affect: $dependents"
    log_info "Recommendations:"
    log_info "  1. Run tests in dependent repos"
    log_info "  2. Notify teams via: sdlc repos notify $repo_id"
    
    # Show dependent repo paths
    for dep_id in ${dependents//,/ }; do
        local dep_path=$(jq -r ".repos[] | select(.id == \"$dep_id\") | .path" "$REPOS_FILE")
        log_info "     $dep_id: $dep_path"
    done
}

# Notify dependent repos of changes
cmd_repos_notify() {
    local repo_id="$1"
    
    if [[ -z "$repo_id" ]]; then
        log_error "Usage: sdlc repos notify <repo-id>"
        return 1
    fi
    
    _repos_init
    
    local dependents=$(jq -r ".repos[] | select(.id == \"$repo_id\") | .dependents[]?" "$REPOS_FILE" 2>/dev/null)
    
    if [[ -z "$dependents" ]]; then
        log_info "No repos depend on '$repo_id'"
        return 0
    fi
    
    log_section "Notifying Dependents of $repo_id Changes"
    
    for dep_id in $dependents; do
        local dep_path=$(jq -r ".repos[] | select(.id == \"$dep_id\") | .path" "$REPOS_FILE")
        if [[ -n "$dep_path" ]] && [[ "$dep_path" != "null" ]]; then
            # Create notification file
            local notif_dir="$dep_path/.sdlc/notifications"
            mkdir -p "$notif_dir"
            
            cat > "$notif_dir/dep-update-$(date +%s).json" << EOF
{
  "type": "dependency_updated",
  "source_repo": "$repo_id",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "message": "Dependency '$repo_id' has been updated. Review for breaking changes.",
  "action_required": "Run tests and verify compatibility"
}
EOF
            log_success "Notified: $dep_id"
        fi
    done
}

# Show repos help
cmd_repos_help() {
    cat << 'EOF'
Multi-Repository Management

Usage: sdlc repos <command> [options]

Commands:
  add [path]              Register current or specified repo
  list                    List all registered repos
  switch <repo-id>        Switch context to repo
  detect                  Auto-detect repos in ~/projects, ~/workspace, etc.
  
  depend <a> <b>          Set repo A depends on repo B
  deps                    Show dependency graph
  check [repo-id]         Check impact on dependent repos
  notify <repo-id>        Notify dependents of changes

Auto-Detection:
  During setup.sh, repos are auto-detected in common directories.
  Set SDL_PROJECTS_ROOT to add custom search path.

Examples:
  # Register current repo
  sdlc repos add
  
  # Register specific repo
  sdlc repos add ~/projects/TejAuthService
  
  # Set dependencies
  sdlc repos depend tej-auth-service tej-security
  
  # Before committing shared library changes
  sdlc repos check tej-security
  sdlc repos notify tej-security

Configuration: ~/.sdlc/repos.json
EOF
}
