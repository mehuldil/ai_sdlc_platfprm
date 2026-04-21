---
name: qa
description: QA test generation - 5 test categories, E2E templates, bug triage, SIT/PP certification
model: sonnet-4-6
token_budget: {input: 8000, output: 4000}
---

# QA Test Generation Skill

Comprehensive QA testing across 5 categories with automation templates.

## 5 Test Categories

1. **Functional Testing**: Feature behavior vs AC
2. **Integration Testing**: Component interactions
3. **System Testing**: End-to-end flows
4. **Regression Testing**: No breakage on changes
5. **Performance Testing**: Load and stress validation

## Test Generation

- Analyze acceptance criteria
- Design test cases (happy path, edge cases, errors)
- Generate E2E test templates
- Create test data strategy
- Define automation coverage

## E2E Templates

- Appium Java POM pattern
- TestNG test framework
- Data-driven test scenarios
- Result reporting

## Bug Triage

- P0-P3 severity classification
- Root cause categorization
- Impact assessment
- Resolution prioritization

## SIT/PP Certification

- System Integration Testing validation
- Pre-Production testing checklist
- Deployment readiness assessment

## Skill Triggers

Use this skill when:
- Story ready for QA planning
- Test case generation needed
- Bug classification required
- Release testing needed
- Automation coverage planned

## Consolidated QA Agents

The QA skill operates through 6 consolidated agents:

1. **qa-engineer** - Main QA persona and overall testing coordination
2. **analysis-agent** - Requirement validation & risk assessment (merged requirement-analysis + risk-analysis)
3. **test-builder-agent** - Test case design with AI Self-Review & Appium/TestNG automation (merged test-case-design + test-automation)
4. **test-runner-agent** - Test execution, reporting, environment setup & verification (merged test-execution + test-environment)
5. **defect-agent** - Bug triage (P0-P3), root cause classification, defect management & ADO filing (merged bug-triager + defect-management)
6. **qa-ops-agent** - Report analysis, pipeline tracking, ADO sync, Excel generation (merged report-analysis + pipeline-status + retry-ado-sync)

### Capabilities Across Consolidated Agents

- **API Test Design & Execution** - API test case generation from OpenAPI specifications
- **Governance** - APPROVE/REJECT/REFINE gate pattern enforcement
- **Release Sign-Off** - Go/no-go decision and test closure validation
- **Test Case Design Guardrails** - 20 guardrails for test case quality assurance
- **Environment Management** - Device, APK, and Appium environment verification
- **Integration** - JMeter integration for performance testing

## Quality Standards

- All AC covered by tests
- Edge cases and errors tested
- Clear test documentation
- Repeatable test execution
- Proper defect logging
