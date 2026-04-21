#!/bin/bash

################################################################################
# AI-SDLC Platform Cross-Tool Validation Script
#
# Validates platform compatibility across multiple tools:
#   - Claude Code
#   - Cursor IDE
#   - Cursor Chat
#   - CLI
#   - /project: commands
#
# Usage: ./scripts/validate-cross-tool.sh [--verbose] [--fix]
################################################################################

set -u

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(dirname "$SCRIPT_DIR")"

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
VERBOSE=${VERBOSE:-0}
FIX_MODE=${FIX_MODE:-0}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --fix)
            FIX_MODE=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Counters for summary
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0
FAILED_CHECKS=0

# Arrays to track results
declare -a FAILED_ITEMS=()
declare -a WARNING_ITEMS=()
declare -a BROKEN_SYMLINKS=()

################################################################################
# Helper Functions
################################################################################

log_pass() {
    local message="$1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -e "${GREEN}PASS${NC}: $message"
}

log_fail() {
    local message="$1"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    FAILED_ITEMS+=("$message")
    echo -e "${RED}FAIL${NC}: $message"
}

log_warn() {
    local message="$1"
    WARNINGS=$((WARNINGS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    WARNING_ITEMS+=("$message")
    echo -e "${YELLOW}WARN${NC}: $message"
}

log_info() {
    local message="$1"
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${BLUE}INFO${NC}: $message"
    fi
}

check_file_exists() {
    local path="$1"
    local name="$2"

    if [[ -f "$path" ]]; then
        log_pass "File exists: $name"
        return 0
    else
        log_fail "File missing: $name ($path)"
        return 1
    fi
}

check_dir_exists() {
    local path="$1"
    local name="$2"

    if [[ -d "$path" ]]; then
        log_pass "Directory exists: $name"
        return 0
    else
        log_fail "Directory missing: $name ($path)"
        return 1
    fi
}

check_executable() {
    local path="$1"
    local name="$2"

    if [[ -x "$path" ]]; then
        log_pass "Executable: $name"
        return 0
    else
        log_fail "Not executable: $name ($path)"
        return 1
    fi
}

check_symlink_health() {
    local target="$1"
    local source_path="$2"

    if [[ -L "$source_path" ]]; then
        local target_path=$(readlink "$source_path")

        # Check if target exists
        if [[ ! -e "$source_path" ]]; then
            BROKEN_SYMLINKS+=("$source_path -> $target_path")
            log_fail "Broken symlink: $(basename "$source_path") -> $target_path"
            return 1
        fi

        # Check if symlink uses relative path (not absolute session path)
        if [[ "$target_path" == /* ]]; then
            log_warn "Absolute path symlink: $(basename "$source_path") -> $target_path (should use relative path)"
            return 1
        fi

        log_pass "Symlink health: $(basename "$source_path")"
        return 0
    else
        log_fail "Not a symlink: $source_path"
        return 1
    fi
}

################################################################################
# Section 1: Claude Code Compatibility
################################################################################

validate_claude_code() {
    echo ""
    echo -e "${BLUE}=== SECTION 1: Claude Code Compatibility ===${NC}"

    # .claude/commands/ exists with .md files
    if check_dir_exists "$PLATFORM_ROOT/.claude/commands" ".claude/commands"; then
        local cmd_count=$(find "$PLATFORM_ROOT/.claude/commands" -maxdepth 1 -type f -name "*.md" | wc -l)
        if [[ $cmd_count -gt 0 ]]; then
            log_pass ".claude/commands has $cmd_count command files"
        else
            log_warn ".claude/commands exists but has no .md files"
        fi
    fi

    # .claude/agents: either one symlink to canonical agents/ (preferred) or per-file symlinks (legacy)
    if [[ -e "$PLATFORM_ROOT/.claude/agents" ]]; then
        if [[ -L "$PLATFORM_ROOT/.claude/agents" ]]; then
            log_pass ".claude/agents → canonical agents/ (single symlink, full tree)"
            check_symlink_health "agents-dir" "$PLATFORM_ROOT/.claude/agents"
        elif [[ -d "$PLATFORM_ROOT/.claude/agents" ]]; then
            local agent_count=$(find "$PLATFORM_ROOT/.claude/agents" -maxdepth 1 -type l 2>/dev/null | wc -l)
            if [[ $agent_count -gt 0 ]]; then
                log_pass ".claude/agents has $agent_count per-file agent symlinks (legacy layout)"
                while IFS= read -r symlink; do
                    check_symlink_health "agent" "$symlink"
                done < <(find "$PLATFORM_ROOT/.claude/agents" -maxdepth 1 -type l 2>/dev/null)
            else
                log_warn ".claude/agents is a directory without symlinks — re-run setup or scripts/repair-claude-mirrors.sh"
            fi
        fi
    fi

    # .claude/rules/ exists with symlinks
    if check_dir_exists "$PLATFORM_ROOT/.claude/rules" ".claude/rules"; then
        local rules_count=$(find "$PLATFORM_ROOT/.claude/rules" -maxdepth 1 -type f -name "*.md" | wc -l)
        if [[ $rules_count -gt 0 ]]; then
            log_pass ".claude/rules has $rules_count rule files"
        else
            log_warn ".claude/rules exists but has no .md files"
        fi
    fi

    # .claude/skills: single symlink to canonical skills/ (preferred) or legacy per-entry symlinks
    if [[ -e "$PLATFORM_ROOT/.claude/skills" ]]; then
        if [[ -L "$PLATFORM_ROOT/.claude/skills" ]]; then
            log_pass ".claude/skills → canonical skills/ (single symlink, full tree)"
            check_symlink_health "skills-dir" "$PLATFORM_ROOT/.claude/skills"
        elif [[ -d "$PLATFORM_ROOT/.claude/skills" ]]; then
            local skills_count=$(find "$PLATFORM_ROOT/.claude/skills" -maxdepth 1 -type l 2>/dev/null | wc -l)
            if [[ $skills_count -gt 0 ]]; then
                log_pass ".claude/skills has $skills_count per-entry symlinks (legacy layout)"
                while IFS= read -r symlink; do
                    check_symlink_health "skill" "$symlink"
                done < <(find "$PLATFORM_ROOT/.claude/skills" -maxdepth 1 -type l 2>/dev/null)
            else
                log_warn ".claude/skills is a directory without symlinks — re-run setup or scripts/repair-claude-mirrors.sh"
            fi
        fi
    fi

    # .claude/settings.json exists
    check_file_exists "$PLATFORM_ROOT/.claude/settings.json" ".claude/settings.json"

    # .mcp.json exists (either at root or in .claude)
    if [[ -f "$PLATFORM_ROOT/.mcp.json" ]] || [[ -f "$PLATFORM_ROOT/.claude/.mcp.json" ]]; then
        log_pass ".mcp.json exists"
    else
        log_fail ".mcp.json missing (not found at root or .claude/)"
    fi
}

################################################################################
# Section 2: Cursor IDE Compatibility
################################################################################

validate_cursor_ide() {
    echo ""
    echo -e "${BLUE}=== SECTION 2: Cursor IDE Compatibility ===${NC}"

    # .cursor/rules/ exists
    if check_dir_exists "$PLATFORM_ROOT/.cursor/rules" ".cursor/rules"; then
        # command-*.md files
        local cmd_rules=$(find "$PLATFORM_ROOT/.cursor/rules" -maxdepth 1 -type l -name "command-*" 2>/dev/null | wc -l)
        if [[ $cmd_rules -gt 0 ]]; then
            log_pass ".cursor/rules has $cmd_rules command rules (symlinks)"
        else
            log_info "No command-*.md rules found in .cursor/rules (may use different naming)"
        fi

        # rule-*.md symlinks (agents/skills NOT in .cursor/rules — they load on-demand)
        local rules=$(find "$PLATFORM_ROOT/.cursor/rules" -maxdepth 1 -type l -name "rule-*.md" 2>/dev/null | wc -l)
        if [[ $rules -gt 0 ]]; then
            log_pass ".cursor/rules has $rules platform rules"
        else
            log_warn ".cursor/rules has no rule-*.md files"
        fi

        # Check symlink health for cursor rules
        while IFS= read -r symlink; do
            check_symlink_health "cursor-rule" "$symlink"
        done < <(find "$PLATFORM_ROOT/.cursor/rules" -maxdepth 1 -type l 2>/dev/null)
    fi

    # .cursor/mcp.json exists
    check_file_exists "$PLATFORM_ROOT/.cursor/mcp.json" ".cursor/mcp.json"
}

################################################################################
# Section 3: CLI Compatibility
################################################################################

validate_cli() {
    echo ""
    echo -e "${BLUE}=== SECTION 3: CLI Compatibility ===${NC}"

    # cli/sdlc.sh exists and executable
    check_executable "$PLATFORM_ROOT/cli/sdlc.sh" "cli/sdlc.sh"

    # cli/sdlc-setup.sh exists and executable
    check_executable "$PLATFORM_ROOT/cli/sdlc-setup.sh" "cli/sdlc-setup.sh"

    # cli/lib/ has required modules
    local required_modules=(
        "logging.sh"
        "config.sh"
        "guards.sh"
        "executor.sh"
        "ado.sh"
    )

    local missing_modules=0
    for module in "${required_modules[@]}"; do
        if check_file_exists "$PLATFORM_ROOT/cli/lib/$module" "cli/lib/$module"; then
            true
        else
            missing_modules=$((missing_modules + 1))
        fi
    done

    if [[ $missing_modules -eq 0 ]]; then
        log_pass "All required CLI modules present"
    else
        log_fail "Missing $missing_modules CLI modules"
    fi

    # Check stage scripts referenced in sdlc.sh
    if [[ -f "$PLATFORM_ROOT/cli/sdlc.sh" ]]; then
        # Extract stage references
        local stages=$(grep -o "stages/[a-zA-Z0-9_-]*\.sh" "$PLATFORM_ROOT/cli/sdlc.sh" | sort -u 2>/dev/null || true)
        if [[ -n "$stages" ]]; then
            while IFS= read -r stage; do
                stage_path="$PLATFORM_ROOT/cli/$stage"
                if [[ -f "$stage_path" ]]; then
                    log_pass "Stage script exists: $stage"
                else
                    log_warn "Stage script missing: $stage"
                fi
            done <<< "$stages"
        fi
    fi
}

################################################################################
# Section 4: Symlink Health Check
################################################################################

validate_symlink_health() {
    echo ""
    echo -e "${BLUE}=== SECTION 4: Symlink Health ===${NC}"

    local total_symlinks=0
    local broken_symlinks_count=0
    local absolute_symlinks=0

    # Find all symlinks
    while IFS= read -r symlink; do
        total_symlinks=$((total_symlinks + 1))
        local target=$(readlink "$symlink")

        # Check if broken
        if [[ ! -e "$symlink" ]]; then
            broken_symlinks_count=$((broken_symlinks_count + 1))
        fi

        # Check if absolute path
        if [[ "$target" == /* ]]; then
            absolute_symlinks=$((absolute_symlinks + 1))
        fi
    done < <(find "$PLATFORM_ROOT/.claude" "$PLATFORM_ROOT/.cursor" -type l 2>/dev/null)

    log_pass "Total symlinks found: $total_symlinks"

    if [[ $broken_symlinks_count -eq 0 ]]; then
        log_pass "Broken symlinks: 0"
    else
        log_fail "Broken symlinks: $broken_symlinks_count"
    fi

    if [[ $absolute_symlinks -eq 0 ]]; then
        log_pass "Absolute path symlinks: 0 (all use relative paths)"
    else
        log_warn "Absolute path symlinks: $absolute_symlinks (should use relative paths)"
    fi

    # Display broken symlinks
    if [[ ${#BROKEN_SYMLINKS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Broken Symlinks:${NC}"
        for symlink in "${BROKEN_SYMLINKS[@]}"; do
            echo "  - $symlink"
        done
    fi
}

################################################################################
# Section 5: File Consistency
################################################################################

validate_file_consistency() {
    echo ""
    echo -e "${BLUE}=== SECTION 5: File Consistency ===${NC}"

    # Skills matching
    echo ""
    echo "Checking skill symlinks consistency..."
    if [[ -d "$PLATFORM_ROOT/skills" ]] && [[ -d "$PLATFORM_ROOT/.claude/skills" ]]; then
        local skills_in_dir=$(find "$PLATFORM_ROOT/skills" -maxdepth 1 \( -type f -o -type d \) ! -name "." ! -name ".." | wc -l)
        local symlink_count=$(find "$PLATFORM_ROOT/.claude/skills" -maxdepth 1 -type l | wc -l)

        if [[ $skills_in_dir -gt 0 ]] && [[ $symlink_count -gt 0 ]]; then
            log_pass "Skills directory has $skills_in_dir items, .claude/skills has $symlink_count symlinks"
        else
            log_warn "Skills inconsistency: skills/ has $skills_in_dir items, symlinks has $symlink_count"
        fi
    fi

    # Agents matching
    echo ""
    echo "Checking agent symlinks consistency..."
    if [[ -d "$PLATFORM_ROOT/agents/shared" ]] && [[ -d "$PLATFORM_ROOT/.claude/agents" ]]; then
        local agents_in_dir=$(find "$PLATFORM_ROOT/agents/shared" -maxdepth 1 -type f -name "*.md" | wc -l)
        local agent_symlinks=$(find "$PLATFORM_ROOT/.claude/agents" -maxdepth 1 -type l | wc -l)

        if [[ $agents_in_dir -gt 0 ]] && [[ $agent_symlinks -gt 0 ]]; then
            log_pass "agents/shared has $agents_in_dir files, .claude/agents has $agent_symlinks symlinks"
        else
            log_warn "Agent inconsistency: agents/shared has $agents_in_dir files, symlinks has $agent_symlinks"
        fi
    fi

    # Rules matching
    echo ""
    echo "Checking rule file consistency..."
    if [[ -d "$PLATFORM_ROOT/rules" ]] && [[ -d "$PLATFORM_ROOT/.claude/rules" ]]; then
        local rules_in_dir=$(find "$PLATFORM_ROOT/rules" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l)
        local claude_rules=$(find "$PLATFORM_ROOT/.claude/rules" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l)

        if [[ $rules_in_dir -gt 0 ]]; then
            log_pass "rules/ has $rules_in_dir files"
        else
            log_info "rules/ directory not found or empty (may be stored elsewhere)"
        fi
    fi

    # Cursor rules consistency
    if [[ -d "$PLATFORM_ROOT/.cursor/rules" ]]; then
        local cursor_rules=$(find "$PLATFORM_ROOT/.cursor/rules" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l)
        local cursor_symlinks=$(find "$PLATFORM_ROOT/.cursor/rules" -maxdepth 1 -type l 2>/dev/null | wc -l)
        local total_cursor_rules=$((cursor_rules + cursor_symlinks))

        if [[ $total_cursor_rules -gt 0 ]]; then
            log_pass ".cursor/rules has $cursor_rules files and $cursor_symlinks symlinks"
        else
            log_warn ".cursor/rules is empty"
        fi
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    echo ""
    echo "================================================================"
    echo "  AI-SDLC Platform Cross-Tool Validation"
    echo "  Platform Root: $PLATFORM_ROOT"
    echo "================================================================"

    # Run validation sections
    validate_claude_code
    validate_cursor_ide
    validate_cli
    validate_symlink_health
    validate_file_consistency

    # Print summary
    echo ""
    echo "================================================================"
    echo "  Validation Summary"
    echo "================================================================"
    echo ""
    echo "Total Checks:   $TOTAL_CHECKS"
    echo -e "  ${GREEN}Passed:  $PASSED_CHECKS${NC}"
    echo -e "  ${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "  ${RED}Failed:  $FAILED_CHECKS${NC}"
    echo ""

    # Show failed items
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        echo -e "${RED}Failed Checks:${NC}"
        for item in "${FAILED_ITEMS[@]}"; do
            echo "  - $item"
        done
        echo ""
    fi

    # Show warnings
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}Warnings:${NC}"
        for item in "${WARNING_ITEMS[@]}"; do
            echo "  - $item"
        done
        echo ""
    fi

    # Overall status
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}Overall Status: PASS${NC}"
        return 0
    elif [[ $FAILED_CHECKS -le 2 ]]; then
        echo -e "${YELLOW}Overall Status: WARN (Minor issues detected)${NC}"
        return 1
    else
        echo -e "${RED}Overall Status: FAIL (Multiple issues detected)${NC}"
        return 2
    fi
}

main
exit $?
