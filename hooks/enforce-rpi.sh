#!/usr/bin/env bash
# hooks/enforce-rpi.sh — RPI Workflow Advisory (Warn, Never Block)
#
# ADVISORY: Checks if RPI workflow is recommended but does NOT block.
# If RPI is needed, logs warning for chat-based user decision.
#
# Routes requiring RPI:
#   - NEW_FEATURE (>3 files)
#   - REFACTOR (>3 files)
#   - Complex BUG_FIX
#
# Routes that skip RPI:
#   - HOTFIX (P0 emergency)
#   - CONFIG_CHANGE (config-only)
#   - UI_TWEAK (<2 files)
#
# See: rules/rpi-workflow.md

set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)"

# Only advise on file writes
case "$TOOL_NAME" in
    Write|Edit|NotebookEdit) ;;
    *) exit 0 ;;
esac

ROUTE="$(cat .sdlc/route 2>/dev/null || echo "")"
STORY_ID="$(cat .sdlc/story-id 2>/dev/null || echo "")"

log_dir=".sdlc/logs"
mkdir -p "$log_dir"
log_file="$log_dir/rpi-advisory.txt"

# Check if RPI is recommended
case "$ROUTE" in
    NEW_FEATURE|REFACTOR|BUG_FIX)
        if [ -n "$STORY_ID" ]; then
            # Check if RPI plan exists
            if [ ! -f ".sdlc/rpi/$STORY_ID/.approved-plan" ]; then
                {
                    echo "⚠️  RPI Advisory: This route ($ROUTE) typically needs RPI workflow"
                    echo "   Story: $STORY_ID"
                    echo "   Recommended: sdlc rpi research $STORY_ID → plan → implement"
                    echo "   You can proceed without RPI, but plan-first reduces rework"
                } >> "$log_file"
            fi
        fi
        ;;
esac

# Log advisory if found
if [ -f "$log_file" ]; then
    {
        echo ""
        echo "--- RPI Workflow Advisory ($(date -u +%Y-%m-%dT%H:%M:%SZ)) ---"
        cat "$log_file"
        echo "--- Decision: You can proceed directly or use RPI first. ---"
    } >> "$log_file"
fi

# ADVISORY ONLY: Never block (exit 0)
exit 0
