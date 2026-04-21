#!/usr/bin/env bash
# validate-stage-variants.sh — Checks canonical RPI / implementation variants
#
# Usage: bash scripts/validate-stage-variants.sh [platform-root]
#
# Strict checks apply to stages/08-implementation/variants/*.md (YAML stack + link to RPI baseline).
# Other stages may still contain placeholder "Variant Template" files — those are not enforced here
# until migrated; expand this script when those files gain proper frontmatter.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT" || exit 1

FAIL=0

if [[ ! -f "stages/_includes/rpi-serialization-baseline.md" ]]; then
  echo "[fail] missing stages/_includes/rpi-serialization-baseline.md"
  FAIL=1
fi

IMP_DIR="stages/08-implementation/variants"
if [[ ! -d "$IMP_DIR" ]]; then
  echo "[fail] missing $IMP_DIR"
  exit 1
fi

while IFS= read -r -d '' f; do
  if ! head -n 40 "$f" | grep -q '^---'; then
    echo "[fail] missing YAML frontmatter: $f"
    FAIL=1
    continue
  fi
  if ! head -n 60 "$f" | grep -qE '^stack:'; then
    echo "[fail] missing stack: in frontmatter: $f"
    FAIL=1
  fi
  if ! grep -qE 'rpi-serialization-baseline|rpi-workflow\.md' "$f"; then
    echo "[fail] must reference rpi-serialization-baseline or rules/rpi-workflow: $f"
    FAIL=1
  fi
done < <(find "$IMP_DIR" -name '*.md' -type f -print0)

if [[ $FAIL -ne 0 ]]; then
  echo ""
  echo "validate-stage-variants: FAILED"
  exit 1
fi
echo "[ok] validate-stage-variants.sh — 08-implementation variants + RPI include"
exit 0
