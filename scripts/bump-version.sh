#!/bin/bash

################################################################################
# Semantic Version Bump Script for User_Manual
#
# Manages version bumping for User_Manual following semantic versioning:
# - MAJOR (X.0.0): Breaking changes (stages, roles, commands)
# - MINOR (0.X.0): New features (agents, skills, integrations)
# - PATCH (0.0.X): Bug fixes and clarifications
#
# Usage:
#   ./scripts/bump-version.sh --major    (bump X.0.0 → (X+1).0.0)
#   ./scripts/bump-version.sh --minor    (bump X.Y.0 → X.(Y+1).0)
#   ./scripts/bump-version.sh --patch    (bump X.Y.Z → X.Y.(Z+1))
#   ./scripts/bump-version.sh --show     (display current version)
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
VERSION_FILE="User_Manual/VERSION"
CHANGELOG_FILE="User_Manual/CHANGELOG.md"

# ============================================================================
# Function: Show current version
# ============================================================================
show_version() {
    if [ ! -f "$VERSION_FILE" ]; then
        echo -e "${RED}ERROR${NC}: VERSION file not found at $VERSION_FILE"
        exit 1
    fi

    local current_version=$(cat "$VERSION_FILE")
    echo -e "${BLUE}Current Version${NC}: ${GREEN}$current_version${NC}"
}

# ============================================================================
# Function: Parse version components
# ============================================================================
parse_version() {
    local version="$1"
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3)

    echo "$major $minor $patch"
}

# ============================================================================
# Function: Bump major version
# ============================================================================
bump_major() {
    local current=$(cat "$VERSION_FILE")
    local parts=($(parse_version "$current"))
    local major=$((parts[0] + 1))
    local new_version="${major}.0.0"

    echo -e "${YELLOW}→${NC} Bumping MAJOR version: $current → $new_version"

    update_version "$new_version" "MAJOR"
}

# ============================================================================
# Function: Bump minor version
# ============================================================================
bump_minor() {
    local current=$(cat "$VERSION_FILE")
    local parts=($(parse_version "$current"))
    local major=${parts[0]}
    local minor=$((parts[1] + 1))
    local new_version="${major}.${minor}.0"

    echo -e "${YELLOW}→${NC} Bumping MINOR version: $current → $new_version"

    update_version "$new_version" "MINOR"
}

# ============================================================================
# Function: Bump patch version
# ============================================================================
bump_patch() {
    local current=$(cat "$VERSION_FILE")
    local parts=($(parse_version "$current"))
    local major=${parts[0]}
    local minor=${parts[1]}
    local patch=$((parts[2] + 1))
    local new_version="${major}.${minor}.${patch}"

    echo -e "${YELLOW}→${NC} Bumping PATCH version: $current → $new_version"

    update_version "$new_version" "PATCH"
}

# ============================================================================
# Function: Update version files
# ============================================================================
update_version() {
    local new_version="$1"
    local bump_type="$2"
    local timestamp=$(date -u +"%Y-%m-%d")

    # Update VERSION file
    echo "$new_version" > "$VERSION_FILE"
    echo -e "${GREEN}✓${NC} Updated $VERSION_FILE → $new_version"

    # Update CHANGELOG.md with new section
    local temp_changelog="${CHANGELOG_FILE}.tmp.$$"

    # Extract header (up to first version block)
    head -n 30 "$CHANGELOG_FILE" > "$temp_changelog"

    cat >> "$temp_changelog" << EOF

## [$new_version] - $timestamp

### $bump_type Release

#### Added
- Documentation updates and improvements

#### Changed
- Version bump to $new_version

---

EOF

    # Append rest of changelog (skip old headers)
    tail -n +31 "$CHANGELOG_FILE" >> "$temp_changelog"

    mv "$temp_changelog" "$CHANGELOG_FILE"
    echo -e "${GREEN}✓${NC} Updated $CHANGELOG_FILE with version $new_version"
}

# ============================================================================
# Function: Validate git status
# ============================================================================
validate_git_status() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}ERROR${NC}: Not in a git repository"
        exit 1
    fi

    # Warn if uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${YELLOW}⚠${NC} You have uncommitted changes"
        echo -e "   Recommend: ${BLUE}git status${NC} to review"
        echo -e "   Proceed? (y/n)"
        read -r proceed
        if [ "$proceed" != "y" ]; then
            echo "Cancelled."
            exit 0
        fi
    fi
}

# ============================================================================
# Function: Show next steps
# ============================================================================
show_next_steps() {
    local new_version="$1"

    echo ""
    echo -e "${BLUE}[Next Steps]${NC}"
    echo ""
    echo "1. Review changes:"
    echo -e "   ${BLUE}git diff ${VERSION_FILE} ${CHANGELOG_FILE}${NC}"
    echo ""
    echo "2. Stage version bump:"
    echo -e "   ${BLUE}git add ${VERSION_FILE} ${CHANGELOG_FILE}${NC}"
    echo ""
    echo "3. Commit version bump:"
    echo -e "   ${BLUE}git commit -m \"docs(user-manual): Release v${new_version}\"${NC}"
    echo ""
    echo "4. Create git tag:"
    echo -e "   ${BLUE}git tag -a v${new_version} -m \"User Manual v${new_version}\"${NC}"
    echo ""
    echo "5. Push to remote:"
    echo -e "   ${BLUE}git push && git push --tags${NC}"
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

if [ $# -eq 0 ]; then
    echo -e "${RED}ERROR${NC}: Missing argument"
    echo ""
    echo "Usage:"
    echo "  ./scripts/bump-version.sh --major    (X.0.0 bump)"
    echo "  ./scripts/bump-version.sh --minor    (0.X.0 bump)"
    echo "  ./scripts/bump-version.sh --patch    (0.0.X bump)"
    echo "  ./scripts/bump-version.sh --show     (show current version)"
    exit 1
fi

case "$1" in
    --major)
        validate_git_status
        bump_major
        show_next_steps "$(cat "$VERSION_FILE")"
        ;;
    --minor)
        validate_git_status
        bump_minor
        show_next_steps "$(cat "$VERSION_FILE")"
        ;;
    --patch)
        validate_git_status
        bump_patch
        show_next_steps "$(cat "$VERSION_FILE")"
        ;;
    --show)
        show_version
        ;;
    *)
        echo -e "${RED}ERROR${NC}: Unknown argument: $1"
        exit 1
        ;;
esac

exit 0
