#!/usr/bin/env bash
# hooks/gate-advisory.sh — Generic Advisory Gate Check
#
# Runs a gate validation check and logs the result to ADO work item as a comment.
# Gates are ADVISORY ONLY — they never block, but always document findings.
#
# Usage: gate-advisory.sh <gate-name> <story-id> [--ado-id=<id>]
#
# Gate Names: G1-G10 (PRD, Pre-grooming, Grooming, Tech Design, Sprint Ready, Dev, SIT, PP, Perf, Release)
#
# See: rules/gate-enforcement.md, ENFORCEMENT-POLICY.md

set -euo pipefail

GATE_NAME="${1:-}"
STORY_ID="${2:-}"
ADO_ID="${3:-}"

# Parse --ado-id flag if provided
case "$ADO_ID" in
  --ado-id=*)
    ADO_ID="${ADO_ID#--ado-id=}"
    ;;
esac

# Validate inputs
if [[ -z "$GATE_NAME" ]] || [[ -z "$STORY_ID" ]]; then
  echo "⚠️  Usage: gate-advisory.sh <gate-name> <story-id> [--ado-id=<id>]" >&2
  echo "Examples:" >&2
  echo "  gate-advisory.sh G1 AB#2001 --ado-id=2001" >&2
  echo "  gate-advisory.sh G4 AB#2001" >&2
  exit 0  # Advisory only: never block
fi

# Extract numeric ADO ID if not provided
if [[ -z "$ADO_ID" ]]; then
  ADO_ID=$(echo "$STORY_ID" | grep -o '[0-9]\+$' || true)
fi

# Setup logging
log_dir=".sdlc/logs"
mkdir -p "$log_dir"
gate_log="$log_dir/${GATE_NAME}-advisory.txt"

# Gate definitions: name, tag, description
declare -A GATE_TAGS=(
  [G1]="prd:reviewed"
  [G2]="pregrooming:checked"
  [G3]="grooming:checked"
  [G4]="techdesign:reviewed"
  [G5]="sprint:ready"
  [G6]="dev:checked"
  [G7]="sit:checked"
  [G8]="pp:checked"
  [G9]="perf:checked"
  [G10]="release:reviewed"
)

declare -A GATE_DESCRIPTIONS=(
  [G1]="PRD Review: sections complete, open questions resolved"
  [G2]="Pre-grooming: checklist items ready"
  [G3]="Grooming: AC present, scope clear, estimate exists"
  [G4]="Tech Design: ADR exists, API contracts committed, NFRs quantified"
  [G5]="Sprint Ready: dependencies noted, blockers identified"
  [G6]="Dev: code merged, coverage %, tests passing"
  [G7]="SIT: test execution, defect status"
  [G8]="Pre-Prod: deployment status, baseline established"
  [G9]="Performance: test results vs targets"
  [G10]="Release: compliance scans, changelog, rollback plan"
)

gate_tag="${GATE_TAGS[$GATE_NAME]:-unknown}"
gate_desc="${GATE_DESCRIPTIONS[$GATE_NAME]:-gate check}"

# Initialize log file with header
if [[ ! -f "$gate_log" ]]; then
  {
    echo "=== $GATE_NAME Advisory Gate Log ==="
    echo "Story: $STORY_ID"
    echo "Gate:  $gate_desc"
    echo ""
  } > "$gate_log"
fi

# Gate validation logic (specific to each gate)
check_gate() {
  local gate="$1"
  local story="$2"
  local issues=()
  local status="PASS"

  case "$gate" in
    G1)
      # Check PRD existence and completeness
      if [[ ! -f ".sdlc/memory/prd-${story}.md" ]]; then
        issues+=("PRD document not found")
        status="WARN"
      else
        if ! grep -q "^## Objectives" ".sdlc/memory/prd-${story}.md"; then
          issues+=("PRD missing Objectives section")
          status="WARN"
        fi
        if ! grep -q "^## Requirements" ".sdlc/memory/prd-${story}.md"; then
          issues+=("PRD missing Requirements section")
          status="WARN"
        fi
      fi
      ;;
    G4)
      # Check ADR and API contracts (implementation gate)
      if [[ ! -f ".sdlc/memory/adr-${story}.md" ]]; then
        issues+=("ADR not found")
        status="WARN"
      else
        adr_status=$(grep -i "^status:" ".sdlc/memory/adr-${story}.md" 2>/dev/null | head -1 | cut -d: -f2 | xargs || echo "UNKNOWN")
        if [[ "$adr_status" != "Accepted" ]] && [[ "$adr_status" != "Approved" ]]; then
          issues+=("ADR status is '$adr_status' (not Accepted)")
          status="WARN"
        fi
      fi

      if [[ ! -f "specs/openapi-${story}.yaml" ]] && [[ ! -f "specs/openapi-${story}.json" ]] && \
         [[ ! -f "specs/graphql-${story}.graphql" ]] && [[ ! -f "specs/rpc-${story}.proto" ]]; then
        if grep -q "api\|endpoint\|endpoint\|service" ".sdlc/memory/${story}.md" 2>/dev/null; then
          issues+=("API contract not committed (OpenAPI/GraphQL/Protobuf)")
          status="WARN"
        fi
      fi

      # Check for NFR quantification
      if [[ -f ".sdlc/memory/nfr-${story}.md" ]]; then
        if grep -qiE "(fast|responsive|efficient|smooth|quick)" ".sdlc/memory/nfr-${story}.md"; then
          issues+=("NFRs use non-quantified terms (fast, responsive, etc.)")
          status="WARN"
        fi
      fi
      ;;
    G6)
      # Check dev status
      if [[ ! -f ".sdlc/memory/test-coverage-${story}.txt" ]]; then
        issues+=("Test coverage report not found")
        status="WARN"
      else
        coverage=$(grep -o '[0-9]\+%' ".sdlc/memory/test-coverage-${story}.txt" | head -1 || echo "0%")
        coverage_num=${coverage%\%}
        if [[ ${coverage_num:-0} -lt 70 ]]; then
          issues+=("Test coverage ${coverage} (recommended >= 70%)")
          status="WARN"
        fi
      fi
      ;;
  esac

  echo "$status"
  if [[ ${#issues[@]} -gt 0 ]]; then
    printf '%s\n' "${issues[@]}"
  fi
}

# Run gate check
gate_check_output=$(check_gate "$GATE_NAME" "$STORY_ID" 2>/dev/null || true)
gate_status=$(echo "$gate_check_output" | head -1)
issues=$(echo "$gate_check_output" | tail -n +2 || true)

# Log results
{
  echo ""
  echo "--- Gate Check $(date -u +%Y-%m-%dT%H:%M:%SZ) ---"
  echo "Gate:   $GATE_NAME"
  echo "Status: $gate_status"
  if [[ -n "$issues" ]]; then
    echo ""
    echo "Issues:"
    echo "$issues" | sed 's/^/  - /'
  fi
  echo ""
} >> "$gate_log"

# Determine icon and ADO comment status
if [[ "$gate_status" == "PASS" ]]; then
  icon="✓"
  ado_status="PASSED"
else
  icon="⚠"
  ado_status="ADVISORY"
fi

# Post comment to ADO if ADO_ID is available and credentials are set
if [[ -n "$ADO_ID" ]] && [[ -n "${ADO_PAT:-}" ]] && [[ -n "${ADO_ORG:-}" ]] && [[ -n "${ADO_PROJECT:-}" ]]; then
  # Build comment text
  comment_text="$icon **[AI-SDLC] Gate $GATE_NAME Advisory — $gate_desc**

**Status:** $ado_status
**Story:** $STORY_ID

**Gate:** $GATE_NAME
"

  if [[ -n "$issues" ]]; then
    comment_text+="
**Findings:**
$(echo "$issues" | sed 's/^/- /')"
  fi

  comment_text+="

**User Action:** You can proceed with or without addressing these items. This gate is advisory.

---
*Automatically posted by AI-SDLC Advisory Gate System*"

  # Post to ADO using curl (best-effort)
  api_url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${ADO_ID}/comments?api-version=7.0"
  auth_header="Authorization: Basic $(echo -n ":${ADO_PAT}" | base64)"

  curl_response=$(curl -sS -X POST \
    -H "$auth_header" \
    -H "Content-Type: application/json" \
    -d "{\"text\":$(echo "$comment_text" | jq -Rs .)}" \
    "$api_url" 2>&1) || true

  if echo "$curl_response" | grep -q '"id"'; then
    {
      echo "ADO Comment Posted: ✓"
      echo ""
    } >> "$gate_log"
  else
    {
      echo "ADO Comment Failed (continuing anyway)"
      echo ""
    } >> "$gate_log"
  fi
fi

# Print summary to console
echo ""
echo "$icon Gate $GATE_NAME: $gate_status"
if [[ -n "$issues" ]]; then
  echo ""
  echo "Findings:"
  echo "$issues" | sed 's/^/  - /'
fi
echo ""
echo "Log: $gate_log"
echo ""

# ADVISORY ONLY: Always exit 0, never block
exit 0
