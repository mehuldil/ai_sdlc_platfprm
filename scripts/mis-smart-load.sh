#!/usr/bin/env bash
################################################################################
# Module Intelligence System — Smart KB Loading
# Detects change type and loads ONLY relevant knowledge sections
# Reduces KB loading from 12K to 2-3K tokens per change
################################################################################

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
CACHE_DIR="$REPO_PATH/.sdlc/cache"
MEMORY_DIR="$REPO_PATH/.sdlc/memory"
mkdir -p "$KB_DIR" "$CACHE_DIR" "$MEMORY_DIR"

detect_change_type() {
  local diff_output
  local has_controller=0
  local has_sql=0
  local has_kafka=0

  diff_output=$(cd "$REPO_PATH" && git diff --name-only 2>/dev/null || echo "")

  if [[ -z "$diff_output" ]]; then
    diff_output=$(cd "$REPO_PATH" && git diff --cached --name-only 2>/dev/null || echo "")
  fi

  if [[ -z "$diff_output" ]]; then
    diff_output=$(cd "$REPO_PATH" && git diff HEAD~1..HEAD --name-only 2>/dev/null || echo "")
  fi

  while IFS= read -r file; do
    if [[ "$file" == *"Controller.java" ]] || [[ "$file" == *"RestController" ]] || \
       grep -q "@RequestMapping\|@GetMapping\|@PostMapping\|@RestController" "$REPO_PATH/$file" 2>/dev/null; then
      has_controller=1
    fi

    if [[ "$file" == *.sql ]] || [[ "$file" == *"migration"* ]] || \
       [[ "$file" == *"Repository.java" ]] || [[ "$file" == *"Entity.java" ]]; then
      has_sql=1
    fi

    if [[ "$file" == *"Kafka"* ]] || grep -q "ProducerRecord\|KafkaTemplate\|@KafkaListener" "$REPO_PATH/$file" 2>/dev/null; then
      has_kafka=1
    fi
  done <<< "$diff_output"

  if [[ $has_kafka -eq 1 ]]; then
    echo "events"
  elif [[ $has_controller -eq 1 ]]; then
    echo "api"
  elif [[ $has_sql -eq 1 ]]; then
    echo "data"
  else
    echo "logic"
  fi
}

main() {
  local explicit_type="${1:-}"
  local change_type

  log_info "Module Intelligence System — Smart KB Load"
  echo ""

  if [[ -n "$explicit_type" && "$explicit_type" != "." ]]; then
    if [[ "$explicit_type" =~ ^(api|data|events|logic|all)$ ]]; then
      change_type="$explicit_type"
      log_success "Using explicit change type: $change_type"
    else
      log_error "Invalid change type: $explicit_type (use: api|data|events|logic|all)"
      return 1
    fi
  else
    log_info "Detecting change type from git diff..."
    change_type=$(detect_change_type)
    log_success "Detected change type: $change_type"
  fi

  echo ""
  log_success "Smart KB loading initialized for: $change_type"
}

main "$@"
