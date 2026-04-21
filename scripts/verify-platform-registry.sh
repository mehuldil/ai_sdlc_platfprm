#!/usr/bin/env bash
# verify-platform-registry.sh — Consistency: stages ↔ dirs, agent registry, rules count
# Run from ai-sdlc-platform root: bash scripts/verify-platform-registry.sh
# Exit 0 = all checks pass; 1 = failure

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0

echo "━━━ Platform registry verification ━━━"
echo ""

# shellcheck source=../cli/lib/config.sh
# shellcheck disable=SC1091
source "${ROOT}/cli/lib/config.sh"

# Stages: STAGES array vs stages/*/STAGE.md
missing_stage=0
for s in "${STAGES[@]}"; do
  if [[ ! -f "${ROOT}/stages/${s}/STAGE.md" ]]; then
    echo "✗ Missing STAGE.md for configured stage: $s"
    missing_stage=$((missing_stage + 1))
    fail=1
  fi
done
if [[ $missing_stage -eq 0 ]]; then
  echo "✓ Stages: ${#STAGES[@]} entries match stages/*/STAGE.md"
fi

# Extra stage dirs not in STAGES (warn)
for d in "${ROOT}/stages"/*/; do
  [[ -d "$d" ]] || continue
  name=$(basename "$d")
  found=0
  for s in "${STAGES[@]}"; do
    [[ "$s" == "$name" ]] && found=1 && break
  done
  if [[ $found -eq 0 ]]; then
    echo "⚠ Stage directory not in cli/lib/config.sh STAGES: $name"
  fi
done

# agent-registry.json — every referenced agent file exists; duplicate IDs across domains
if [[ -f "${ROOT}/agents/agent-registry.json" ]]; then
  if command -v jq &>/dev/null; then
    t1=$(jq '.tier_1_universal | keys | length' "${ROOT}/agents/agent-registry.json" 2>/dev/null || echo "0")
    t2=$(jq '.tier_2_domain | keys | length' "${ROOT}/agents/agent-registry.json" 2>/dev/null || echo "0")
    echo "✓ agent-registry.json: tier_1=$t1 tier_2_domain keys=$t2 (jq)"
    missing_path=0
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      if [[ ! -f "${ROOT}/agents/${rel}" ]]; then
        echo "✗ agent-registry.json lists missing file: agents/${rel}"
        missing_path=$((missing_path + 1))
        fail=1
      fi
    done < <(jq -r '.. | objects | select(has("path")) | .path' "${ROOT}/agents/agent-registry.json" 2>/dev/null)
    if [[ $missing_path -eq 0 ]]; then
      echo "✓ agent-registry.json: all path entries exist under agents/"
    fi
    dup_ids=$(jq -r '
      [.tier_1_universal // {} | keys[]]
      + [.tier_2_domain // {} | to_entries[] | .value | keys[]]
      | group_by(.) | map(select(length > 1)) | flatten | unique | .[]
    ' "${ROOT}/agents/agent-registry.json" 2>/dev/null || true)
    if [[ -n "$(echo "$dup_ids" | tr -d '[:space:]')" ]]; then
      echo "✗ Duplicate agent IDs in registry (must be unique):"
      echo "$dup_ids" | while IFS= read -r x; do [[ -n "$x" ]] && echo "  - $x"; done
      fail=1
    else
      echo "✓ agent-registry.json: no duplicate agent IDs across tier_1 + tier_2_domain"
    fi
  else
    echo "⚠ jq not installed — skip agent-registry deep check"
  fi
else
  echo "✗ agents/agent-registry.json missing"
  fail=1
fi

# Rules (canonical markdown in rules/)
rules_n=0
if [[ -d "${ROOT}/rules" ]]; then
  rules_n=$(find "${ROOT}/rules" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
  echo "✓ rules/*.md count: $rules_n (see User_Manual/Agents_Skills_Rules.md for documented total)"
fi

# workflows
wf_n=0
if [[ -d "${ROOT}/workflows" ]]; then
  wf_n=$(find "${ROOT}/workflows" -maxdepth 1 \( -name '*.yml' -o -name '*.yaml' -o -name '*.md' \) -type f | wc -l | tr -d ' ')
  echo "✓ workflows/: $wf_n file(s)"
fi

echo ""
if [[ $fail -eq 0 ]]; then
  echo "━━━ OK ━━━"
  exit 0
else
  echo "━━━ FAILED ━━━"
  exit 1
fi
