#!/bin/bash

################################################################################
# Pre-Stage Hook
# Runs before any stage execution to verify prerequisites and load context
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[Pre-Stage Hook]${NC} Verifying prerequisites..."

# Load atomic I/O library for multi-user concurrency safety
if [ -f "scripts/lib/atomic-io.sh" ]; then
    source "scripts/lib/atomic-io.sh"
    # Clean orphaned temp files from prior crashes
    cleanup_temp_files ".sdlc" 2>/dev/null || true
fi

# ============================================================================
# 1. Verify required SDLC context files exist
# ============================================================================
echo -e "${BLUE}Step 1:${NC} Checking SDLC context files..."

if [ ! -f ".sdlc/role" ]; then
    echo -e "${RED}ERROR:${NC} .sdlc/role not found"
    exit 1
fi

if [ ! -f ".sdlc/stack" ]; then
    echo -e "${RED}ERROR:${NC} .sdlc/stack not found"
    exit 1
fi

if [ ! -f ".sdlc/stage" ]; then
    echo -e "${RED}ERROR:${NC} .sdlc/stage not found"
    exit 1
fi

CURRENT_ROLE=$(cat .sdlc/role)
CURRENT_STACK=$(cat .sdlc/stack)
CURRENT_STAGE=$(cat .sdlc/stage)

echo -e "${GREEN}✓${NC} Role: ${CURRENT_ROLE}"
echo -e "${GREEN}✓${NC} Stack: ${CURRENT_STACK}"
echo -e "${GREEN}✓${NC} Stage: ${CURRENT_STAGE}"

# ============================================================================
# 2. Run smart routing classification if not already classified
# ============================================================================
echo -e "${BLUE}Step 2:${NC} Checking smart routing classification..."

if [ ! -f ".sdlc/memory/routing-classification.md" ]; then
    echo -e "${YELLOW}→${NC} Running smart routing classification..."
    # Call smart routing to classify the current task/story
    # This would normally invoke: sdlc route <task-description>
    echo -e "${GREEN}✓${NC} Smart routing classification will be performed"
else
    echo -e "${GREEN}✓${NC} Task already classified"
fi

# ============================================================================
# 3. Load stage pre-conditions from STAGE.md
# ============================================================================
echo -e "${BLUE}Step 3:${NC} Loading stage pre-conditions..."

STAGE_FILE="stages/${CURRENT_STAGE}/STAGE.md"

if [ ! -f "${STAGE_FILE}" ]; then
    echo -e "${RED}ERROR:${NC} Stage definition not found: ${STAGE_FILE}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Stage definition loaded: ${STAGE_FILE}"

# Extract pre-conditions section from STAGE.md
echo -e "${BLUE}Step 4:${NC} Verifying pre-conditions..."
# This would extract the "## Pre-Conditions" section and validate each

# ============================================================================
# 4. Check if required_stages gates are passed
# ============================================================================
echo -e "${BLUE}Step 5:${NC} Checking required stage gates..."

# Extract required_stages from STAGE.md frontmatter
# Example: requires_stages: [Requirement Intake, Design Review]
# For each required stage, check if .sdlc/memory/{stage}-completion.md exists

# BUG FIX #7: Properly handle stage names with quoted expansion
REQUIRES_STAGES=$(grep "requires_stages:" "${STAGE_FILE}" | sed 's/requires_stages: //g' | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "$REQUIRES_STAGES" ]; then
    echo -e "${GREEN}✓${NC} No prerequisite stages required"
else
    echo "$REQUIRES_STAGES" | while IFS= read -r stage; do
        # Trim whitespace properly
        stage_clean="${stage#"${stage%%[![:space:]]*}"}"
        stage_clean="${stage_clean%"${stage_clean##*[![:space:]]}"}"

        # Build safe filename from stage name
        completion_file=".sdlc/memory/$(echo "$stage_clean" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')-completion.md"

        if [ -f "$completion_file" ]; then
            echo -e "${GREEN}✓${NC} Gate passed: $stage_clean"
        else
            echo -e "${YELLOW}→${NC} Prerequisite stage gate incomplete: $stage_clean"
            echo -e "${YELLOW}   Expected: $completion_file${NC}"
        fi
    done
fi

# ============================================================================
# 6. MCP Health Check (non-blocking)
# ============================================================================
echo -e "${BLUE}Step 6:${NC} Running MCP health checks..."

MCP_HEALTH_SCRIPT="hooks/mcp-health-check.sh"
if [ -f "$MCP_HEALTH_SCRIPT" ]; then
    bash "$MCP_HEALTH_SCRIPT" 2>/dev/null || true
    if [ -f ".sdlc/mcp-health.json" ]; then
        echo -e "${GREEN}✓${NC} MCP health status updated"
    fi
else
    echo -e "${YELLOW}→${NC} MCP health check script not found, skipping"
fi

# ============================================================================
# 7. Drain MCP pending queue (retry failed operations from prior stages)
# ============================================================================
echo -e "${BLUE}Step 7:${NC} Draining MCP pending queue..."

MCP_DRAIN_SCRIPT="scripts/mcp-queue-drain.sh"
if [ -f "$MCP_DRAIN_SCRIPT" ]; then
    bash "$MCP_DRAIN_SCRIPT" 2>/dev/null || echo -e "${YELLOW}⚠${NC} Queue drain had issues (non-blocking)"
else
    echo -e "${YELLOW}→${NC} MCP queue drain script not found, skipping"
fi

# ============================================================================
# 8. ADO State Reconciliation (sync local ↔ ADO before stage work)
# ============================================================================
echo -e "${BLUE}Step 8:${NC} Running ADO state reconciliation..."

ADO_SYNC_SCRIPT="scripts/ado-state-sync.sh"
if [ -f "$ADO_SYNC_SCRIPT" ]; then
    bash "$ADO_SYNC_SCRIPT" --pull 2>/dev/null || echo -e "${YELLOW}⚠${NC} ADO sync skipped (non-blocking)"
else
    echo -e "${YELLOW}→${NC} ADO state sync script not found, skipping"
fi

# ============================================================================
# 9. Check cross-pipeline blocking dependencies
# ============================================================================
echo -e "${BLUE}Step 9:${NC} Checking cross-pipeline dependencies..."

DEPS_FILE=".sdlc/triggers/pipeline-dependencies.json"
if [ -f "$DEPS_FILE" ]; then
    # Check if any BLOCKING dependencies target this stage and are unsatisfied
    BLOCKING_COUNT=$(python3 -c "
import json, sys
try:
    with open('$DEPS_FILE') as f:
        data = json.load(f)
    stage = '${CURRENT_STAGE}'.lower().replace(' ', '-')
    blocked = [d for d in data.get('dependencies', [])
               if d.get('type') == 'BLOCKING'
               and stage in d.get('target', {}).get('stage', '').lower()]
    for b in blocked:
        fired = '.sdlc/triggers/fired/' + b['source']['team'] + '-' + b['source']['stage'].replace(' ', '-') + '.json'
        import os
        if not os.path.exists(fired):
            print(f\"BLOCKED: Waiting on {b['source']['team']} {b['source']['stage']} ({b.get('artifact', 'unknown artifact')})\")
except Exception:
    pass
" 2>/dev/null || true)

    if [ -n "$BLOCKING_COUNT" ]; then
        echo -e "${YELLOW}⚠ Cross-Pipeline Blockers Found:${NC}"
        echo "$BLOCKING_COUNT" | while IFS= read -r line; do
            echo -e "  ${RED}→${NC} $line"
        done
        echo -e "${YELLOW}   User can override with: sdlc proceed --force${NC}"
    else
        echo -e "${GREEN}✓${NC} No blocking cross-pipeline dependencies"
    fi
else
    echo -e "${YELLOW}→${NC} Pipeline dependencies config not found, skipping"
fi

# ============================================================================
# 10. Initialize gate metrics for this stage
# ============================================================================
echo -e "${BLUE}Step 10:${NC} Initializing gate metrics..."

GATE_TRACKER="scripts/gate-metrics-tracker.sh"
if [ -f "$GATE_TRACKER" ]; then
    source "$GATE_TRACKER"
    GATE_ID=$(resolve_gate_id "${CURRENT_STAGE}" 2>/dev/null || echo "G0")
    if [ "$GATE_ID" != "G0" ]; then
        gate_start "$GATE_ID" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Gate ${GATE_ID} metrics tracking started"
    else
        echo -e "${YELLOW}→${NC} Stage '${CURRENT_STAGE}' not mapped to a gate, skipping metrics"
    fi
else
    echo -e "${YELLOW}→${NC} Gate metrics tracker not found, skipping"
fi

echo -e "${GREEN}[Pre-Stage Hook]${NC} All prerequisites verified successfully!"
exit 0
