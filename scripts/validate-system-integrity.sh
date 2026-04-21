#!/usr/bin/env bash
################################################################################
# System Integrity Validator (Change Validation Layer)
#
# Validates platform-wide constraints after any change:
#   1. Semantic agent/skill duplication (title + purpose similarity)
#   2. Agent THIN orchestrator lint (agents should delegate to skills)
#   3. Workflow ↔ stage dependency alignment
#   4. Symlink health for .claude/.cursor
#   5. STAGE_BUDGET consistency across scripts
#
# Usage: bash scripts/validate-system-integrity.sh [platform-dir]
# Exit:  0 = clean, 1 = issues found
################################################################################

set -eo pipefail

PLATFORM_DIR="${1:-.}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_section() { echo ""; echo -e "${CYAN}━━━ $1 ━━━${NC}"; echo ""; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }
log_info()    { echo -e "${BLUE}→${NC} $1"; }

ISSUES=0

# ============================================================================
# 1. Semantic Agent/Skill Duplication
# ============================================================================

log_section "1. Agent/Skill Semantic Duplication"

_extract_title() {
  head -5 "$1" 2>/dev/null | grep -E '^#' | head -1 | sed 's/^#\+[[:space:]]*//' | tr '[:upper:]' '[:lower:]'
}

declare -A AGENT_TITLES
AGENT_DUPES=0

while IFS= read -r agent_file; do
  [[ "$agent_file" == *CAPABILITY_MATRIX* ]] && continue
  [[ "$agent_file" == *-THIN.md ]] && continue
  [[ "$agent_file" == *-FULL.md ]] && continue

  title=$(_extract_title "$agent_file")
  [[ -z "$title" ]] && continue
  # Normalize: remove "agent", "thin orchestrator", parens
  norm=$(echo "$title" | sed 's/(thin orchestrator)//; s/agent//g; s/[[:space:]]\+/ /g; s/^ //; s/ $//')

  if [[ -n "${AGENT_TITLES[$norm]:-}" ]]; then
    log_warn "Possible agent duplicate: '$agent_file' ↔ '${AGENT_TITLES[$norm]}' (title: '$norm')"
    AGENT_DUPES=$((AGENT_DUPES + 1))
    ISSUES=$((ISSUES + 1))
  else
    AGENT_TITLES["$norm"]="$agent_file"
  fi
done < <(find "$PLATFORM_DIR/agents" -name '*.md' -type f 2>/dev/null)

declare -A SKILL_TITLES
SKILL_DUPES=0

while IFS= read -r skill_file; do
  [[ "$(basename "$skill_file")" != "SKILL.md" ]] && continue
  title=$(_extract_title "$skill_file")
  [[ -z "$title" ]] && continue
  norm=$(echo "$title" | sed 's/skill//g; s/[[:space:]]\+/ /g; s/^ //; s/ $//')

  if [[ -n "${SKILL_TITLES[$norm]:-}" ]]; then
    log_warn "Possible skill duplicate: '$skill_file' ↔ '${SKILL_TITLES[$norm]}'"
    SKILL_DUPES=$((SKILL_DUPES + 1))
    ISSUES=$((ISSUES + 1))
  else
    SKILL_TITLES["$norm"]="$skill_file"
  fi
done < <(find "$PLATFORM_DIR/skills" -name 'SKILL.md' -type f 2>/dev/null)

if [[ $AGENT_DUPES -eq 0 && $SKILL_DUPES -eq 0 ]]; then
  log_success "No semantic duplicates detected (agents: ${#AGENT_TITLES[@]}, skills: ${#SKILL_TITLES[@]})"
fi

# ============================================================================
# 2. Agent THIN Orchestrator Lint
# ============================================================================

log_section "2. Agent THIN Orchestrator Lint"

THICK_AGENTS=0
THIN_AGENTS=0

while IFS= read -r agent_file; do
  [[ "$agent_file" == *CAPABILITY_MATRIX* ]] && continue
  [[ "$agent_file" == *pipeline-flow* ]] && continue
  [[ "$agent_file" == *gate-matrix* ]] && continue

  # Check if agent references skills/ paths (evidence of delegation)
  has_skill_ref=0
  grep -qiE 'skills/|SKILL\.md|Extracted Skills|Delegated Skills|skill_invoke' "$agent_file" 2>/dev/null && has_skill_ref=1

  # Check for large inline procedure (>80 non-blank lines is suspect for an agent)
  line_count=$(wc -l < "$agent_file" 2>/dev/null || echo 0)

  if [[ $has_skill_ref -eq 1 ]]; then
    THIN_AGENTS=$((THIN_AGENTS + 1))
  elif [[ $line_count -gt 80 ]]; then
    THICK_AGENTS=$((THICK_AGENTS + 1))
    log_warn "Thick agent (${line_count} lines, no skill refs): $agent_file"
    ISSUES=$((ISSUES + 1))
  fi
done < <(find "$PLATFORM_DIR/agents" -name '*.md' -type f 2>/dev/null)

log_info "Thin agents (skill-delegating): $THIN_AGENTS"
log_info "Thick agents (embedded logic): $THICK_AGENTS"
if [[ $THICK_AGENTS -eq 0 ]]; then
  log_success "All substantial agents delegate to skills"
fi

# ============================================================================
# 3. Workflow ↔ Stage Dependency Alignment
# ============================================================================

log_section "3. Workflow ↔ Stage Dependency Validation"

STAGE_DEPS_ISSUES=0

for wf_file in "$PLATFORM_DIR"/workflows/*.yml "$PLATFORM_DIR"/workflows/*.yaml; do
  [[ ! -f "$wf_file" ]] && continue
  wf_name="$(basename "$wf_file")"

  # Extract stage names from YAML (lines like "  - name: xxx")
  stage_names=()
  while IFS= read -r line; do
    name=$(echo "$line" | sed -n 's/.*name:[[:space:]]*//p' | tr -d '\r')
    [[ -n "$name" ]] && stage_names+=("$name")
  done < <(grep '^\s*-\?\s*name:' "$wf_file" 2>/dev/null | tail -n +2)

  # For each stage, check if its directory exists
  for sname in "${stage_names[@]}"; do
    found_dir=""
    for d in "$PLATFORM_DIR"/stages/[0-9][0-9]-*; do
      [[ ! -d "$d" ]] && continue
      dir_basename="$(basename "$d")"
      short="${dir_basename#[0-9][0-9]-}"
      if [[ "$short" == "$sname" ]]; then
        found_dir="$d"
        break
      fi
    done
    if [[ -z "$found_dir" ]]; then
      log_warn "$wf_name: stage '$sname' has no matching stages/ directory"
      STAGE_DEPS_ISSUES=$((STAGE_DEPS_ISSUES + 1))
      ISSUES=$((ISSUES + 1))
    fi
  done

  # Check ordering: if a STAGE.md declares requires_stages, verify workflow order
  prev_stages=()
  for sname in "${stage_names[@]}"; do
    found_dir=""
    for d in "$PLATFORM_DIR"/stages/[0-9][0-9]-*; do
      [[ ! -d "$d" ]] && continue
      short="$(basename "$d")"
      short="${short#[0-9][0-9]-}"
      [[ "$short" == "$sname" ]] && found_dir="$d" && break
    done

    if [[ -n "$found_dir" && -f "$found_dir/STAGE.md" ]]; then
      requires=$(grep -i 'requires_stages' "$found_dir/STAGE.md" 2>/dev/null | head -1 || true)
      if [[ -n "$requires" ]]; then
        # Extract required stage names (rough parse of YAML-like list)
        req_names=$(echo "$requires" | grep -oE '[A-Za-z][-A-Za-z]+' | tr '[:upper:]' '[:lower:]' || true)
        for rn in $req_names; do
          [[ "$rn" == "requires" || "$rn" == "stages" ]] && continue
          # Check if required stage appears before this one in workflow
          found_before=0
          for ps in "${prev_stages[@]}"; do
            # Fuzzy match: "grooming" matches "grooming"
            if [[ "$ps" == *"$rn"* || "$rn" == *"$ps"* ]]; then
              found_before=1
              break
            fi
          done
          if [[ $found_before -eq 0 ]]; then
            log_warn "$wf_name: '$sname' requires '$rn' but it does not appear earlier in workflow"
            STAGE_DEPS_ISSUES=$((STAGE_DEPS_ISSUES + 1))
            ISSUES=$((ISSUES + 1))
          fi
        done
      fi
    fi

    prev_stages+=("$sname")
  done
done

if [[ $STAGE_DEPS_ISSUES -eq 0 ]]; then
  log_success "All workflow stage references and dependencies valid"
fi

# ============================================================================
# 4. Symlink Health (.claude/, .cursor/)
# ============================================================================

log_section "4. Symlink Health"

BROKEN_LINKS=0
for dir in "$PLATFORM_DIR/.claude" "$PLATFORM_DIR/.cursor"; do
  [[ ! -d "$dir" ]] && continue
  while IFS= read -r link; do
    if [[ -L "$link" && ! -e "$link" ]]; then
      target=$(readlink "$link" 2>/dev/null || echo "???")
      log_warn "Broken symlink: $link → $target"
      BROKEN_LINKS=$((BROKEN_LINKS + 1))
      ISSUES=$((ISSUES + 1))
    fi
  done < <(find "$dir" -type l 2>/dev/null || true)
done

if [[ $BROKEN_LINKS -eq 0 ]]; then
  log_success "All symlinks valid"
fi

# ============================================================================
# 5. STAGE_BUDGET Consistency
# ============================================================================

log_section "5. STAGE_BUDGET Source Consistency"

BUDGET_FILES=()
while IFS= read -r f; do
  BUDGET_FILES+=("$f")
done < <(grep -rl 'STAGE_BUDGET' "$PLATFORM_DIR/scripts" 2>/dev/null || true)

if [[ ${#BUDGET_FILES[@]} -le 1 ]]; then
  log_success "STAGE_BUDGET defined in ${#BUDGET_FILES[@]} file(s) — no duplication"
else
  log_warn "STAGE_BUDGET defined in ${#BUDGET_FILES[@]} files — risk of divergence:"
  for f in "${BUDGET_FILES[@]}"; do
    log_info "  $f"
  done
  ISSUES=$((ISSUES + 1))
fi

# ============================================================================
# Summary
# ============================================================================

log_section "System Integrity Summary"

if [[ $ISSUES -eq 0 ]]; then
  log_success "All checks passed — system integrity verified"
  exit 0
else
  log_warn "Found $ISSUES issue(s) — review above"
  exit 1
fi
