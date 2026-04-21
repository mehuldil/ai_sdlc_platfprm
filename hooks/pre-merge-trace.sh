#!/bin/bash

################################################################################
# Pre-Merge Trace Hook (C4: End-to-end tracing from master story to PR)
# Verifies branch has AB# references and logs trace before allowing merge
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[Pre-Merge Trace Hook]${NC} Verifying work item tracing..."

# ============================================================================
# Configuration
# ============================================================================
TRACE_LOG=".sdlc/memory/tracing-log.md"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
MERGE_BASE=$(git merge-base --fork-point master 2>/dev/null || git merge-base master HEAD 2>/dev/null || echo "")

if [[ -z "$MERGE_BASE" ]]; then
  echo -e "${YELLOW}⚠${NC} Could not determine merge base; skipping tracing validation"
  exit 0
fi

# ============================================================================
# 1. Collect all commits on branch with AB# references
# ============================================================================
echo -e "${BLUE}Step 1:${NC} Scanning branch commits for AB# references..."

COMMITS_WITH_REF=()
COMMITS_WITHOUT_REF=()
BRANCH_AB_REFS=()

# Get all commits since merge base
while IFS= read -r commit_hash; do
  commit_msg=$(git log -1 --format=%B "$commit_hash" 2>/dev/null || echo "")

  # Skip merge commits
  if git log -1 --format=%P "$commit_hash" | grep -q ' '; then
    continue
  fi

  # Extract AB# references from commit
  ab_refs=$(echo "$commit_msg" | grep -oE 'AB#[0-9]+' | sort -u || echo "")

  if [[ -n "$ab_refs" ]]; then
    COMMITS_WITH_REF+=("$commit_hash")
    while IFS= read -r ref; do
      if [[ -n "$ref" ]]; then
        BRANCH_AB_REFS+=("$ref")
      fi
    done <<< "$ab_refs"
  elif echo "$commit_msg" | grep -qE '\[no-ref\]'; then
    COMMITS_WITH_REF+=("$commit_hash")
  else
    COMMITS_WITHOUT_REF+=("$commit_hash")
  fi
done < <(git rev-list "$MERGE_BASE..HEAD" 2>/dev/null)

# ============================================================================
# 2. Check for AB# references in commits
# ============================================================================
if [[ ${#COMMITS_WITH_REF[@]} -eq 0 ]]; then
  echo -e "${RED}✗ BLOCKED: No commits on branch contain AB# references${NC}"
  echo ""
  echo "Each commit must reference an ADO work item:"
  echo "  git commit -m 'Feature description AB#12345'"
  echo ""
  echo "Or use [no-ref] for infrastructure commits:"
  echo "  git commit -m '[no-ref] Update CI pipeline'"
  echo ""
  exit 1
fi

UNIQUE_AB_REFS=($(printf '%s\n' "${BRANCH_AB_REFS[@]}" | sort -u))
echo -e "${GREEN}✓${NC} Found ${#COMMITS_WITH_REF[@]} commits with AB# references"
echo -e "${GREEN}✓${NC} Unique work items: ${UNIQUE_AB_REFS[*]}"

if [[ ${#COMMITS_WITHOUT_REF[@]} -gt 0 ]]; then
  echo -e "${YELLOW}⚠${NC} ${#COMMITS_WITHOUT_REF[@]} commits without AB# references (allowed with [no-ref])"
fi

# ============================================================================
# 3. Check PR description (if exists) for AB# references
# ============================================================================
echo ""
echo -e "${BLUE}Step 2:${NC} Checking PR description for AB# reference..."

PR_AB_REFS=()
PR_FILE="${GIT_PR_DESCRIPTION_FILE:-}"

if [[ -f "$PR_FILE" ]]; then
  pr_ab_refs=$(grep -oE 'AB#[0-9]+' "$PR_FILE" | sort -u || echo "")
  if [[ -n "$pr_ab_refs" ]]; then
    while IFS= read -r ref; do
      if [[ -n "$ref" ]]; then
        PR_AB_REFS+=("$ref")
      fi
    done <<< "$pr_ab_refs"
    echo -e "${GREEN}✓${NC} PR description contains AB# references: ${PR_AB_REFS[*]}"
  else
    echo -e "${YELLOW}⚠${NC} PR description does not contain AB# references (recommended)"
  fi
else
  echo -e "${YELLOW}→${NC} No PR description available (local merge)"
fi

# ============================================================================
# 4. Log tracing information
# ============================================================================
echo ""
echo -e "${BLUE}Step 3:${NC} Logging trace to memory..."

# Ensure memory directory exists
mkdir -p ".sdlc/memory" 2>/dev/null || true

if [[ ! -f "$TRACE_LOG" ]]; then
  cat > "$TRACE_LOG" << 'EOF'
# End-to-End Tracing Log (C4)

This file tracks all merges with their work item references, providing
an audit trail from master stories (AB#) through PRs to merged commits.

## Merge Records

Format:
- **Merge**: branch → merge hash (timestamp)
  - **Work Items**: AB#12345, AB#67890
  - **Commits**: N commits with refs, M commits without refs
  - **PR**: PR#123 (if available)

---

EOF
fi

# Format merge record
{
  echo ""
  echo "- **Merge**: \`$CURRENT_BRANCH\` → \`$(git rev-parse --short HEAD 2>/dev/null)\` ($(date +'%Y-%m-%d %H:%M:%S'))"
  echo "  - **Work Items**: $(IFS=', '; echo "${UNIQUE_AB_REFS[*]:-none}")"
  echo "  - **Commits Traced**: ${#COMMITS_WITH_REF[@]} / $((${#COMMITS_WITH_REF[@]} + ${#COMMITS_WITHOUT_REF[@]}))"
  echo "  - **Commit Range**: \`$MERGE_BASE..HEAD\`"
  if [[ ${#PR_AB_REFS[@]} -gt 0 ]]; then
    echo "  - **PR AB# Refs**: $(IFS=', '; echo "${PR_AB_REFS[*]}")"
  fi
} >> "$TRACE_LOG" 2>/dev/null || true

echo -e "${GREEN}✓${NC} Trace logged to $TRACE_LOG"

# ============================================================================
# 5. Enforce: block merge if untraced commits exceed threshold
# ============================================================================
TOTAL_COMMITS=$(( ${#COMMITS_WITH_REF[@]} + ${#COMMITS_WITHOUT_REF[@]} ))
if [[ $TOTAL_COMMITS -gt 0 && ${#COMMITS_WITHOUT_REF[@]} -gt 0 ]]; then
  UNTRACED_RATIO=$(( ${#COMMITS_WITHOUT_REF[@]} * 100 / TOTAL_COMMITS ))
  if [[ $UNTRACED_RATIO -gt 50 ]]; then
    echo ""
    echo -e "${RED}✗ BLOCKED: ${#COMMITS_WITHOUT_REF[@]}/$TOTAL_COMMITS commits lack AB# or [no-ref]${NC}"
    echo "  Each commit must reference a work item (AB#12345) or use [no-ref]."
    exit 1
  fi
fi

# ============================================================================
# 6. Summary
# ============================================================================
echo ""
echo -e "${GREEN}✓${NC} Pre-merge tracing validation passed"
exit 0
