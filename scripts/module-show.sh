#!/usr/bin/env bash
################################################################################
# Unified Module System — Viewer
# View contracts, knowledge, or summary
################################################################################

set -eo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

REPO_PATH="${2:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"
MODULE_DIR="$REPO_PATH/.sdlc/module"
SECTION="${1:-summary}"
FILTER="${3:-}"

if [[ ! -d "$MODULE_DIR" ]]; then
  echo -e "${RED}[ERROR]${NC} Module system not initialized at: $MODULE_DIR"
  echo "Run: sdlc module init"
  exit 1
fi

show_header() {
  echo ""
  echo -e "${BOLD}${CYAN}=== $1 ===${NC}"
  echo ""
}

show_file() {
  local file="$1"
  local title="$2"

  if [[ ! -f "$file" ]]; then
    echo -e "${RED}[ERROR]${NC} Not found: $file"
    return 1
  fi

  show_header "$title"

  if [[ -n "$FILTER" ]]; then
    grep -A5 "$FILTER" "$file" 2>/dev/null | head -50 || echo "No matches for: $FILTER"
  else
    cat "$file"
  fi
}

show_summary() {
  show_header "Module System Summary"

  local stack=$(grep -o '"stack": "[^"]*"' "$MODULE_DIR/meta.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
  local timestamp=$(grep -o '"timestamp": "[^"]*"' "$MODULE_DIR/meta.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
  local commit=$(grep -o '"commit": "[^"]*"' "$MODULE_DIR/meta.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")

  echo "Stack: $stack | Last scan: $timestamp | Commit: ${commit:0:8}"
  echo ""

  echo -e "${BOLD}Contracts:${NC}"
  for file in "$MODULE_DIR/contracts"/*.yaml; do
    if [[ -f "$file" ]]; then
      local name=$(basename "$file")
      local size=$(wc -c < "$file" 2>/dev/null || echo 0)
      printf "  %-25s %6d bytes\n" "$name" "$size"
    fi
  done

  echo ""
  echo -e "${BOLD}Knowledge:${NC}"
  for file in "$MODULE_DIR/knowledge"/*.md; do
    if [[ -f "$file" ]]; then
      local name=$(basename "$file")
      local size=$(wc -c < "$file" 2>/dev/null || echo 0)
      printf "  %-25s %6d bytes\n" "$name" "$size"
    fi
  done
}

case "$SECTION" in
  summary|"")       show_summary ;;
  api|endpoints)    show_file "$MODULE_DIR/contracts/api.yaml" "API Contract" ;;
  data|schema|db)   show_file "$MODULE_DIR/contracts/data.yaml" "Data Contract" ;;
  events|kafka)     show_file "$MODULE_DIR/contracts/events.yaml" "Event Contract" ;;
  deps|dependencies) show_file "$MODULE_DIR/contracts/dependencies.yaml" "Dependencies" ;;
  manifest|modules) show_file "$MODULE_DIR/knowledge/manifest.md" "Module Manifest" ;;
  issues|bugs)      show_file "$MODULE_DIR/knowledge/known-issues.md" "Known Issues" ;;
  impact|rules)     show_file "$MODULE_DIR/knowledge/impact-rules.md" "Impact Rules" ;;
  tech|decisions)   show_file "$MODULE_DIR/knowledge/tech-decisions.md" "Tech Decisions" ;;
  all)
    for f in "$MODULE_DIR/contracts"/*.yaml "$MODULE_DIR/knowledge"/*.md; do
      [[ -f "$f" ]] && { show_header "$(basename "$f")"; cat "$f"; }
    done
    ;;
  help|--help|-h)
    cat << 'HELP'
Module System Viewer

Usage: sdlc module show [section] [filter]

Sections:
  summary         Overview of all files (default)
  api             API contract (endpoints, consumers)
  data            Data contract (schemas, migrations)
  events          Event contract (Kafka/EventBus/Combine)
  deps            Dependencies (cross-pod + external)
  manifest        Module structure
  issues          Known issues from git
  impact          Change impact rules
  tech            Tech decisions
  all             Show everything

Filter:  sdlc module show api "UserController"

HELP
    ;;
  *)
    echo -e "${RED}[ERROR]${NC} Unknown section: $SECTION"
    echo "Run: sdlc module show help"
    exit 1
    ;;
esac

echo ""
