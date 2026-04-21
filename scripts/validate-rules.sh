#!/usr/bin/env bash
################################################################################
# Rule Bypass Detection Validator (R3)
# Scans canonical agents/ and skills/ (source of truth), not .claude/*/ nested copies.
# Scans for patterns that bypass/ignore/override rules; validates referenced rules exist.
# Warns when an agent definition may lack ask-first-protocol language.
#
# Exit codes: 0 = clean, 1 = violations found
################################################################################

set -eo pipefail

PLATFORM_DIR="${1:-.}"
# Canonical agent markdown lives under agents/ (source of truth). .claude/agents may mirror or nest
# copies that drift; validate-system-integrity.sh also scans agents/.
AGENTS_DIR="${PLATFORM_DIR}/agents"
# Canonical skills/ (source of truth). .claude/skills may nest duplicate trees and slow scans.
SKILLS_DIR="${PLATFORM_DIR}/skills"
RULES_DIR="${PLATFORM_DIR}/.claude/rules"
# Canonical org rules (source of truth); .claude/rules often has IDE subsets + *-ide.md variants
CANONICAL_RULES_DIR="${PLATFORM_DIR}/rules"

# Returns 0 if referenced rule exists on disk (canonical and/or IDE copy)
_rule_file_exists() {
  local name="$1"
  [[ -f "${CANONICAL_RULES_DIR}/${name}.md" ]] && return 0
  [[ -f "${RULES_DIR}/${name}.md" ]] && return 0
  if [[ "$name" == "gate-enforcement" ]]; then
    [[ -f "${RULES_DIR}/gate-enforcement-ide.md" ]] && return 0
  fi
  return 1
}

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
# Initialize counters
# ============================================================================

BYPASS_VIOLATIONS=0
MISSING_RULE_REFS=0
MISSING_ASK_PROTOCOL=0
TOTAL_AGENTS=0
TOTAL_SKILLS=0

# Bypass patterns (shared by agent + skill scans). Single combined grep per file is much faster than N greps.
BYPASS_PATTERNS=(
  "bypass.*gate"
  "ignore.*rule"
  "override.*rule"
  "skip.*check"
  "bypass.*check"
  "skip.*protocol"
  "ignore.*protocol"
)
BYPASS_REGEX=""
for _bp in "${BYPASS_PATTERNS[@]}"; do
  [[ -n "$BYPASS_REGEX" ]] && BYPASS_REGEX+="|"
  BYPASS_REGEX+="$_bp"
done

# ============================================================================
# STEP 1: Check rule files exist
# ============================================================================

log_section "Rule Files Validation"

if [[ ! -d "$RULES_DIR" ]]; then
  log_warn "Rules directory not found: $RULES_DIR"
  RULES_EXIST=0
else
  # Shallow find only — rules are flat; avoids slow traversal if hooks symlink oddly
  rule_count=$(find "$RULES_DIR" -maxdepth 4 -name "*.md" -type f 2>/dev/null | wc -l)
  if [[ $rule_count -gt 0 ]]; then
    log_success "Found $rule_count rule files"
    RULES_EXIST=1
  else
    log_warn "No rule files found in $RULES_DIR"
    RULES_EXIST=0
  fi
fi

# ============================================================================
# STEP 2: Scan agent files for bypass patterns
# ============================================================================

log_section "Agent Files - Bypass Pattern Detection"

if [[ ! -d "$AGENTS_DIR" ]]; then
  log_warn "Agents directory not found: $AGENTS_DIR"
else
  # Bypass patterns: BYPASS_PATTERNS / BYPASS_REGEX at top of script
  agent_files=()
  while IFS= read -r file; do
    agent_files+=("$file")
  done < <(find "$AGENTS_DIR" -name "*.md" -type f)

  TOTAL_AGENTS=${#agent_files[@]}

  for agent_file in "${agent_files[@]}"; do
    agent_name=$(basename "$agent_file" .md)
    # agents/CAPABILITY_MATRIX.md is an index, not an agent definition
    if [[ "$agent_name" == "CAPABILITY_MATRIX" ]]; then
      continue
    fi
    has_violations=0

    # Fast path: one combined grep; only enumerate patterns if something matched
    if grep -qiE "$BYPASS_REGEX" "$agent_file"; then
      for pattern in "${BYPASS_PATTERNS[@]}"; do
        if grep -qi "$pattern" "$agent_file"; then
          if [[ $has_violations -eq 0 ]]; then
            log_warn "Agent: $agent_name"
            has_violations=1
          fi
          echo "  ⚠  Pattern: $pattern"
          BYPASS_VIOLATIONS=$((BYPASS_VIOLATIONS + 1))
        fi
      done
    fi

    # Check if agent references rules (if rules exist)
    if [[ $RULES_EXIST -eq 1 ]]; then
      # Extract rule references (rules/*.md, .claude/rules/*.md, etc.)
      rule_refs=$(grep -oE '(rules/[a-zA-Z0-9_.-]+\.md|\.?/?claude/rules/[a-zA-Z0-9_.-]+\.md)' "$agent_file" 2>/dev/null | sort -u || true)

      if [[ -n "$rule_refs" ]]; then
        while IFS= read -r rule_ref; do
          rule_name=$(basename "$rule_ref" .md)
          if ! _rule_file_exists "$rule_name"; then
            log_warn "Agent: $agent_name references missing rule: $rule_name"
            MISSING_RULE_REFS=$((MISSING_RULE_REFS + 1))
          fi
        done <<< "$rule_refs"
      fi
    fi

    # Check if agent references ask-first / governed behavior (hyphenated titles like ASK-First must match)
    if ! grep -qiE 'ask-first-protocol|ask[- ]?first|ask.*protocol|ask[._]before|ask.*permission|must[[:space:]]+ask|always[[:space:]]+ask' "$agent_file"; then
      # This is a warning, not a violation (some agents may not need it)
      # Only warn if agent performs actions (single grep for action verbs)
      if grep -qiE 'execute|run|perform|action|deploy|delete|modify' "$agent_file"; then
        log_warn "Agent: $agent_name may lack ask-first-protocol reference"
        MISSING_ASK_PROTOCOL=$((MISSING_ASK_PROTOCOL + 1))
      fi
    fi
  done
fi

# ============================================================================
# STEP 3: Scan skill files for bypass patterns
# ============================================================================

log_section "Skill Files - Bypass Pattern Detection"

if [[ ! -d "$SKILLS_DIR" ]]; then
  log_warn "Skills directory not found: $SKILLS_DIR"
else
  skill_files=()
  while IFS= read -r file; do
    skill_files+=("$file")
  done < <(find "$SKILLS_DIR" -name "*.md" -type f)

  TOTAL_SKILLS=${#skill_files[@]}

  for skill_file in "${skill_files[@]}"; do
    skill_name=$(basename "$skill_file" .md)
    has_violations=0

    if grep -qiE "$BYPASS_REGEX" "$skill_file"; then
      for pattern in "${BYPASS_PATTERNS[@]}"; do
        if grep -qi "$pattern" "$skill_file"; then
          if [[ $has_violations -eq 0 ]]; then
            log_warn "Skill: $skill_name"
            has_violations=1
          fi
          echo "  ⚠  Pattern: $pattern"
          BYPASS_VIOLATIONS=$((BYPASS_VIOLATIONS + 1))
        fi
      done
    fi

    # Check if skill references rules
    if [[ $RULES_EXIST -eq 1 ]]; then
      rule_refs=$(grep -oE '(rules/[a-zA-Z0-9_.-]+\.md|\.?/?claude/rules/[a-zA-Z0-9_.-]+\.md)' "$skill_file" 2>/dev/null | sort -u || true)

      if [[ -n "$rule_refs" ]]; then
        while IFS= read -r rule_ref; do
          rule_name=$(basename "$rule_ref" .md)
          if ! _rule_file_exists "$rule_name"; then
            log_warn "Skill: $skill_name references missing rule: $rule_name"
            MISSING_RULE_REFS=$((MISSING_RULE_REFS + 1))
          fi
        done <<< "$rule_refs"
      fi
    fi
  done
fi

# ============================================================================
# STEP 4: Summary Report
# ============================================================================

log_section "Summary"

TOTAL_ISSUES=$((BYPASS_VIOLATIONS + MISSING_RULE_REFS + MISSING_ASK_PROTOCOL))

echo "Agents scanned: $TOTAL_AGENTS"
echo "Skills scanned: $TOTAL_SKILLS"
echo ""

if [[ $BYPASS_VIOLATIONS -gt 0 ]]; then
  log_error "Bypass patterns detected: $BYPASS_VIOLATIONS"
else
  log_success "No bypass patterns detected"
fi

if [[ $MISSING_RULE_REFS -gt 0 ]]; then
  log_warn "Missing rule references: $MISSING_RULE_REFS"
else
  log_success "All rule references exist"
fi

if [[ $MISSING_ASK_PROTOCOL -gt 0 ]]; then
  log_warn "Agents lacking ask-first reference: $MISSING_ASK_PROTOCOL (warning only)"
else
  log_success "Ask-first protocol properly referenced"
fi

echo ""

if [[ $TOTAL_ISSUES -eq 0 ]]; then
  log_success "Rule validation PASSED ✓"
  exit 0
else
  log_warn "Found $TOTAL_ISSUES rule violations or issues"
  exit 1
fi
