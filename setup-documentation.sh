#!/bin/bash

################################################################################
# Documentation Automation Setup
#
# Installs and configures:
# - Registry auto-generation hooks (post-commit)
# - Documentation validation hooks (pre-commit)
# - Semantic versioning system
# - Scripts and permissions
#
# Usage:
#   ./setup-documentation.sh              (interactive)
#   ./setup-documentation.sh --silent     (non-interactive)
#   ./setup-documentation.sh --verify     (check only)
#   ./setup-documentation.sh --uninstall  (remove hooks)
#
# Called by: ./setup.sh (main setup) or manually
# Requirements: Git 2.9+, Bash 4.0+
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
MODE="${1:-interactive}"
MODE="${MODE#--}"  # Strip leading -- from argument

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
ACTIONS_TAKEN=0

# ============================================================================
# Helpers
# ============================================================================
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_action() {
    echo -e "${GREEN}→${NC} $1"
    ACTIONS_TAKEN=$((ACTIONS_TAKEN + 1))
}

# ============================================================================
# Phase: Verify Environment
# ============================================================================
verify_environment() {
    echo -e "${CYAN}Verifying environment...${NC}"

    # Check git
    if ! command -v git &> /dev/null; then
        print_error "Git not found (required: Git 2.9+)"
        return 1
    fi
    print_success "Git available"

    # Check git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        return 1
    fi
    print_success "Git repository found"

    # Check required files
    local required_files=(
        "hooks/doc-change-check.sh"
        "hooks/post-commit-registry-update.sh"
        "scripts/regenerate-registries.sh"
        "scripts/bump-version.sh"
        "User_Manual/VERSION"
        "User_Manual/CHANGELOG.md"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$REPO_ROOT/$file" ]; then
            print_error "$file NOT FOUND"
            return 1
        fi
    done
    print_success "All required files present"
}

# ============================================================================
# Phase: Make Scripts Executable
# ============================================================================
make_executable() {
    echo -e "${CYAN}Making scripts executable...${NC}"

    local scripts=(
        "hooks/doc-change-check.sh"
        "hooks/post-commit-registry-update.sh"
        "scripts/regenerate-registries.sh"
        "scripts/bump-version.sh"
        "scripts/verify-git-hooks.sh"
        "scripts/validate-system-change.sh"
        "scripts/bootstrap-sdlc-features.sh"
    )

    for script in "${scripts[@]}"; do
        if [ ! -x "$REPO_ROOT/$script" ]; then
            chmod +x "$REPO_ROOT/$script"
            print_action "chmod +x $script"
        fi
    done
    print_success "All scripts executable"
}

# ============================================================================
# Phase: Configure Git Hooks
# ============================================================================
configure_git_hooks() {
    echo -e "${CYAN}Configuring git hooks...${NC}"

    # Set core.hooksPath
    git config core.hooksPath hooks
    print_action "git config core.hooksPath hooks"

    # Verify
    if git config core.hooksPath | grep -q "hooks"; then
        print_success "core.hooksPath configured"
    else
        print_error "Failed to set core.hooksPath"
        return 1
    fi
}

# ============================================================================
# Phase: Verify Installation
# ============================================================================
verify_installation() {
    echo -e "${CYAN}Verifying installation...${NC}"

    # Test regenerate-registries.sh
    if bash "$REPO_ROOT/scripts/regenerate-registries.sh" --check >/dev/null 2>&1 || true; then
        print_success "Registry regenerator working"
    fi

    # Test bump-version.sh
    if bash "$REPO_ROOT/scripts/bump-version.sh" --show >/dev/null 2>&1; then
        local version=$(cat "$REPO_ROOT/User_Manual/VERSION")
        print_success "Version system working (current: v$version)"
    else
        print_error "Version system failed"
        return 1
    fi

    # Check hooks available
    if git config core.hooksPath > /dev/null 2>&1; then
        print_success "Git hooks configured"
    fi
}

# ============================================================================
# Phase: Uninstall Hooks
# ============================================================================
uninstall_hooks() {
    print_header "Uninstalling Documentation Automation"

    # Unset core.hooksPath if set to 'hooks'
    if git config core.hooksPath 2>/dev/null | grep -q "hooks"; then
        git config --unset core.hooksPath
        print_action "Unset core.hooksPath"
    fi

    print_success "Hooks uninstalled"
    print_info "Documentation automation disabled"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

case "$MODE" in
    uninstall)
        uninstall_hooks
        exit 0
        ;;
    verify)
        print_header "Verifying Documentation Automation"
        verify_environment || exit 1
        verify_installation || exit 1
        echo ""
        print_success "All verifications passed!"
        exit 0
        ;;
    silent|interactive)
        print_header "Documentation Automation Setup"
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Usage: $0 [interactive|silent|verify|uninstall]"
        exit 1
        ;;
esac

# ============================================================================
# Pre-flight checks
# ============================================================================
echo -e "${CYAN}Running pre-flight checks...${NC}"
verify_environment || exit 1
echo ""

# ============================================================================
# Ask for confirmation (interactive only)
# ============================================================================
if [ "$MODE" = "interactive" ]; then
    print_header "What Will Be Installed"

    cat << 'EOF'
  1. Registry Auto-Generation
     • hooks/post-commit-registry-update.sh
     • Automatically updates CAPABILITY_MATRIX.md when agents change
     • Automatically updates SKILL.md when skills change
     • Automatically updates COMMANDS_REGISTRY.md when commands change

  2. Documentation Validation
     • hooks/doc-change-check.sh
     • Validates User_Manual kept in sync with code changes
     • Blocks commits if documentation not updated (required)

  3. Semantic Versioning
     • scripts/bump-version.sh (MAJOR/MINOR/PATCH versioning)
     • User_Manual/VERSION (current: 1.0.0)
     • User_Manual/CHANGELOG.md (release history)

  4. Registry Regeneration
     • scripts/regenerate-registries.sh (on-demand registry updates)
     • Modes: --check, --update, --dry-run

After setup:
  ✓ Commits to agents/skills/rules/commands will auto-validate docs
  ✓ Registries auto-update after every commit
  ✓ Version bumping with: ./scripts/bump-version.sh --{major|minor|patch}
  ✓ Full automation available immediately

EOF

    read -p "Proceed with setup? (y/n): " response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

# ============================================================================
# Execute setup
# ============================================================================
print_header "Installing Documentation Automation"

make_executable
echo ""
configure_git_hooks
echo ""
verify_installation
echo ""

# ============================================================================
# Success Summary
# ============================================================================
print_header "Documentation Automation Installed ✓"

cat << 'EOF'
Systems Enabled:

  Registry Auto-Generation
  └─ Agents/skills/commands registries auto-update on commit

  Documentation Validation
  └─ Pre-commit hook ensures User_Manual stays in sync

  Semantic Versioning
  └─ Version management (MAJOR/MINOR/PATCH)

  Git Hooks
  └─ core.hooksPath = hooks (auto-loads all hooks)

EOF

# ============================================================================
# Next Steps
# ============================================================================
print_header "Next Steps"

cat << 'EOF'
1. Verify installation:
   $ ./setup-documentation.sh --verify

2. See your current version:
   $ ./scripts/bump-version.sh --show

3. Test dry-run of registry regeneration:
   $ ./scripts/regenerate-registries.sh --dry-run

4. Read the documentation automation guide:
   $ cat REGISTRY_VERSIONING_GUIDE.md

5. Make a test commit to see hooks in action:
   $ git commit --allow-empty -m "test: verify hooks work"

6. To uninstall (if needed):
   $ ./setup-documentation.sh --uninstall

EOF

print_success "Setup completed successfully!"
print_info "Documentation automation is active and ready!"

exit 0
