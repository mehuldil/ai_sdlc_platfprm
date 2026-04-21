#!/usr/bin/env bash
################################################################################
# Unified Module System — Smart KB Loading
# Detects change type → loads ONLY relevant contracts + knowledge
# Saves 70% tokens (2-3K vs 12K full load)
################################################################################

set -eo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

REPO_PATH="${2:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"
MODULE_DIR="$REPO_PATH/.sdlc/module"
CACHE_DIR="$MODULE_DIR/cache"
mkdir -p "$CACHE_DIR"

if [[ ! -d "$MODULE_DIR" ]]; then
  log_error "Module system not initialized. Run: sdlc module init"
  exit 1
fi

# Read stack from meta.json
STACK=$(grep -o '"stack": "[^"]*"' "$MODULE_DIR/meta.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")

################################################################################
# CHANGE DETECTION — Multi-stack
################################################################################

detect_change_type() {
  local diff_output
  diff_output=$(cd "$REPO_PATH" && git diff --name-only 2>/dev/null || echo "")
  [[ -z "$diff_output" ]] && diff_output=$(cd "$REPO_PATH" && git diff --cached --name-only 2>/dev/null || echo "")
  [[ -z "$diff_output" ]] && diff_output=$(cd "$REPO_PATH" && git diff HEAD~1..HEAD --name-only 2>/dev/null || echo "")

  local has_api=0 has_data=0 has_events=0

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local full_path="$REPO_PATH/$file"

    # API changes (multi-stack)
    case "$file" in
      *Controller.java|*Controller.kt|*Router.js|*Route.ts|*route*.js|*route*.ts)
        has_api=1 ;;
    esac
    [[ -f "$full_path" ]] && grep -q '@RequestMapping\|@GetMapping\|@PostMapping\|@GET\|@POST\|router\.get\|router\.post\|app\.get\|app\.post\|URLSession\|Alamofire\|AF\.' "$full_path" 2>/dev/null && has_api=1

    # Data changes (multi-stack)
    case "$file" in
      *.sql|*migration*|*Entity.java|*Entity.kt|*Model.swift|*+CoreDataClass.swift|*schema*|*model*.js|*model*.ts)
        has_data=1 ;;
    esac
    [[ -f "$full_path" ]] && grep -q '@Entity\|@Dao\|@Database\|NSManagedObject\|CoreData\|mongoose\.Schema\|sequelize' "$full_path" 2>/dev/null && has_data=1

    # Event changes (multi-stack)
    case "$file" in
      *Kafka*|*kafka*|*EventBus*|*event*bus*)
        has_events=1 ;;
    esac
    [[ -f "$full_path" ]] && grep -q 'KafkaTemplate\|@KafkaListener\|ProducerRecord\|EventBus\|LiveData\|MutableLiveData\|SharedFlow\|NotificationCenter\|PassthroughSubject\|EventEmitter' "$full_path" 2>/dev/null && has_events=1

  done <<< "$diff_output"

  if [[ $has_events -eq 1 ]]; then echo "events"
  elif [[ $has_api -eq 1 ]]; then echo "api"
  elif [[ $has_data -eq 1 ]]; then echo "data"
  else echo "logic"
  fi
}

################################################################################
# CACHE CHECK — 1-hour TTL
################################################################################

check_cache() {
  local type="$1"
  local cache_file="$CACHE_DIR/last-load-${type}.md"

  if [[ -f "$cache_file" ]]; then
    local cache_age
    local file_time=$(stat -c%Y "$cache_file" 2>/dev/null || stat -f%m "$cache_file" 2>/dev/null || echo 0)
    local now=$(date +%s)
    cache_age=$(( now - file_time ))

    # Cache TTL is configurable via SDL_MODULE_CACHE_TTL (seconds). Default 3600 (1h).
    # For focused single-day work: export SDL_MODULE_CACHE_TTL=86400 (24h).
    local ttl="${SDL_MODULE_CACHE_TTL:-3600}"
    if [[ $cache_age -lt $ttl ]]; then
      log_info "Using cached load ($(( cache_age / 60 ))m old, TTL: $(( ttl / 60 ))m)"
      cat "$cache_file"
      return 0
    fi
  fi
  return 1
}

################################################################################
# SMART LOAD — Build context for AI
################################################################################

build_smart_load() {
  local change_type="$1"
  local output_file="$CACHE_DIR/last-load-${change_type}.md"

  cat > "$output_file" << EOF
# Smart Module Context — $change_type change
**Loaded:** $(date -u +"%Y-%m-%dT%H:%M:%SZ") | **Stack:** $STACK

EOF

  # Always include: impact rules + relevant contract
  case "$change_type" in
    api)
      echo "## API Contract" >> "$output_file"
      [[ -f "$MODULE_DIR/contracts/api.yaml" ]] && cat "$MODULE_DIR/contracts/api.yaml" >> "$output_file"
      echo "" >> "$output_file"
      echo "## Dependencies" >> "$output_file"
      [[ -f "$MODULE_DIR/contracts/dependencies.yaml" ]] && cat "$MODULE_DIR/contracts/dependencies.yaml" >> "$output_file"
      ;;
    data)
      echo "## Data Contract" >> "$output_file"
      [[ -f "$MODULE_DIR/contracts/data.yaml" ]] && cat "$MODULE_DIR/contracts/data.yaml" >> "$output_file"
      ;;
    events)
      echo "## Event Contract" >> "$output_file"
      [[ -f "$MODULE_DIR/contracts/events.yaml" ]] && cat "$MODULE_DIR/contracts/events.yaml" >> "$output_file"
      echo "" >> "$output_file"
      echo "## Dependencies" >> "$output_file"
      [[ -f "$MODULE_DIR/contracts/dependencies.yaml" ]] && cat "$MODULE_DIR/contracts/dependencies.yaml" >> "$output_file"
      ;;
    logic)
      echo "## Module Manifest" >> "$output_file"
      [[ -f "$MODULE_DIR/knowledge/manifest.md" ]] && cat "$MODULE_DIR/knowledge/manifest.md" >> "$output_file"
      ;;
    all)
      for f in "$MODULE_DIR/contracts"/*.yaml "$MODULE_DIR/knowledge"/*.md; do
        [[ -f "$f" ]] && { echo "---"; echo "## $(basename "$f")"; cat "$f"; echo ""; } >> "$output_file"
      done
      ;;
  esac

  # Always append impact rules and known issues
  if [[ "$change_type" != "all" ]]; then
    echo "" >> "$output_file"
    echo "## Impact Rules" >> "$output_file"
    [[ -f "$MODULE_DIR/knowledge/impact-rules.md" ]] && cat "$MODULE_DIR/knowledge/impact-rules.md" >> "$output_file"
    echo "" >> "$output_file"
    echo "## Known Issues (Recent)" >> "$output_file"
    [[ -f "$MODULE_DIR/knowledge/known-issues.md" ]] && head -15 "$MODULE_DIR/knowledge/known-issues.md" >> "$output_file"
  fi

  local size=$(wc -c < "$output_file")
  local tokens=$(( size / 4 ))  # Rough estimate: 4 chars per token

  echo ""
  echo -e "${CYAN}Loaded: ~${tokens} tokens (${size} bytes)${NC}"
  echo -e "${CYAN}Full KB would be ~12,000 tokens — saved ~$(( 100 - (tokens * 100 / 12000) ))%${NC}"
  echo ""

  cat "$output_file"
}

################################################################################
# MAIN
################################################################################

main() {
  local explicit_type="${1:-}"

  echo ""
  echo -e "${CYAN}═══════════════════════════════════════════${NC}"
  echo -e "${CYAN}MODULE SYSTEM — SMART LOAD${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════${NC}"
  echo ""

  local change_type
  if [[ -n "$explicit_type" && "$explicit_type" =~ ^(api|data|events|logic|all)$ ]]; then
    change_type="$explicit_type"
    log_success "Explicit load type: $change_type"
  else
    log_info "Auto-detecting change type from git diff..."
    change_type=$(detect_change_type)
    log_success "Detected: $change_type"
  fi

  # Check cache first
  if [[ "$change_type" != "all" ]] && check_cache "$change_type"; then
    return 0
  fi

  build_smart_load "$change_type"
}

main "$@"
