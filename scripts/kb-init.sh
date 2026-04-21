#!/usr/bin/env bash
# Module Knowledgebase Initializer — kb-init.sh
set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

if [[ ! -d "$REPO_PATH/.git" ]]; then
  log_error "Not a git repository: $REPO_PATH"
  exit 1
fi

KB_DIR="$REPO_PATH/.sdlc/module-kb"
mkdir -p "$KB_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT_HASH=$(cd "$REPO_PATH" && git rev-parse HEAD 2>/dev/null || echo "unknown")

log_info "Initializing Module Knowledgebase for: $REPO_PATH"
log_info "Output directory: $KB_DIR"
echo ""

# Detect stack
detect_stack() {
  local has_pom=0
  local has_gradle=0
  local has_package_json=0
  local has_metro=0
  local has_makefile=0

  [[ -f "$REPO_PATH/pom.xml" ]] && has_pom=1
  [[ -f "$REPO_PATH/build.gradle" || -f "$REPO_PATH/build.gradle.kts" ]] && has_gradle=1
  [[ -f "$REPO_PATH/package.json" ]] && has_package_json=1
  [[ -f "$REPO_PATH/metro.config.js" ]] && has_metro=1
  [[ -f "$REPO_PATH/Makefile" || -f "$REPO_PATH/CMakeLists.txt" ]] && has_makefile=1

  if [[ $has_pom -eq 1 || $has_gradle -eq 1 ]]; then
    echo "java"
  elif [[ $has_package_json -eq 1 && $has_metro -eq 1 ]]; then
    echo "react-native"
  elif [[ $has_package_json -eq 1 ]]; then
    echo "node"
  elif [[ $has_makefile -eq 1 ]]; then
    echo "c"
  else
    echo "unknown"
  fi
}

STACK=$(detect_stack)
log_success "Detected stack: $STACK"
echo ""

# Create Module Manifest
create_module_manifest() {
  log_info "Scanning Java modules..."
  local manifest_file="$KB_DIR/module-manifest.md"
  cat > "$manifest_file" << 'MANIFEST_HEADER'
# Module Manifest

**Stack:** java

## Source Directories
MANIFEST_HEADER

  find "$REPO_PATH" -path "*/src/main/java/*" -type d -name "*" 2>/dev/null | head -30 | while read -r dir; do
    local rel_path="${dir#$REPO_PATH/}"
    echo "- $rel_path" >> "$manifest_file"
  done

  cat >> "$manifest_file" << 'MANIFEST_MIDDLE'

## Controllers

MANIFEST_MIDDLE

  find "$REPO_PATH/src/main/java" -name "*Controller.java" 2>/dev/null | head -20 | while read -r file; do
    local class_name=$(basename "$file" .java)
    echo "- $class_name" >> "$manifest_file"
  done

  cat >> "$manifest_file" << 'MANIFEST_END'

**Generated:** $TIMESTAMP
**Commit:** ${COMMIT_HASH:0:8}

MANIFEST_END

  log_success "Created: module-manifest.md"
}

# Create API Surface
create_api_surface() {
  log_info "Scanning API endpoints..."
  local api_file="$KB_DIR/api-surface.md"
  cat > "$api_file" << 'API_HEADER'
# API Surface

**Generated:** $TIMESTAMP
**Commit:** ${COMMIT_HASH:0:8}

## REST Endpoints

Scan api-surface.md for endpoint mappings.

API_HEADER

  log_success "Created: api-surface.md"
}

# Create Data Model
create_data_model() {
  log_info "Scanning data model..."
  local data_file="$KB_DIR/data-model.md"
  cat > "$data_file" << 'DATA_HEADER'
# Data Model

**Generated:** $TIMESTAMP
**Commit:** ${COMMIT_HASH:0:8}

## Database Migrations

Review migration files for schema details.

## Entities

Check @Entity classes for data mappings.

DATA_HEADER

  log_success "Created: data-model.md"
}

# Create Event Topology
create_event_topology() {
  log_info "Scanning event topology..."
  local event_file="$KB_DIR/event-topology.md"
  cat > "$event_file" << 'EVENT_HEADER'
# Event Topology

**Generated:** $TIMESTAMP
**Commit:** ${COMMIT_HASH:0:8}
**Stack:** $STACK

## Kafka Topics

Check application.properties and code for Kafka topics.

EVENT_HEADER

  log_success "Created: event-topology.md"
}

# Create Dependency Map
create_dependency_map() {
  log_info "Scanning dependency map..."
  local dep_file="$KB_DIR/dependency-map.md"
  cat > "$dep_file" << 'DEP_HEADER'
# Dependency Map

**Generated:** $TIMESTAMP
**Commit:** ${COMMIT_HASH:0:8}

## External Dependencies

See pom.xml or build.gradle for complete list.

DEP_HEADER

  log_success "Created: dependency-map.md"
}

# Create Tech Decisions
create_tech_decisions() {
  log_info "Scanning tech decisions..."
  local tech_file="$KB_DIR/tech-decisions.md"
  cat > "$tech_file" << 'TECH_HEADER'
# Tech Decisions

**Generated:** $TIMESTAMP
**Commit:** ${COMMIT_HASH:0:8}
**Stack:** $STACK

## Frameworks

See pom.xml or build.gradle for version details.

TECH_HEADER

  log_success "Created: tech-decisions.md"
}

# Create Known Issues
create_known_issues() {
  log_info "Scanning known issues..."
  local issues_file="$KB_DIR/known-issues.md"
  cat > "$issues_file" << 'ISSUES_HEADER'
# Known Issues & Bug History

**Generated:** $TIMESTAMP
**Commit:** ${COMMIT_HASH:0:8}

## Recent Bug Fixes

ISSUES_HEADER

  cd "$REPO_PATH"
  git log --oneline --grep="fix\|bug" -i 2>/dev/null | head -20 | while read -r line; do
    echo "- $line" >> "$issues_file"
  done || true

  log_success "Created: known-issues.md"
}

# Create Change Impact Rules
create_impact_rules() {
  log_info "Generating change-impact rules..."
  local impact_file="$KB_DIR/change-impact-rules.md"
  cat > "$impact_file" << 'IMPACT_HEADER'
# Change Impact Rules

**Generated:** $TIMESTAMP
**Commit:** ${COMMIT_HASH:0:8}

## Impact Matrix

| Component | Impact |
|-----------|--------|
| Controllers | Check service layer and API contracts |
| Services | Check repository and other service calls |
| Repositories | Check database migrations |
| Entities | Check migrations and API serialization |
| Config Files | Check all dependent code |

IMPACT_HEADER

  log_success "Created: change-impact-rules.md"
}

# Create Last Scan Metadata
create_scan_metadata() {
  log_info "Saving scan metadata..."
  local last_scan_file="$KB_DIR/last-scan.json"
  cat > "$last_scan_file" << SCAN_META
{
  "timestamp": "$TIMESTAMP",
  "commit": "$COMMIT_HASH",
  "stack": "$STACK",
  "repo_path": "$REPO_PATH"
}
SCAN_META

  log_success "Created: last-scan.json"
}

# Main
case "$STACK" in
  java)
    create_module_manifest
    ;;
  *)
    log_warn "Stack: $STACK - using basic scan"
    ;;
esac

create_api_surface
create_data_model
create_event_topology
create_dependency_map
create_tech_decisions
create_known_issues
create_impact_rules
create_scan_metadata

echo ""
log_success "Module Knowledgebase initialized at: $KB_DIR"
