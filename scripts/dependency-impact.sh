#!/usr/bin/env bash
################################################################################
# Dependency Impact Checker (R3)
# Takes a file path as argument and finds all files that reference/import/symlink
# to the given file. Reports impact radius.
#
# Usage: dependency-impact.sh <file-path> [--verbose]
# Example: dependency-impact.sh .claude/rules/token-enforcement.md
#
# Checks:
# - Grep references in agent/command/skill files
# - Symlinks pointing to file
# - agent-registry.json entries
# - Import statements in scripts
################################################################################

set -eo pipefail

TARGET_FILE="${1:-.}"
VERBOSE="${2:-}"
PLATFORM_DIR="."

if [[ -z "$TARGET_FILE" || "$TARGET_FILE" == "--"* ]]; then
  echo "Usage: dependency-impact.sh <target-file> [--verbose]"
  echo ""
  echo "Examples:"
  echo "  dependency-impact.sh .claude/rules/token-enforcement.md"
  echo "  dependency-impact.sh cli/lib/executor.sh --verbose"
  echo ""
  echo "Output: Shows all files that reference the target file"
  exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_error() {
  echo -e "${RED}✗${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}⚠${NC}  $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_info() {
  echo -e "${BLUE}→${NC} $1"
}

log_section() {
  echo ""
  echo -e "${BLUE}=== $1 ===${NC}"
  echo ""
}

# ============================================================================
# Normalize target file path
# ============================================================================

# Remove leading ./ if present
TARGET_FILE="${TARGET_FILE#./}"

# Extract the filename (with extension)
TARGET_BASENAME=$(basename "$TARGET_FILE")
TARGET_BASENAME_NO_EXT="${TARGET_BASENAME%.*}"

# Check if target file exists (if absolute path given)
if [[ "$TARGET_FILE" == /* ]]; then
  if [[ ! -f "$TARGET_FILE" ]]; then
    log_error "File not found: $TARGET_FILE"
    exit 1
  fi
  SEARCH_PATH="$PLATFORM_DIR"
else
  SEARCH_PATH="$PLATFORM_DIR"
  # Convert to relative path from PLATFORM_DIR
  if [[ ! -f "$PLATFORM_DIR/$TARGET_FILE" ]]; then
    log_warn "File may not exist: $PLATFORM_DIR/$TARGET_FILE (continuing search anyway)"
  fi
fi

log_section "Dependency Impact Analysis"

echo "Target file: $TARGET_FILE"
echo "Search path: $SEARCH_PATH"
echo ""

# ============================================================================
# Initialize counters
# ============================================================================

IMPACT_FILES=()
GREP_REFS=0
SYMLINK_REFS=0
REGISTRY_REFS=0

# ============================================================================
# SEARCH 1: Grep for filename references
# ============================================================================

log_info "Searching for text references to: $TARGET_BASENAME"

# Search in agent files
if [[ -d "$PLATFORM_DIR/.claude/agents" ]]; then
  while IFS= read -r file; do
    if grep -l "$TARGET_BASENAME\|$TARGET_BASENAME_NO_EXT\|$TARGET_FILE" "$file" 2>/dev/null; then
      IMPACT_FILES+=("$file")
      GREP_REFS=$((GREP_REFS + 1))
    fi
  done < <(find "$PLATFORM_DIR/.claude/agents" -name "*.md" -type f 2>/dev/null || true)
fi

# Search in command files
if [[ -d "$PLATFORM_DIR/.claude/commands" ]]; then
  while IFS= read -r file; do
    if grep -l "$TARGET_BASENAME\|$TARGET_BASENAME_NO_EXT\|$TARGET_FILE" "$file" 2>/dev/null; then
      IMPACT_FILES+=("$file")
      GREP_REFS=$((GREP_REFS + 1))
    fi
  done < <(find "$PLATFORM_DIR/.claude/commands" -name "*.md" -type f 2>/dev/null || true)
fi

# Search in skill files
if [[ -d "$PLATFORM_DIR/.claude/skills" ]]; then
  while IFS= read -r file; do
    if grep -l "$TARGET_BASENAME\|$TARGET_BASENAME_NO_EXT\|$TARGET_FILE" "$file" 2>/dev/null; then
      IMPACT_FILES+=("$file")
      GREP_REFS=$((GREP_REFS + 1))
    fi
  done < <(find "$PLATFORM_DIR/.claude/skills" -name "*.md" -type f 2>/dev/null || true)
fi

# Search in scripts
if [[ -d "$PLATFORM_DIR/scripts" ]]; then
  while IFS= read -r file; do
    if grep -l "$TARGET_BASENAME\|$TARGET_BASENAME_NO_EXT\|$TARGET_FILE" "$file" 2>/dev/null; then
      IMPACT_FILES+=("$file")
      GREP_REFS=$((GREP_REFS + 1))
    fi
  done < <(find "$PLATFORM_DIR/scripts" -name "*.sh" -type f 2>/dev/null || true)
fi

# Search in cli
if [[ -d "$PLATFORM_DIR/cli" ]]; then
  while IFS= read -r file; do
    if grep -l "$TARGET_BASENAME\|$TARGET_BASENAME_NO_EXT\|$TARGET_FILE" "$file" 2>/dev/null; then
      IMPACT_FILES+=("$file")
      GREP_REFS=$((GREP_REFS + 1))
    fi
  done < <(find "$PLATFORM_DIR/cli" -name "*.sh" -type f 2>/dev/null || true)
fi

# ============================================================================
# SEARCH 2: Find symlinks pointing to target
# ============================================================================

log_info "Searching for symlinks to: $TARGET_FILE"

while IFS= read -r symlink; do
  if [[ -L "$symlink" ]]; then
    target=$(readlink "$symlink")
    if [[ "$target" == *"$TARGET_BASENAME"* ]] || [[ "$target" == *"$TARGET_FILE"* ]]; then
      IMPACT_FILES+=("$symlink")
      SYMLINK_REFS=$((SYMLINK_REFS + 1))
    fi
  fi
done < <(find "$PLATFORM_DIR" -type l 2>/dev/null || true)

# ============================================================================
# SEARCH 3: Check agent-registry.json
# ============================================================================

log_info "Checking agent-registry.json"

if [[ -f "$PLATFORM_DIR/agents/agent-registry.json" ]]; then
  if grep -q "$TARGET_BASENAME\|$TARGET_FILE" "$PLATFORM_DIR/agents/agent-registry.json"; then
    IMPACT_FILES+=("$PLATFORM_DIR/agents/agent-registry.json")
    REGISTRY_REFS=$((REGISTRY_REFS + 1))
  fi
fi

# ============================================================================
# Deduplicate and display results
# ============================================================================

log_section "Impact Results"

UNIQUE_FILES=()
for file in "${IMPACT_FILES[@]}"; do
  # Skip if already in unique list
  if [[ ! " ${UNIQUE_FILES[@]} " =~ " ${file} " ]]; then
    UNIQUE_FILES+=("$file")
  fi
done

TOTAL_IMPACT=${#UNIQUE_FILES[@]}

if [[ $TOTAL_IMPACT -eq 0 ]]; then
  log_success "No dependencies found"
  echo ""
  echo "This file appears to be unused or newly added."
  exit 0
fi

log_warn "Changing $TARGET_FILE affects $TOTAL_IMPACT files:"
echo ""

for file in "${UNIQUE_FILES[@]}"; do
  # Show relative path from PLATFORM_DIR
  rel_path="${file#$PLATFORM_DIR/}"
  echo "  • $rel_path"

  if [[ -n "$VERBOSE" && "$VERBOSE" == "--verbose" ]]; then
    # Show matching lines
    echo "    References:"
    if grep -n "$TARGET_BASENAME\|$TARGET_BASENAME_NO_EXT\|$TARGET_FILE" "$file" 2>/dev/null | head -3; then
      :
    fi | sed 's/^/      /'
  fi
done

echo ""
log_info "Impact Summary:"
echo "  Text references: $GREP_REFS files"
echo "  Symlinks: $SYMLINK_REFS files"
echo "  Registry entries: $REGISTRY_REFS files"
echo "  Total unique files: $TOTAL_IMPACT"
echo ""

if [[ $TOTAL_IMPACT -lt 3 ]]; then
  log_success "Low impact - safe to refactor"
  exit 0
elif [[ $TOTAL_IMPACT -lt 10 ]]; then
  log_warn "Medium impact - review carefully before refactoring"
  exit 0
else
  log_warn "High impact ($TOTAL_IMPACT files) - plan refactoring carefully"
  exit 0
fi
