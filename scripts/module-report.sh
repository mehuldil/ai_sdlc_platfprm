#!/usr/bin/env bash
################################################################################
# Unified Module System — Impact Report
# Generates impact analysis for current changes
################################################################################

set -eo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"
MODULE_DIR="$REPO_PATH/.sdlc/module"
REPORT_DIR="$MODULE_DIR/cache"
mkdir -p "$REPORT_DIR"

if [[ ! -d "$MODULE_DIR" ]]; then
  echo -e "${RED}[ERROR]${NC} Module system not initialized. Run: sdlc module init"
  exit 1
fi

STACK=$(grep -o '"stack": "[^"]*"' "$MODULE_DIR/meta.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
REPO_NAME=$(basename "$REPO_PATH")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

REPORT="$REPORT_DIR/impact-report.md"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}MODULE SYSTEM — IMPACT REPORT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Get changed files
CHANGED=$(cd "$REPO_PATH" && git diff --name-only 2>/dev/null || echo "")
[[ -z "$CHANGED" ]] && CHANGED=$(cd "$REPO_PATH" && git diff --cached --name-only 2>/dev/null || echo "")
[[ -z "$CHANGED" ]] && CHANGED=$(cd "$REPO_PATH" && git diff HEAD~1..HEAD --name-only 2>/dev/null || echo "")

FILE_COUNT=$(echo "$CHANGED" | grep -c . || echo 0)

cat > "$REPORT" << EOF
# Impact Report — $REPO_NAME
**Generated:** $TIMESTAMP | **Stack:** $STACK | **Files changed:** $FILE_COUNT

## 1. Changed Files
EOF

echo "$CHANGED" | while read -r f; do
  [[ -n "$f" ]] && echo "- $f" >> "$REPORT"
done

cat >> "$REPORT" << EOF

## 2. Change Categories
EOF

# Categorize changes
api_files=$(echo "$CHANGED" | grep -E 'Controller\.|Route\.|router\.|route\.' || true)
data_files=$(echo "$CHANGED" | grep -E '\.sql|migration|Entity\.|Model\.|schema' || true)
event_files=$(echo "$CHANGED" | grep -iE 'kafka|event|listener|producer|consumer' || true)
config_files=$(echo "$CHANGED" | grep -E 'config|\.yml|\.yaml|\.properties|\.env' || true)
test_files=$(echo "$CHANGED" | grep -iE 'test|spec|__test' || true)

[[ -n "$api_files" ]] && { echo "### API Changes"; echo "$api_files" | while read -r f; do echo "- $f"; done; echo ""; } >> "$REPORT"
[[ -n "$data_files" ]] && { echo "### Data Changes"; echo "$data_files" | while read -r f; do echo "- $f"; done; echo ""; } >> "$REPORT"
[[ -n "$event_files" ]] && { echo "### Event Changes"; echo "$event_files" | while read -r f; do echo "- $f"; done; echo ""; } >> "$REPORT"
[[ -n "$config_files" ]] && { echo "### Config Changes"; echo "$config_files" | while read -r f; do echo "- $f"; done; echo ""; } >> "$REPORT"
[[ -n "$test_files" ]] && { echo "### Test Changes"; echo "$test_files" | while read -r f; do echo "- $f"; done; echo ""; } >> "$REPORT"

cat >> "$REPORT" << EOF

## 3. Risk Assessment
EOF

RISK="LOW"
[[ -n "$api_files" ]] && RISK="MEDIUM"
[[ -n "$data_files" ]] && RISK="HIGH"
[[ -n "$api_files" && -n "$data_files" ]] && RISK="CRITICAL"

echo "**Overall Risk: $RISK**" >> "$REPORT"
echo "" >> "$REPORT"

[[ "$RISK" == "CRITICAL" ]] && echo "- API + Data changes together = high breakage risk" >> "$REPORT"
[[ -n "$api_files" ]] && echo "- API changes may break consumers" >> "$REPORT"
[[ -n "$data_files" ]] && echo "- Data changes may require migration" >> "$REPORT"
[[ -n "$event_files" ]] && echo "- Event changes may affect downstream processors" >> "$REPORT"
[[ -n "$config_files" ]] && echo "- Config changes affect all environments" >> "$REPORT"

cat >> "$REPORT" << EOF

## 4. Impacted Modules
EOF

# Check dependencies contract for impacted modules
if [[ -f "$MODULE_DIR/contracts/dependencies.yaml" ]]; then
  echo "See: contracts/dependencies.yaml for cross-pod impacts" >> "$REPORT"
  grep -A2 "module:" "$MODULE_DIR/contracts/dependencies.yaml" 2>/dev/null | head -20 >> "$REPORT" || true
else
  echo "No dependencies contract found" >> "$REPORT"
fi

cat >> "$REPORT" << EOF

## 5. ADO Issue References
EOF

# Find ADO refs in changed files
ADO_REFS=""
while IFS= read -r file; do
  [[ -z "$file" || ! -f "$REPO_PATH/$file" ]] && continue
  local_refs=$(grep -o 'AB#[0-9]\+' "$REPO_PATH/$file" 2>/dev/null || true)
  [[ -n "$local_refs" ]] && ADO_REFS="${ADO_REFS}${local_refs}\n"
done <<< "$CHANGED"

if [[ -n "$ADO_REFS" ]]; then
  echo -e "$ADO_REFS" | sort -u | while read -r ref; do
    [[ -n "$ref" ]] && echo "- $ref" >> "$REPORT"
  done
else
  echo "No ADO references found in changed files" >> "$REPORT"
fi

cat >> "$REPORT" << EOF

## 6. Recommended Actions

EOF

[[ -n "$api_files" ]] && echo "- [ ] Update contracts/api.yaml with endpoint changes" >> "$REPORT"
[[ -n "$data_files" ]] && echo "- [ ] Update contracts/data.yaml with schema changes" >> "$REPORT"
[[ -n "$data_files" ]] && echo "- [ ] Verify migration is reversible" >> "$REPORT"
[[ -n "$event_files" ]] && echo "- [ ] Update contracts/events.yaml" >> "$REPORT"
[[ -n "$event_files" ]] && echo "- [ ] Notify downstream event consumers" >> "$REPORT"
[[ -n "$api_files" ]] && echo "- [ ] Notify API consumers (check dependencies.yaml)" >> "$REPORT"
echo "- [ ] Run: sdlc module validate" >> "$REPORT"
echo "- [ ] Reference ADO issue in commit message" >> "$REPORT"

# Display report
cat "$REPORT"

echo ""
log_success "Report saved: $REPORT"
echo ""
