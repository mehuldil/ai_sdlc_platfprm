#!/bin/bash
# Auto-validators for slash command outputs

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Validator: Story Completeness
validate_story() {
    local story_file=$1
    local errors=0
    
    echo -e "${YELLOW}Validating story: $story_file${NC}"
    
    # Check required sections
    required_sections=("Title" "Acceptance Criteria" "Story Points" "Tech Tasks")
    for section in "${required_sections[@]}"; do
        if ! grep -q "## $section" "$story_file"; then
            echo -e "${RED}✗ Missing section: $section${NC}"
            errors=$((errors + 1))
        fi
    done
    
    # Check AC count (minimum 3)
    ac_count=$(grep -c "^- \[ \]" "$story_file" || echo 0)
    if [ $ac_count -lt 3 ]; then
        echo -e "${YELLOW}⚠ AC count low: $ac_count (recommended: >=3)${NC}"
    else
        echo -e "${GREEN}✓ AC count adequate: $ac_count${NC}"
    fi
    
    # Check estimation
    if grep -q "Story Points:" "$story_file"; then
        sp=$(grep "Story Points:" "$story_file" | grep -oE "[0-9]+")
        if [ -z "$sp" ] || [ "$sp" -lt 1 ] || [ "$sp" -gt 21 ]; then
            echo -e "${RED}✗ Invalid story points: $sp (must be 1-21 Fibonacci)${NC}"
            errors=$((errors + 1))
        else
            echo -e "${GREEN}✓ Story points valid: $sp${NC}"
        fi
    else
        echo -e "${RED}✗ Missing Story Points${NC}"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Validator: Design Document
validate_design() {
    local design_file=$1
    local errors=0
    
    echo -e "${YELLOW}Validating design: $design_file${NC}"
    
    # Check 7 design sections
    required_sections=("Overview" "Data Model" "API Contracts" "Integration" "Performance" "Deployment" "Rollback")
    for section in "${required_sections[@]}"; do
        if ! grep -q "## $section" "$design_file"; then
            echo -e "${RED}✗ Missing section: $section${NC}"
            errors=$((errors + 1))
        fi
    done
    
    # Check for DDL/SQL if database mentioned
    if grep -q -i "database\|sql\|table" "$design_file"; then
        if ! grep -q '```sql' "$design_file"; then
            echo -e "${YELLOW}⚠ Missing SQL schema${NC}"
        else
            echo -e "${GREEN}✓ SQL schema present${NC}"
        fi
    fi
    
    # Check for API contract (OpenAPI)
    if ! grep -q "openapi\|/api/" "$design_file"; then
        echo -e "${YELLOW}⚠ Missing API contract${NC}"
    else
        echo -e "${GREEN}✓ API contract present${NC}"
    fi
    
    return $errors
}

# Validator: Test Plan
validate_test_plan() {
    local test_file=$1
    local errors=0
    
    echo -e "${YELLOW}Validating test plan: $test_file${NC}"
    
    # Check for test matrix
    if ! grep -q "Test Type\|Scenario" "$test_file"; then
        echo -e "${RED}✗ Missing test matrix${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Test matrix present${NC}"
    fi
    
    # Check for Gherkin
    if ! grep -q "Feature:\|Scenario:\|Given\|When\|Then" "$test_file"; then
        echo -e "${YELLOW}⚠ Missing Gherkin scenarios${NC}"
    else
        echo -e "${GREEN}✓ Gherkin scenarios present${NC}"
    fi
    
    # Check coverage target
    if ! grep -q "coverage\|coverage target" "$test_file"; then
        echo -e "${YELLOW}⚠ Missing coverage target${NC}"
    else
        echo -e "${GREEN}✓ Coverage target defined${NC}"
    fi
    
    # Check effort estimation
    if ! grep -q "Effort\|SP\|points" "$test_file"; then
        echo -e "${YELLOW}⚠ Missing effort estimate${NC}"
    else
        echo -e "${GREEN}✓ Effort estimated${NC}"
    fi
    
    return $errors
}

# Validator: Release Readiness
validate_release() {
    local release_file=$1
    local errors=0
    
    echo -e "${YELLOW}Validating release: $release_file${NC}"
    
    # Check all gates
    gates=("G1\|PRD" "G2\|Grooming" "G3\|Grooming" "G4\|Tech Design" "G5\|Sprint" "G6\|Dev" "G7\|SIT" "G8\|PP" "G9\|Perf" "G10\|Release")
    for gate in "${gates[@]}"; do
        if ! grep -q "$gate" "$release_file"; then
            echo -e "${YELLOW}⚠ Missing gate check: $gate${NC}"
        fi
    done
    
    # Check compliance scans
    compliance_scans=("SAST" "DAST" "SCA" "Coverage" "Container")
    for scan in "${compliance_scans[@]}"; do
        if ! grep -q -i "$scan" "$release_file"; then
            echo -e "${YELLOW}⚠ Missing compliance: $scan${NC}"
        fi
    done
    
    # Check go/no-go decision
    if grep -q "✅ GO" "$release_file"; then
        echo -e "${GREEN}✓ Release approved (GO)${NC}"
    elif grep -q "❌ NO-GO" "$release_file"; then
        echo -e "${RED}✗ Release blocked (NO-GO)${NC}"
        errors=$((errors + 1))
    else
        echo -e "${YELLOW}⚠ Release decision not documented${NC}"
    fi
    
    return $errors
}

# Validator: Gate Completeness
validate_gates() {
    local ado_id=$1
    local stage=$2
    local errors=0
    
    echo -e "${YELLOW}Validating gates for $ado_id (stage $stage)${NC}"
    
    # Check for gate acknowledgment
    if [ ! -f ".sdlc/state.json" ]; then
        echo -e "${YELLOW}⚠ No state file found${NC}"
        return 0
    fi
    
    # Query state file for gate acks
    gate_acks=$(grep -c "gate_ack" ".sdlc/state.json" 2>/dev/null || echo 0)
    if [ $gate_acks -eq 0 ]; then
        echo -e "${YELLOW}⚠ No gate acknowledgments recorded${NC}"
    else
        echo -e "${GREEN}✓ Gate acknowledgments: $gate_acks${NC}"
    fi
    
    return $errors
}

# Main validation runner
validate_all() {
    local errors=0
    
    echo -e "${YELLOW}=== AI-SDLC Validator Suite ===${NC}\n"
    
    # Validate all stories
    echo -e "${YELLOW}--- Stories ---${NC}"
    for story in .sdlc/memory/projects/*/stories.md; do
        if [ -f "$story" ]; then
            validate_story "$story"
            ((errors += $?))
        fi
    done
    
    # Validate all designs
    echo -e "\n${YELLOW}--- Designs ---${NC}"
    for design in .sdlc/memory/projects/*/design.md; do
        if [ -f "$design" ]; then
            validate_design "$design"
            ((errors += $?))
        fi
    done
    
    # Validate all test plans
    echo -e "\n${YELLOW}--- Test Plans ---${NC}"
    for test in .sdlc/memory/projects/*/test-design.md; do
        if [ -f "$test" ]; then
            validate_test_plan "$test"
            ((errors += $?))
        fi
    done
    
    # Validate all releases
    echo -e "\n${YELLOW}--- Releases ---${NC}"
    for release in .sdlc/memory/projects/*/release.md; do
        if [ -f "$release" ]; then
            validate_release "$release"
            ((errors += $?))
        fi
    done
    
    # Final summary
    echo -e "\n${YELLOW}=== Validation Summary ===${NC}"
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ All validations passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Found $errors validation errors${NC}"
        return 1
    fi
}

# Run validators
validate_all
