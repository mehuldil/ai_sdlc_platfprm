#!/bin/bash

################################################################################
# Trace Audit Script (C4: End-to-end tracing analysis)
# Scans git log for current branch and reports tracing statistics
# Reports: commits with/without AB# refs, percentage traced, untraced list
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# Configuration
# ============================================================================
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
MEMORY_DIR=".sdlc/memory"
AUDIT_LOG="${MEMORY_DIR}/trace-audit-$(date +'%Y%m%d-%H%M%S').md"
MERGE_BASE=$(git merge-base --fork-point master 2>/dev/null || git merge-base master HEAD 2>/dev/null || git rev-list --max-parents=0 HEAD 2>/dev/null || echo "")

# Colors in functions
_blue() { echo -e "${BLUE}$*${NC}"; }
_green() { echo -e "${GREEN}$*${NC}"; }
_yellow() { echo -e "${YELLOW}$*${NC}"; }
_red() { echo -e "${RED}$*${NC}"; }

# ============================================================================
# Header
# ============================================================================
echo ""
_blue "═══════════════════════════════════════════════════════════════"
_blue "  Trace Audit: End-to-End Tracing Analysis (C4)"
_blue "═══════════════════════════════════════════════════════════════"
echo ""
_blue "Branch:" "$CURRENT_BRANCH"
_blue "Current Commit:" "$CURRENT_COMMIT"
echo ""

# ============================================================================
# 1. Scan commits for AB# references
# ============================================================================
echo -e "${BLUE}→${NC} Scanning commits for AB# references..."
echo ""

declare -A COMMIT_REFS
TOTAL_COMMITS=0
TRACED_COMMITS=0
UNTRACED_COMMITS=0
ALL_AB_REFS=()
UNTRACED_LIST=()

# If MERGE_BASE is empty, scan all commits
if [[ -z "$MERGE_BASE" ]]; then
  COMMIT_RANGE="HEAD"
  echo -e "${YELLOW}⚠${NC} No merge base found; scanning all commits on branch"
else
  COMMIT_RANGE="${MERGE_BASE}..HEAD"
fi

# Process each commit
while IFS= read -r commit_hash; do
  [[ -z "$commit_hash" ]] && continue

  TOTAL_COMMITS=$((TOTAL_COMMITS + 1))

  # Get commit details
  commit_msg=$(git log -1 --format=%B "$commit_hash" 2>/dev/null || echo "")
  commit_subject=$(git log -1 --format=%s "$commit_hash" 2>/dev/null || echo "unknown")
  commit_author=$(git log -1 --format=%an "$commit_hash" 2>/dev/null || echo "unknown")
  commit_date=$(git log -1 --format=%ai "$commit_hash" 2>/dev/null || echo "unknown")

  # Skip merge commits
  if git log -1 --format=%P "$commit_hash" | grep -q ' '; then
    continue
  fi

  # Extract AB# references
  ab_refs=$(echo "$commit_msg" | grep -oE 'AB#[0-9]+' | sort -u || echo "")

  if [[ -n "$ab_refs" ]]; then
    TRACED_COMMITS=$((TRACED_COMMITS + 1))
    while IFS= read -r ref; do
      if [[ -n "$ref" ]]; then
        ALL_AB_REFS+=("$ref")
      fi
    done <<< "$ab_refs"
    COMMIT_REFS["$commit_hash"]="$ab_refs"
  else
    UNTRACED_COMMITS=$((UNTRACED_COMMITS + 1))
    UNTRACED_LIST+=("$commit_hash:$commit_subject:$commit_author")
  fi
done < <(git rev-list "$COMMIT_RANGE" 2>/dev/null || echo "")

# ============================================================================
# 2. Calculate statistics
# ============================================================================
echo ""
echo -e "${BLUE}→${NC} Calculating statistics..."
echo ""

if [[ $TOTAL_COMMITS -eq 0 ]]; then
  _yellow "No commits found in range"
  exit 0
fi

UNIQUE_AB_REFS=($(printf '%s\n' "${ALL_AB_REFS[@]}" | sort -u))
TRACE_PERCENTAGE=$((TRACED_COMMITS * 100 / TOTAL_COMMITS))

# ============================================================================
# 3. Display summary to stdout
# ============================================================================
echo -e "${CYAN}Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
printf "  Total Commits:        %d\n" "$TOTAL_COMMITS"
printf "  Commits with AB#:     %d ${GREEN}✓${NC}\n" "$TRACED_COMMITS"
printf "  Commits without AB#:  %d ${YELLOW}⚠${NC}\n" "$UNTRACED_COMMITS"
printf "  Trace Coverage:       %d%% " "$TRACE_PERCENTAGE"

if [[ $TRACE_PERCENTAGE -eq 100 ]]; then
  _green "✓ FULL TRACE"
elif [[ $TRACE_PERCENTAGE -ge 75 ]]; then
  _yellow "⚠ PARTIAL"
else
  _red "✗ INSUFFICIENT"
fi

echo ""
printf "  Unique Work Items:    %d\n" "${#UNIQUE_AB_REFS[@]}"
echo ""

if [[ ${#UNIQUE_AB_REFS[@]} -gt 0 ]]; then
  echo -e "${CYAN}Traced Work Items${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf '%s\n' "${UNIQUE_AB_REFS[@]}" | sort | while read -r ref; do
    echo "  $ref"
  done
  echo ""
fi

if [[ ${#UNTRACED_LIST[@]} -gt 0 ]]; then
  echo -e "${CYAN}Untraced Commits${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for item in "${UNTRACED_LIST[@]}"; do
    IFS=: read -r hash subject author <<< "$item"
    printf "  ${YELLOW}⚠${NC} %-8s %s\n" "$hash" "$subject"
  done
  echo ""
fi

# ============================================================================
# 4. Generate detailed audit log
# ============================================================================
echo -e "${BLUE}→${NC} Generating detailed audit log..."

mkdir -p "$MEMORY_DIR" 2>/dev/null || true

{
  cat << EOF
# Trace Audit Report (C4: End-to-end Tracing)

Generated: $(date +'%Y-%m-%d %H:%M:%S')

## Branch Information
- **Branch**: $CURRENT_BRANCH
- **Current Commit**: $CURRENT_COMMIT
- **Merge Base**: $MERGE_BASE
- **Scan Range**: $COMMIT_RANGE

## Summary Statistics
- **Total Commits**: $TOTAL_COMMITS
- **Commits with AB#**: $TRACED_COMMITS (${TRACE_PERCENTAGE}%)
- **Commits without AB#**: $UNTRACED_COMMITS
- **Unique Work Items**: ${#UNIQUE_AB_REFS[@]}

EOF

  if [[ $TRACE_PERCENTAGE -eq 100 ]]; then
    echo "**Trace Coverage**: FULL (100%) ✓"
  elif [[ $TRACE_PERCENTAGE -ge 75 ]]; then
    echo "**Trace Coverage**: PARTIAL (${TRACE_PERCENTAGE}%) ⚠"
  else
    echo "**Trace Coverage**: INSUFFICIENT (${TRACE_PERCENTAGE}%) ✗"
  fi

  echo ""
  echo "## Traced Work Items"
  echo ""

  if [[ ${#UNIQUE_AB_REFS[@]} -gt 0 ]]; then
    printf '%s\n' "${UNIQUE_AB_REFS[@]}" | sort | while read -r ref; do
      echo "- $ref"
    done
  else
    echo "None"
  fi

  echo ""
  echo "## Detailed Commit Analysis"
  echo ""

  # Commit details
  while IFS= read -r commit_hash; do
    [[ -z "$commit_hash" ]] && continue

    commit_msg=$(git log -1 --format=%B "$commit_hash" 2>/dev/null || echo "")
    commit_subject=$(git log -1 --format=%s "$commit_hash" 2>/dev/null || echo "unknown")
    commit_author=$(git log -1 --format=%an "$commit_hash" 2>/dev/null || echo "unknown")
    commit_date=$(git log -1 --format=%ai "$commit_hash" 2>/dev/null || echo "unknown")

    # Skip merge commits
    if git log -1 --format=%P "$commit_hash" | grep -q ' '; then
      continue
    fi

    ab_refs=$(echo "$commit_msg" | grep -oE 'AB#[0-9]+' | sort -u | tr '\n' ',' | sed 's/,$//')

    if [[ -n "$ab_refs" ]]; then
      echo "### ✓ $commit_hash"
    else
      echo "### ⚠ $commit_hash"
    fi

    echo "- **Subject**: $commit_subject"
    echo "- **Author**: $commit_author"
    echo "- **Date**: $commit_date"
    if [[ -n "$ab_refs" ]]; then
      echo "- **Work Items**: $ab_refs"
    else
      echo "- **Work Items**: UNTRACED"
    fi
    echo ""
  done < <(git rev-list "$COMMIT_RANGE" 2>/dev/null || echo "")

  echo "## Recommendations"
  echo ""

  if [[ $TRACE_PERCENTAGE -lt 100 ]]; then
    echo "- Add AB# references to the following commits:"
    echo "  \`git rebase --interactive\` and add work item IDs to commit messages"
    echo ""
    echo "  Or use \`[no-ref]\` tag for infrastructure commits:"
    echo "  \`[no-ref] Update CI/CD pipeline\`"
    echo ""
  fi

  echo "- Ensure every feature commit links to a work item for end-to-end tracing"
  echo "- Infrastructure commits can be marked with [no-ref] for exemption"
  echo "- All merges are logged in .sdlc/memory/tracing-log.md"

} > "$AUDIT_LOG" 2>/dev/null

_green "✓ Audit log saved: $AUDIT_LOG"
echo ""
