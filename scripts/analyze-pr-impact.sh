#!/bin/bash
# Analyze impact of changes in current branch vs main

set -e

BRANCH=${1:-HEAD}
BASE=${2:-main}

echo "Analyzing impact of: $BRANCH vs $BASE\n"

# Files changed
echo "## Files Changed"
git diff $BASE...$BRANCH --name-only

# Line changes
echo -e "\n## Statistics"
git diff $BASE...$BRANCH --stat

# References to changed files
echo -e "\n## Possible Impact (files that reference changed files)"
CHANGED_FILES=$(git diff $BASE...$BRANCH --name-only)
for file in $CHANGED_FILES; do
  BASENAME=$(basename "$file" .md)
  echo -e "\nFile: $file"
  grep -r "$(basename $BASENAME)" . --include="*.md" 2>/dev/null | grep -v "$file" | head -5 || echo "  (no direct references found)"
done

echo -e "\n## Recommendation"
echo "Review impact analysis above. High impact = more review time needed."
