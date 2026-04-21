#!/usr/bin/env bash
# Module Knowledgebase Viewer — kb-show.sh
set -eo pipefail

BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

REPO_PATH="${2:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

KB_DIR="$REPO_PATH/.sdlc/module-kb"
SECTION="${1:-summary}"
FILTER="${3:-}"

if [[ ! -d "$KB_DIR" ]]; then
  echo -e "${RED}[ERROR]${NC} Module KB not found at: $KB_DIR"
  echo "Initialize with: sdlc kb init [path]"
  exit 1
fi

show_header() {
  echo ""
  echo -e "${BOLD}${BLUE}=== $1 ===${NC}"
  echo ""
}

show_summary() {
  show_header "Module Knowledgebase Summary"
  echo "Available sections:"
  for file in "$KB_DIR"/*.md "$KB_DIR"/*.json; do
    if [[ -f "$file" ]]; then
      local name=$(basename "$file")
      local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
      printf "  %-25s %6d bytes\n" "$name" "$size"
    fi
  done
}

show_file() {
  local file="$1"
  local title="$2"
  
  if [[ ! -f "$KB_DIR/$file" ]]; then
    echo -e "${RED}[ERROR]${NC} File not found: $KB_DIR/$file"
    exit 1
  fi
  
  show_header "$title"
  
  if [[ -n "$FILTER" ]]; then
    grep -A5 "$FILTER" "$KB_DIR/$file" 2>/dev/null | head -50 || {
      echo "No matches for: $FILTER"
    }
  else
    cat "$KB_DIR/$file"
  fi
}

case "$SECTION" in
  summary|"") show_summary ;;
  manifest|modules) show_file "module-manifest.md" "Module Manifest" ;;
  api|endpoints) show_file "api-surface.md" "API Surface" ;;
  data|schema|database) show_file "data-model.md" "Data Model" ;;
  events|kafka|topics) show_file "event-topology.md" "Event Topology" ;;
  deps|dependencies) show_file "dependency-map.md" "Dependency Map" ;;
  tech|decisions|adr) show_file "tech-decisions.md" "Tech Decisions" ;;
  issues|bugs) show_file "known-issues.md" "Known Issues" ;;
  impact|rules) show_file "change-impact-rules.md" "Change Impact Rules" ;;
  help|--help|-h)
    cat << 'HELP'
Module Knowledgebase Viewer

Usage: kb-show.sh [section] [filter]

Sections:
  (none)      Summary
  manifest    Module structure
  api         API endpoints
  data|schema Database schema
  events|kafka Kafka topics
  deps        Dependencies
  tech        Tech decisions
  issues|bugs Known issues
  impact      Change impact rules

HELP
    ;;
  *)
    echo -e "${RED}[ERROR]${NC} Unknown section: $SECTION"
    exit 1
    ;;
esac

echo ""
