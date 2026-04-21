#!/usr/bin/env bash
# hooks/enforce-g4.sh — G4 Implementation Gate (Advisory Only)
#
# ADVISORY: Checks G4 criteria but does NOT block.
# If issues found, logs warning that user can review in chat.
#
# G4 Gate Checklist:
#   1. Architecture Decision Record (ADR) exists and accepted
#   2. API contracts (OpenAPI/GraphQL/Protobuf) committed
#   3. Database migration has predecessor linked (if needed)
#   4. NFRs quantified (numeric values, not adjectives)
#
# See: rules/gate-enforcement.md

set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)"

# Only advise on code changes
case "$TOOL_NAME" in
    Write|Edit|NotebookEdit) ;;
    *) exit 0 ;;
esac

STORY_ID="${1:-}"
[ -z "$STORY_ID" ] && exit 0  # No story context; skip advisory

log_dir=".sdlc/logs"
mkdir -p "$log_dir"
log_file="$log_dir/g4-advisory.txt"

# Check 1: ADR Acceptance
adr_file=".sdlc/memory/adr-${STORY_ID}.md"
adr_issues=()
if [ ! -f "$adr_file" ]; then
    adr_issues+=("⚠️  ADR not found at $adr_file")
    {
        echo "⚠️  G4 Advisory: ADR not found at $adr_file"
        echo "   → You can proceed, but consider creating ADR before implementation"
    } >> "$log_file"
else
    adr_status=$(grep -i "^status:" "$adr_file" 2>/dev/null | head -1 | cut -d: -f2 | xargs || echo "UNKNOWN")
    if [ "$adr_status" != "Accepted" ]; then
        adr_issues+=("⚠️  ADR status is '$adr_status' (not 'Accepted')")
        {
            echo "⚠️  G4 Advisory: ADR status is '$adr_status' (not 'Accepted')"
            echo "   → You can proceed, but Tech Lead should review ADR before merge"
        } >> "$log_file"
    fi
fi

# Check 2: API Contracts
if [ ! -f "specs/openapi-${STORY_ID}.yaml" ] && [ ! -f "specs/openapi-${STORY_ID}.json" ] && \
   [ ! -f "specs/graphql-${STORY_ID}.graphql" ] && [ ! -f "specs/rpc-${STORY_ID}.proto" ]; then
    {
        echo "⚠️  G4 Advisory: No API contract found"
        echo "   → If this is an API change, document the contract before releasing"
    } >> "$log_file"
fi

# Check 3: DB Migrations
if git diff --cached --name-only 2>/dev/null | grep -qiE "(migration|schema|database|db.*\.sql)"; then
    {
        echo "⚠️  G4 Advisory: Database changes detected"
        echo "   → Ensure migration task is linked as predecessor in ADO"
    } >> "$log_file"
fi

# Check 4: NFRs Quantified
nfr_file=".sdlc/memory/nfr-targets.md"
if [ -f "$nfr_file" ]; then
    if grep -qiE "(fast|responsive|efficient|smooth|quick)" "$nfr_file"; then
        {
            echo "⚠️  G4 Advisory: NFRs use non-quantified terms"
            echo "   → Replace with numeric targets (e.g., 'p95 latency < 200ms')"
        } >> "$log_file"
    fi
fi

# Log the advisory (always allow, never block)
if [ -f "$log_file" ]; then
    {
        echo ""
        echo "--- G4 Gate Advisory ($(date -u +%Y-%m-%dT%H:%M:%SZ)) ---"
        echo "Story: $STORY_ID"
        cat "$log_file"
        echo "--- You can proceed. Warnings will be reviewed at merge time. ---"
    } >> "$log_file"
fi

# Post ADO comment if there are issues and ADO credentials are available
if [ ${#adr_issues[@]} -gt 0 ] && [ -n "${ADO_PAT:-}" ] && [ -n "${ADO_ORG:-}" ]; then
    # Extract numeric ID from STORY_ID (e.g., "2001" from "AB#2001")
    ado_id=$(echo "$STORY_ID" | grep -o '[0-9]\+$' || true)

    if [ -n "$ado_id" ]; then
        # Build ADO comment
        ado_comment="**[AI-SDLC] G4 Advisory — Implementation Gate**

**Status:** ADVISORY (Non-blocking)
**Story:** $STORY_ID

**Gate:** Technical Design (G4)
- Architecture Decision Record (ADR) status
- API contracts (OpenAPI/GraphQL/Protobuf)
- Database migrations (if needed)
- NFRs (quantified, not adjectives)

**Findings:**"

        for issue in "${adr_issues[@]}"; do
            ado_comment="$ado_comment
- ${issue}"
        done

        ado_comment="$ado_comment

**User Action:** You can proceed. These items can be addressed before merge.

---
*Automatically posted by AI-SDLC G4 Advisory System*"

        # Post comment to ADO
        api_url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT:-}/\_apis/wit/workitems/${ado_id}/comments?api-version=7.0"

        # Use curl to POST comment (best effort, don't fail if it doesn't work)
        curl -sS -X POST \
            -u ":${ADO_PAT}" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"$(echo "$ado_comment" | sed 's/"/\\"/g' | sed 's/$/\\n/g' | tr -d '\n')\"}" \
            "$api_url" >/dev/null 2>&1 || true
    fi
fi

# ADVISORY ONLY: Never block (exit 0)
exit 0
