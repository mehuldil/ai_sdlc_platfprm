#!/bin/bash
# AI-SDLC PR Validation Script
# Run before submitting pull request: ./scripts/validate-pr.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}AI-SDLC PR Validation${NC}\n"

# 1. Check file naming (kebab-case)
echo -e "${BLUE}→${NC} Checking file naming conventions..."
ISSUES=0
for file in $(git diff --cached --name-only); do
  filename=$(basename "$file")
  if [[ $filename =~ [A-Z] ]] && [[ ! $filename =~ \.json$ ]] && [[ ! $filename =~ \.yml$ ]]; then
    echo -e "${RED}✗${NC} File has uppercase: $file (should be kebab-case)"
    ISSUES=$((ISSUES+1))
  fi
done
[[ $ISSUES -eq 0 ]] && echo -e "${GREEN}✓${NC} All files follow naming convention"

# 2. Check for secrets
echo -e "\n${BLUE}→${NC} Scanning for secrets..."
SECRETS=0
for file in $(git diff --cached --name-only); do
  if grep -qE '(password|secret|api.?key|token|private.?key)\s*[:=]' "$file" 2>/dev/null; then
    echo -e "${RED}✗${NC} Potential secret in: $file"
    SECRETS=$((SECRETS+1))
  fi
done
[[ $SECRETS -eq 0 ]] && echo -e "${GREEN}✓${NC} No secrets detected"

# 3. Check for absolute paths
echo -e "\n${BLUE}→${NC} Checking for absolute paths..."
PATHS=0
for file in $(git diff --cached --name-only); do
  if grep -qE '^\s*[/]sessions/' "$file" 2>/dev/null; then
    echo -e "${RED}✗${NC} Absolute path found in: $file"
    PATHS=$((PATHS+1))
  fi
done
[[ $PATHS -eq 0 ]] && echo -e "${GREEN}✓${NC} No absolute paths"

# 4. Check line counts by type
echo -e "\n${BLUE}→${NC} Checking file sizes..."
for file in $(git diff --cached --name-only); do
  lines=$(wc -l < "$file")
  if [[ $file == rules/* ]] && [[ $lines -gt 150 ]]; then
    echo -e "${YELLOW}⚠${NC} Rule file large: $file ($lines lines, target <100)"
  fi
  if [[ $file == agents/* ]] && [[ $lines -gt 200 ]]; then
    echo -e "${YELLOW}⚠${NC} Agent file large: $file ($lines lines, target <150)"
  fi
  if [[ $file == skills/* ]] && [[ $lines -gt 250 ]]; then
    echo -e "${YELLOW}⚠${NC} Skill file large: $file ($lines lines, target <200)"
  fi
done
echo -e "${GREEN}✓${NC} File size checks complete"

# 5. Check for duplication
echo -e "\n${BLUE}→${NC} Checking for potential duplicates..."
echo -e "${YELLOW}ℹ${NC} Run: grep -r 'pattern' . to find similar content"

# 6. Summary
echo -e "\n${BLUE}═════════════════════════════════════════${NC}"
[[ $ISSUES -eq 0 && $SECRETS -eq 0 && $PATHS -eq 0 ]] && \
  echo -e "${GREEN}✓ PR validation passed! Ready to submit.${NC}" || \
  echo -e "${RED}✗ Fix issues above before submitting PR${NC}"
echo -e "${BLUE}═════════════════════════════════════════${NC}\n"

[[ $ISSUES -gt 0 || $SECRETS -gt 0 || $PATHS -gt 0 ]] && exit 1
exit 0
