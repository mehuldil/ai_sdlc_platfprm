#!/usr/bin/env bash
# hooks/post-story-create.sh — Post-tool hook: validate AI-created work items have required tags
#
# Hook type: PostToolUse
# Applies to: mcp__ado-mcp__createWorkItem
#
# Purpose: Warn when AI-created work items are missing recommended tags.
# These tags help with tracking, routing, and filtering AI-generated content.
#
# Required Tags for Stories:
#   claude:generated — Indicates AI-generated work item
#   story:product|backend|frontend|database|qa — Story type classification
#
# See: rules/ado-standards.md

set -euo pipefail

# Read input from stdin
INPUT="$(cat)"

# Extract tool name
TOOL_NAME="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)"

# Only apply to work item creation
if [ "$TOOL_NAME" != "mcp__ado-mcp__createWorkItem" ]; then
    exit 0
fi

# Extract tool response (output of the work item creation)
TOOL_OUTPUT="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get('tool_response', {})))" 2>/dev/null || echo "{}")"

# Extract work item details
WI_ID="$(echo "$TOOL_OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || true)"
WI_TYPE="$(echo "$TOOL_OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('fields',{}).get('System.WorkItemType',''))" 2>/dev/null || true)"
TAGS="$(echo "$TOOL_OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('fields',{}).get('System.Tags',''))" 2>/dev/null || true)"

# Only validate stories and features; skip tasks and bugs
case "$WI_TYPE" in
    "User Story"|"Story"|"Feature")
        # Continue with validation
        ;;
    *)
        # Not a story type; skip
        exit 0
        ;;
esac

WARNINGS=()

# Check for claude:generated tag
if ! echo "$TAGS" | grep -qi "claude:generated"; then
    WARNINGS+=("Missing 'claude:generated' tag on AB#$WI_ID (indicates AI-created story)")
fi

# Check for story type tag
if ! echo "$TAGS" | grep -qiE "story:(product|backend|frontend|database|qa)"; then
    WARNINGS+=("Missing story type tag (story:product|story:backend|story:frontend|story:database|story:qa) on AB#$WI_ID")
fi

# Output warnings if any found
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo "--- post-story-create validation warnings ---"
    for w in "${WARNINGS[@]}"; do
        echo "  [!] $w"
    done
    echo "--- end warnings ---"
    echo ""
    echo "Recommendation: Consider adding missing tags to AB#$WI_ID for better tracking and filtering."
fi

exit 0
