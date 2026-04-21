#!/bin/bash

# test-bypass-escalation hook: When tests fail, allow merge if:
#   1) Branch skip marker (.sdlc/skip-tests-<branch>) with work_item=<id> (from: sdlc skip-tests --work-item=…)
#   2) OR TPM/Boss approval file (.sdlc/test-skip-approval-<branch>.json)
# SDLC_SKIP_TESTS=1 alone does NOT allow merge — unit-test policy is mandatory; bypass must be on the WI or via approval.
# Make executable: chmod +x hooks/test-bypass-escalation.sh

set -e

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Path to approval file
APPROVAL_FILE=".sdlc/test-skip-approval-${BRANCH_NAME}.json"
SKIP_MARKER=".sdlc/skip-tests-${BRANCH_NAME}"

# Ensure .sdlc directory exists
mkdir -p .sdlc/logs

# Log directory
LOG_DIR=".sdlc/logs"
LOG_FILE="${LOG_DIR}/test-bypass.log"

# Function to log events
log_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
    echo "[${timestamp}] [${level}] [${BRANCH_NAME}] ${message}" >> "$LOG_FILE"
}

# --- Policy (1): explicit test skip for this branch (must trace to ADO work item) ---
if [[ -f "$SKIP_MARKER" ]]; then
    if grep -qE '^work_item=[0-9]+$' "$SKIP_MARKER" 2>/dev/null; then
        log_event "ALLOW" "Test enforcement skipped: skip marker includes work_item (ADO traceability — see rules/pre-merge-test-enforcement.md)"
        echo -e "${YELLOW}⚠${NC} Test skip active for branch ${BRANCH_NAME} (marker + work item). Merge may proceed."
        echo -e "${BLUE}  Log:${NC} $LOG_FILE"
        exit 0
    fi
    echo -e "${RED}✗${NC} Skip marker exists but is invalid (missing work_item=<id>). Re-run: sdlc skip-tests --work-item=… --reason=…"
    log_event "BLOCK" "Invalid skip marker — no work_item line"
    exit 1
fi

if [[ "${SDLC_SKIP_TESTS:-}" == "1" ]]; then
    echo -e "${RED}✗${NC} SDLC_SKIP_TESTS=1 does not bypass mandatory unit-test policy."
    echo "  Use: sdlc skip-tests --work-item=<id> --reason=\"…\" (posts/routes to ADO per policy) OR TPM/Boss approval file."
    log_event "BLOCK" "SDLC_SKIP_TESTS=1 rejected"
    exit 1
fi

# Tests did not pass and no skip marker — require escalation or approval file below
echo -e "${RED}✗ Tests failed on branch: ${BRANCH_NAME}${NC}"
echo ""

# Check if approval file exists
if [ ! -f "$APPROVAL_FILE" ]; then
    echo -e "${RED}ERROR: Test bypass requires approval from TPM or manager${NC}"
    echo ""
    echo -e "${YELLOW}Approval file not found:${NC}"
    echo "  ${APPROVAL_FILE}"
    echo ""
    echo -e "${YELLOW}To proceed with test bypass, create an approval file:${NC}"
    echo ""
    echo -e "${BLUE}Option 1: Create approval file manually${NC}"
    echo "  mkdir -p .sdlc"
    echo "  cat > \"${APPROVAL_FILE}\" << 'EOF'"
    echo "{"
    echo "  \"approver\": \"<Your Name>\","
    echo "  \"role\": \"tpm\","
    echo "  \"reason\": \"<Explanation of why tests are bypassed>\","
    echo "  \"timestamp\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","
    echo "  \"branch\": \"${BRANCH_NAME}\""
    echo "}"
    echo "EOF"
    echo ""
    echo -e "${BLUE}Option 2: Use CLI command (if available)${NC}"
    echo "  sdlc approve-test-skip \\"
    echo "    --approver=\"Your Name\" \\"
    echo "    --role=tpm \\"
    echo "    --reason=\"Brief explanation\" \\"
    echo "    --branch=\"${BRANCH_NAME}\""
    echo ""
    echo -e "${YELLOW}Valid roles:${NC} tpm, boss"
    echo -e "${YELLOW}Branch:${NC} ${BRANCH_NAME}"
    echo ""
    log_event "BLOCK" "Test bypass rejected - no approval file"
    exit 1
fi

# Validate approval file format
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq not found, skipping JSON validation${NC}"
    # Still try to parse with basic checks
    if ! grep -q '"approver"' "$APPROVAL_FILE" || ! grep -q '"role"' "$APPROVAL_FILE"; then
        echo -e "${RED}ERROR: Approval file missing required fields${NC}"
        log_event "BLOCK" "Invalid approval file format"
        exit 1
    fi
else
    # Validate JSON format
    if ! jq empty "$APPROVAL_FILE" 2>/dev/null; then
        echo -e "${RED}ERROR: Approval file is not valid JSON${NC}"
        echo "  File: ${APPROVAL_FILE}"
        log_event "BLOCK" "Invalid JSON in approval file"
        exit 1
    fi

    # Validate required fields
    REQUIRED_FIELDS=("approver" "role" "reason" "timestamp" "branch")
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! jq -e ".${field}" "$APPROVAL_FILE" > /dev/null 2>&1; then
            echo -e "${RED}ERROR: Approval file missing required field: ${field}${NC}"
            log_event "BLOCK" "Missing required field: ${field}"
            exit 1
        fi
    done

    # Extract role using jq
    APPROVER_ROLE=$(jq -r '.role' "$APPROVAL_FILE" 2>/dev/null || echo "")
    APPROVER_NAME=$(jq -r '.approver' "$APPROVAL_FILE" 2>/dev/null || echo "")
    APPROVAL_REASON=$(jq -r '.reason' "$APPROVAL_FILE" 2>/dev/null || echo "")
fi

# Fallback parsing if jq is not available
if [ -z "$APPROVER_ROLE" ]; then
    APPROVER_ROLE=$(grep -o '"role"[[:space:]]*:[[:space:]]*"[^"]*"' "$APPROVAL_FILE" | cut -d'"' -f4)
    APPROVER_NAME=$(grep -o '"approver"[[:space:]]*:[[:space:]]*"[^"]*"' "$APPROVAL_FILE" | cut -d'"' -f4)
    APPROVAL_REASON=$(grep -o '"reason"[[:space:]]*:[[:space:]]*"[^"]*"' "$APPROVAL_FILE" | cut -d'"' -f4)
fi

# Validate approver role (must be tpm or boss)
if [ "$APPROVER_ROLE" != "tpm" ] && [ "$APPROVER_ROLE" != "boss" ]; then
    echo -e "${RED}ERROR: Invalid approver role: ${APPROVER_ROLE}${NC}"
    echo -e "${YELLOW}Valid roles:${NC} tpm, boss"
    log_event "BLOCK" "Invalid approver role: ${APPROVER_ROLE}"
    exit 1
fi

# ALLOW MERGE with approval
echo -e "${YELLOW}⚠ TEST BYPASS APPROVED${NC}"
echo ""
echo -e "${BLUE}Approval Details:${NC}"
echo "  Approver: ${APPROVER_NAME}"
echo "  Role: ${APPROVER_ROLE}"
echo "  Branch: ${BRANCH_NAME}"
echo "  Reason: ${APPROVAL_REASON}"
echo ""
echo -e "${RED}WARNING: Tests were bypassed - this merge requires extra scrutiny${NC}"
echo ""

# Log the bypass
log_event "ALLOWED" "Test bypass approved by ${APPROVER_NAME} (${APPROVER_ROLE}) - Reason: ${APPROVAL_REASON}"

# Cleanup: Remove approval file after use (optional - set to 0 to keep)
CLEANUP_AFTER_APPROVAL=1
if [ "$CLEANUP_AFTER_APPROVAL" -eq 1 ]; then
    rm -f "$APPROVAL_FILE"
    log_event "INFO" "Approval file cleaned up"
fi

echo -e "${GREEN}✓ Proceeding with merge${NC}"
exit 0
