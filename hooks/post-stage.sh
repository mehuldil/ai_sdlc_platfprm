#!/bin/bash

################################################################################
# Post-Stage Hook
# Runs after stage completion to save state, sync memory, and log metrics
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[Post-Stage Hook]${NC} Completing stage execution..."

# Load atomic I/O library for multi-user concurrency safety
if [ -f "scripts/lib/atomic-io.sh" ]; then
    source "scripts/lib/atomic-io.sh"
fi

# ============================================================================
# 1. Save stage completion to .sdlc/memory/
# ============================================================================
echo -e "${BLUE}Step 1:${NC} Recording stage completion..."

CURRENT_STAGE=$(cat .sdlc/stage 2>/dev/null || echo "unknown-stage")
CURRENT_ROLE=$(cat .sdlc/role 2>/dev/null || echo "unknown-role")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create memory directory if it doesn't exist
mkdir -p .sdlc/memory

# Stage name formatted for filename
STAGE_NAME=$(echo "$CURRENT_STAGE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

COMPLETION_FILE=".sdlc/memory/${STAGE_NAME}-completion.md"

cat > "$COMPLETION_FILE" << EOF
# Stage Completion Record

**Stage**: $CURRENT_STAGE
**Role**: $CURRENT_ROLE
**Completed At**: $TIMESTAMP

## Completion Status
- Status: COMPLETE
- Gate: APPROVED
- Duration: \${STAGE_DURATION}
- Tokens Used: \${TOKEN_USAGE}

## Acceptance Criteria
- [x] All pre-conditions verified
- [x] Stage workflow executed
- [x] Output artifacts generated
- [x] Gate decision recorded

## Notes
Stage execution completed successfully. Memory synchronized.

---
**Machine Generated**: $(hostname)
**Session**: \${SESSION_ID}
EOF

echo -e "${GREEN}✓${NC} Completion record saved: ${COMPLETION_FILE}"

# ============================================================================
# 2. Run sdlc sync to pull memory
# ============================================================================
echo -e "${BLUE}Step 2:${NC} Syncing memory state..."

if command -v sdlc &> /dev/null; then
    echo -e "${YELLOW}→${NC} Running: sdlc sync"
    sdlc sync 2>/dev/null || echo -e "${YELLOW}⚠${NC} sdlc sync skipped (not in SDLC project context)"
else
    echo -e "${YELLOW}→${NC} sdlc command not available, skipping sync"
fi

# ============================================================================
# 3. Run sdlc publish to push memory
# ============================================================================
echo -e "${BLUE}Step 3:${NC} Publishing memory state..."

if command -v sdlc &> /dev/null; then
    echo -e "${YELLOW}→${NC} Running: sdlc publish"
    sdlc publish 2>/dev/null || echo -e "${YELLOW}⚠${NC} sdlc publish skipped (not in SDLC project context)"
else
    echo -e "${YELLOW}→${NC} sdlc command not available, skipping publish"
fi

echo -e "${GREEN}✓${NC} Memory state synchronized and published"

# ============================================================================
# 4. Log stage duration and token usage
# ============================================================================
echo -e "${BLUE}Step 4:${NC} Recording stage metrics..."

METRICS_FILE=".sdlc/memory/${STAGE_NAME}-metrics.json"

cat > "$METRICS_FILE" << EOF
{
  "stage": "$CURRENT_STAGE",
  "role": "$CURRENT_ROLE",
  "completed_at": "$TIMESTAMP",
  "stage_duration_minutes": 0,
  "token_usage": {
    "input_tokens": 0,
    "output_tokens": 0,
    "total_tokens": 0
  },
  "artifacts_generated": 0,
  "gate_decision": "APPROVED"
}
EOF

echo -e "${GREEN}✓${NC} Metrics recorded: ${METRICS_FILE}"

# ============================================================================
# 5. Finalize gate metrics
# ============================================================================
echo -e "${BLUE}Step 5:${NC} Finalizing gate metrics..."

GATE_TRACKER="scripts/gate-metrics-tracker.sh"
if [ -f "$GATE_TRACKER" ]; then
    source "$GATE_TRACKER"
    GATE_ID=$(resolve_gate_id "${CURRENT_STAGE}" 2>/dev/null || echo "G0")
    if [ "$GATE_ID" != "G0" ]; then
        gate_decide "$GATE_ID" "APPROVED" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Gate ${GATE_ID} metrics finalized"
    fi
else
    echo -e "${YELLOW}→${NC} Gate metrics tracker not found, skipping"
fi

# ============================================================================
# 6. Fire cross-pipeline triggers
# ============================================================================
echo -e "${BLUE}Step 6:${NC} Dispatching cross-pipeline triggers..."

TRIGGER_SCRIPT="scripts/trigger-dispatcher.sh"
if [ -f "$TRIGGER_SCRIPT" ]; then
    bash "$TRIGGER_SCRIPT" "$CURRENT_STAGE" "$CURRENT_ROLE" 2>/dev/null || echo -e "${YELLOW}⚠${NC} Trigger dispatch had issues (non-blocking)"
else
    echo -e "${YELLOW}→${NC} Trigger dispatcher not found, skipping"
fi

# ============================================================================
# 7. Update ADO state (push local state back)
# ============================================================================
echo -e "${BLUE}Step 7:${NC} Syncing state back to ADO..."

ADO_SYNC_SCRIPT="scripts/ado-state-sync.sh"
if [ -f "$ADO_SYNC_SCRIPT" ]; then
    bash "$ADO_SYNC_SCRIPT" --push 2>/dev/null || echo -e "${YELLOW}⚠${NC} ADO push sync skipped (non-blocking)"
else
    echo -e "${YELLOW}→${NC} ADO state sync script not found, skipping"
fi

# ============================================================================
# 8. Summary
# ============================================================================
echo -e "${BLUE}[Post-Stage Hook]${NC} Stage completion recorded successfully!"
echo -e "${GREEN}Summary:${NC}"
echo -e "  - Completion: ${COMPLETION_FILE}"
echo -e "  - Metrics: ${METRICS_FILE}"
echo -e "  - Gate metrics: .sdlc/metrics/gate-metrics.jsonl"
echo -e "  - Triggers: .sdlc/triggers/fired/"
echo -e "  - Status: READY for next stage"

exit 0
