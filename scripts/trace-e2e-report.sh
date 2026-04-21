#!/usr/bin/env bash
################################################################################
# End-to-End Traceability Report
# Generates a mapping: PRD → Story → Task → Commit (AB#) → PR → ADO
#
# Usage: bash scripts/trace-e2e-report.sh [project-path]
################################################################################

set -eo pipefail

PROJECT_DIR="${1:-.}"
PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_section() { echo ""; echo -e "${CYAN}━━━ $1 ━━━${NC}"; echo ""; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
log_info()    { echo -e "${BLUE}→${NC} $1"; }

PASS=0
WARN=0

# ============================================================================
# 1. Story files → PRD section traceability
# ============================================================================

log_section "1. Story → PRD Section Traceability"

STORY_FILES=()
while IFS= read -r f; do
  STORY_FILES+=("$f")
done < <(find "$PROJECT_DIR" -path '*/stories/*.md' -o -path '*/.sdlc/stories/*.md' 2>/dev/null || true)

if [[ ${#STORY_FILES[@]} -eq 0 ]]; then
  log_info "No story files found under stories/ — check after sdlc story create"
else
  STORIES_WITH_PRD=0
  STORIES_WITHOUT_PRD=0
  for sf in "${STORY_FILES[@]}"; do
    if grep -qE 'PRD.*(Section|Ref|ID)|prd_section|PRD-REF' "$sf" 2>/dev/null; then
      STORIES_WITH_PRD=$((STORIES_WITH_PRD + 1))
    else
      log_warn "Story missing PRD section ref: $sf"
      STORIES_WITHOUT_PRD=$((STORIES_WITHOUT_PRD + 1))
    fi
  done
  log_info "Stories with PRD ref: $STORIES_WITH_PRD / $((STORIES_WITH_PRD + STORIES_WITHOUT_PRD))"
  [[ $STORIES_WITHOUT_PRD -gt 0 ]] && WARN=$((WARN + 1)) || PASS=$((PASS + 1))
fi

# ============================================================================
# 2. Task → Story traceability (parent IDs in task files)
# ============================================================================

log_section "2. Task → Story Traceability"

TASK_FILES=()
while IFS= read -r f; do
  TASK_FILES+=("$f")
done < <(find "$PROJECT_DIR" -path '*/tasks/*.md' -o -path '*/.sdlc/tasks/*.md' 2>/dev/null || true)

if [[ ${#TASK_FILES[@]} -eq 0 ]]; then
  log_info "No task files found under tasks/"
else
  TASKS_WITH_PARENT=0
  TASKS_WITHOUT_PARENT=0
  for tf in "${TASK_FILES[@]}"; do
    if grep -qE 'parent_story|Sprint Story|Master Story|US-[0-9]+' "$tf" 2>/dev/null; then
      TASKS_WITH_PARENT=$((TASKS_WITH_PARENT + 1))
    else
      log_warn "Task missing parent story ref: $tf"
      TASKS_WITHOUT_PARENT=$((TASKS_WITHOUT_PARENT + 1))
    fi
  done
  log_info "Tasks with parent ref: $TASKS_WITH_PARENT / $((TASKS_WITH_PARENT + TASKS_WITHOUT_PARENT))"
  [[ $TASKS_WITHOUT_PARENT -gt 0 ]] && WARN=$((WARN + 1)) || PASS=$((PASS + 1))
fi

# ============================================================================
# 3. Commit → AB# traceability (current branch)
# ============================================================================

log_section "3. Commit → ADO Work Item (AB#) Traceability"

if ! git rev-parse --git-dir &>/dev/null 2>&1; then
  log_info "Not a git repository — skipping commit trace"
else
  TOTAL_COMMITS=0
  TRACED_COMMITS=0
  NOREF_COMMITS=0
  UNTRACED_COMMITS=0

  while IFS= read -r hash; do
    TOTAL_COMMITS=$((TOTAL_COMMITS + 1))
    msg=$(git log -1 --format=%B "$hash" 2>/dev/null || echo "")
    if echo "$msg" | grep -qE 'AB#[0-9]+'; then
      TRACED_COMMITS=$((TRACED_COMMITS + 1))
    elif echo "$msg" | grep -qE '\[no-ref\]'; then
      NOREF_COMMITS=$((NOREF_COMMITS + 1))
    else
      UNTRACED_COMMITS=$((UNTRACED_COMMITS + 1))
    fi
  done < <(git log --format=%H -50 2>/dev/null || true)

  log_info "Last 50 commits: $TRACED_COMMITS AB#-traced, $NOREF_COMMITS [no-ref], $UNTRACED_COMMITS untraced"
  [[ $UNTRACED_COMMITS -gt 0 ]] && WARN=$((WARN + 1)) || PASS=$((PASS + 1))

  AB_IDS=$(git log --format=%B -50 2>/dev/null | grep -oE 'AB#[0-9]+' | sort -u || true)
  if [[ -n "$AB_IDS" ]]; then
    log_info "Unique ADO work items referenced: $(echo "$AB_IDS" | tr '\n' ' ')"
  fi
fi

# ============================================================================
# 4. Tracing log (merge records)
# ============================================================================

log_section "4. Merge Trace Log"

TRACE_LOG="${PROJECT_DIR}/.sdlc/memory/tracing-log.md"
if [[ -f "$TRACE_LOG" ]]; then
  MERGE_COUNT=$(grep -cE '^\- \*\*Merge\*\*' "$TRACE_LOG" 2>/dev/null || echo "0")
  log_success "Tracing log exists with $MERGE_COUNT merge record(s)"
  PASS=$((PASS + 1))
else
  log_warn "No tracing log found at $TRACE_LOG (created on first merge)"
  WARN=$((WARN + 1))
fi

# ============================================================================
# 5. Template traceability fields
# ============================================================================

log_section "5. Template Traceability Fields"

TEMPLATE_DIR="${PLATFORM_DIR}/templates/story-templates"
for tpl in master-story-template.md sprint-story-template.md tech-story-template.md task-template.md; do
  tpl_path="${TEMPLATE_DIR}/${tpl}"
  if [[ ! -f "$tpl_path" ]]; then
    log_warn "Template not found: $tpl"
    WARN=$((WARN + 1))
    continue
  fi
  has_trace=0
  grep -qiE 'PRD.*Section|parent_story|Master Story|Sprint Story|AB#|work.item' "$tpl_path" 2>/dev/null && has_trace=1
  if [[ $has_trace -eq 1 ]]; then
    log_success "$tpl has traceability fields"
    PASS=$((PASS + 1))
  else
    log_warn "$tpl missing traceability fields"
    WARN=$((WARN + 1))
  fi
done

# ============================================================================
# Summary
# ============================================================================

log_section "Traceability Report Summary"

echo "PASS:  $PASS ✓"
echo "WARN:  $WARN ⚠"
echo ""

if [[ $WARN -eq 0 ]]; then
  log_success "Full traceability: PRD → Story → Task → Commit → ADO"
else
  log_warn "$WARN traceability gap(s) found — review above"
fi
