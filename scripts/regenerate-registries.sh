#!/bin/bash

################################################################################
# Registry Auto-Generation Script
#
# Regenerates all master registries (CAPABILITY_MATRIX, SKILL, COMMANDS_REGISTRY)
# from source files when agents/skills/commands change.
#
# Called by: post-commit hook or manual invocation
# Usage: ./scripts/regenerate-registries.sh [--check|--update|--dry-run]
#
# --check:   Only report what needs updating (exit 0 if all OK, 1 if updates needed)
# --update:  Regenerate all registries in place
# --dry-run: Show what would be changed without modifying files
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MODE="${1:-update}"  # Default: update mode

echo -e "${BLUE}[Registry Regenerator]${NC} Mode: $MODE"
echo ""

UPDATES_NEEDED=0
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ============================================================================
# FUNCTION: Regenerate Agent Capability Matrix
# ============================================================================
_agent_md_lines() {
    local d="$1"
    [[ -d "$d" ]] || return
    find "$d" -name "*.md" -type f 2>/dev/null | sort | while read -r f; do
        echo "- \`$(basename "$f" .md)\`"
    done
}

regenerate_agent_matrix() {
    echo -e "${YELLOW}→${NC} Scanning agents directory..."

    local agent_dir="agents"
    local output_file="agents/CAPABILITY_MATRIX.md"
    local temp_file="${output_file}.tmp.$$"

    _count_tier() {
        local d="$1"
        if [[ ! -d "$d" ]]; then
            echo 0
            return
        fi
        find "$d" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' '
    }

    local tier1_count
    tier1_count=$(_count_tier "$agent_dir/shared")
    local backend_count
    backend_count=$(_count_tier "$agent_dir/backend")
    local frontend_count
    frontend_count=$(_count_tier "$agent_dir/frontend")
    local qa_count
    qa_count=$(_count_tier "$agent_dir/qa")
    local perf_count
    perf_count=$(_count_tier "$agent_dir/performance")
    local product_count
    product_count=$(_count_tier "$agent_dir/product")
    local reports_count
    reports_count=$(_count_tier "$agent_dir/boss")
    if [[ -d "$agent_dir/reports" ]]; then
        local rc_extra
        rc_extra=$(_count_tier "$agent_dir/reports")
        reports_count=$((reports_count + rc_extra))
    fi

    local total=$((tier1_count + backend_count + frontend_count + qa_count + perf_count + product_count + reports_count))

    local list_shared list_backend list_frontend list_qa list_perf list_product list_reports
    list_shared=$(_agent_md_lines "$agent_dir/shared")
    list_backend=$(_agent_md_lines "$agent_dir/backend")
    list_frontend=$(_agent_md_lines "$agent_dir/frontend")
    list_qa=$(_agent_md_lines "$agent_dir/qa")
    list_perf=$(_agent_md_lines "$agent_dir/performance")
    list_product=$(_agent_md_lines "$agent_dir/product")
    list_reports=$(_agent_md_lines "$agent_dir/boss")
    if [[ -d "$agent_dir/reports" ]]; then
        list_reports="${list_reports}"$'\n'"$(_agent_md_lines "$agent_dir/reports")"
    fi

    cat > "$temp_file" << EOF
# Agent Capability Matrix

**Last Generated**: $TIMESTAMP
**Total Agents**: $total

**Authoritative manifest:** [agent-registry.json](agent-registry.json) — tiers, tags, token budgets, and tool wiring.

## SDLC authoring (all agents)

Outputs that touch **PRD, system design, Master/Sprint/Tech/Task stories, or ADO** must follow **[AUTHORING_STANDARDS.md](../templates/AUTHORING_STANDARDS.md)** — ADO-ready PRD lift (copy/notifications), traceability chain, no invented scope, non-redundancy, and **Tech Story** non-regression when applicable.

Individual agent files include a short **SDLC authoring** line pointing to this standard (search for AUTHORING_STANDARDS under the agents/ tree).

## By Tier

| Tier | Domain | Count | Purpose |
|------|--------|-------|---------|
| **Tier 1** | Shared (Universal) | $tier1_count | Core system agents used by all roles |
| **Tier 2** | Backend | $backend_count | Backend-specific agents |
| **Tier 2** | Frontend | $frontend_count | Mobile/web/design/dev agents |
| **Tier 2** | QA | $qa_count | Requirements through test execution |
| **Tier 2** | Performance | $perf_count | Performance analysis and reporting |
| **Tier 2** | Product | $product_count | Product management |
| **Tier 3** | Reports / Executive | $reports_count | Cross-cutting reports and release |

**Total Agents**: $total

---

## Agent Inventory (from filesystem)

### Tier 1: \`agents/shared/\`

$list_shared

### Tier 2: \`agents/backend/\`

$list_backend

### Tier 2: \`agents/frontend/\`

$list_frontend

### Tier 2: \`agents/qa/\`

$list_qa

### Tier 2: \`agents/performance/\`

$list_perf

### Tier 2: \`agents/product/\`

$list_product

### Tier 3: \`agents/boss/\` (and \`agents/reports/\` if present)

$list_reports

---

## Agent Discovery

\`\`\`bash
ls agents/{shared,backend,frontend,qa,performance,product,boss}/
grep -r "description" agents/ --include="*.md"
\`\`\`

---

**Generated**: $TIMESTAMP
**Command**: regenerate-registries.sh --update
EOF

    if [ "$MODE" = "check" ]; then
        if ! diff -q "$temp_file" "$output_file" >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠${NC} agents/CAPABILITY_MATRIX.md needs regeneration"
            UPDATES_NEEDED=$((UPDATES_NEEDED + 1))
        else
            echo -e "${GREEN}✓${NC} agents/CAPABILITY_MATRIX.md is current"
        fi
        rm -f "$temp_file"
    elif [ "$MODE" = "dry-run" ]; then
        echo -e "${BLUE}→${NC} Would update agents/CAPABILITY_MATRIX.md"
        diff -u "$output_file" "$temp_file" 2>/dev/null | head -40 || true
        rm -f "$temp_file"
    else
        mv "$temp_file" "$output_file"
        echo -e "${GREEN}✓${NC} Regenerated agents/CAPABILITY_MATRIX.md ($total agents)"
    fi
}

# ============================================================================
# FUNCTION: Regenerate Skill Registry
# ============================================================================
regenerate_skill_registry() {
    echo -e "${YELLOW}→${NC} Scanning skills directory..."

    local skills_dir="skills"
    local output_file="skills/SKILL.md"
    local temp_file="${output_file}.tmp.$$"

    # All SKILL.md under tree except top-level registry (skills/SKILL.md)
    local skill_count
    skill_count=$(find "$skills_dir" -name "SKILL.md" -type f ! -path "$skills_dir/SKILL.md" 2>/dev/null | wc -l | tr -d ' ' || echo 0)

    cat > "$temp_file" << EOF
# Skills Registry

**Last Generated**: $TIMESTAMP
**Total Skills**: $skill_count

## Skill Categories

### RPI Workflow (Research → Plan → Implement → Verify)
- rpi-research.md - Research and requirements analysis
- rpi-plan.md - Planning and design
- rpi-implement.md - Implementation execution
- rpi-verify.md - Verification and testing

### Role-Based Skills
- backend/ - Backend development skills
- frontend/ - Frontend development skills
- qa/ - QA and testing skills
- product/ - Product management skills
- performance/ - Performance optimization skills
- shared/ - Universal skills used across roles

### Specialized Skills
- qa-orchestrator.md - QA test orchestration
- performance/ptlc.md - Performance test lifecycle
- contract-generator.md - API contract generation
- story-generator.md - User story generation

**Total Skills**: $skill_count

---

## Skill Discovery

Find skills by name or category:
\`\`\`bash
# List all skills
ls -la skills/*.md | grep -v SKILL.md

# Find skills by pattern
grep -r "skill_name" skills/ --include="*.md"
\`\`\`

---

**Generated**: $TIMESTAMP
**Command**: regenerate-registries.sh --update
EOF

    if [ "$MODE" = "check" ]; then
        if ! diff -q "$temp_file" "$output_file" >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠${NC} skills/SKILL.md needs regeneration"
            UPDATES_NEEDED=$((UPDATES_NEEDED + 1))
        else
            echo -e "${GREEN}✓${NC} skills/SKILL.md is current"
        fi
        rm -f "$temp_file"
    elif [ "$MODE" = "dry-run" ]; then
        echo -e "${BLUE}→${NC} Would update skills/SKILL.md"
        rm -f "$temp_file"
    else
        mv "$temp_file" "$output_file"
        echo -e "${GREEN}✓${NC} Regenerated skills/SKILL.md ($skill_count skills)"
    fi
}

# ============================================================================
# FUNCTION: Regenerate Commands Registry
# ============================================================================
regenerate_commands_registry() {
    echo -e "${YELLOW}→${NC} Scanning commands directory..."

    local commands_dir=".claude/commands"
    local output_file="$commands_dir/COMMANDS_REGISTRY.md"
    local temp_file="${output_file}.tmp.$$"

    mkdir -p "$commands_dir"

    local command_count=$(find "$commands_dir" -name "*.md" -type f ! -name "COMMANDS_REGISTRY.md" 2>/dev/null | wc -l | tr -d ' ' || echo 0)

    cat > "$temp_file" << EOF
# Commands Registry

**Last Generated**: $TIMESTAMP
**Total Commands**: $command_count

## SDLC Pipeline Commands
- /requirement-intake - Start requirement intake phase
- /grooming - Run grooming session
- /implementation - Start implementation phase
- /code-review - Code review process
- /testing - Test design and execution
- /deployment - Deployment planning
- /release - Release management

## RPI Workflow Commands
- /rpi - Research → Plan → Implement → Verify
- /rpi-research - Start research phase
- /rpi-plan - Start planning phase
- /rpi-implement - Start implementation phase
- /rpi-verify - Start verification phase

## Operational Commands
- /status - Show system status
- /sync - Sync state with ADO
- /health - Health check
- /memory - Show memory state
- /metrics - Show pipeline metrics

## Integration Commands
- /ado - Azure DevOps operations
- /git - Git operations
- /ci - CI/CD status

**Total Commands**: $command_count

---

## Command Discovery

\`\`\`bash
# List all commands
ls .claude/commands/*.md | grep -v COMMANDS_REGISTRY

# Find command by name
grep -r "command_name" .claude/commands/ --include="*.md"
\`\`\`

---

**Generated**: $TIMESTAMP
**Command**: regenerate-registries.sh --update
EOF

    if [ "$MODE" = "check" ]; then
        if ! diff -q "$temp_file" "$output_file" >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠${NC} .claude/commands/COMMANDS_REGISTRY.md needs regeneration"
            UPDATES_NEEDED=$((UPDATES_NEEDED + 1))
        else
            echo -e "${GREEN}✓${NC} .claude/commands/COMMANDS_REGISTRY.md is current"
        fi
        rm -f "$temp_file"
    elif [ "$MODE" = "dry-run" ]; then
        echo -e "${BLUE}→${NC} Would update .claude/commands/COMMANDS_REGISTRY.md"
        rm -f "$temp_file"
    else
        mv "$temp_file" "$output_file"
        echo -e "${GREEN}✓${NC} Regenerated .claude/commands/COMMANDS_REGISTRY.md ($command_count commands)"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
echo -e "${BLUE}[Registry Regenerator]${NC} Starting scan..."
echo ""

regenerate_agent_matrix
echo ""
regenerate_skill_registry
echo ""
regenerate_commands_registry

echo ""
echo -e "${BLUE}[Registry Regenerator]${NC} Summary:"

if [ "$MODE" = "check" ]; then
    if [ $UPDATES_NEEDED -eq 0 ]; then
        echo -e "${GREEN}✓${NC} All registries are current"
        exit 0
    else
        echo -e "${RED}✗${NC} $UPDATES_NEEDED registry/registries need regeneration"
        echo ""
        echo "To regenerate: ./scripts/regenerate-registries.sh --update"
        exit 1
    fi
elif [ "$MODE" = "dry-run" ]; then
    echo -e "${BLUE}→${NC} Dry-run completed. No files modified."
    exit 0
else
    echo -e "${GREEN}✓${NC} All registries regenerated"
    exit 0
fi
