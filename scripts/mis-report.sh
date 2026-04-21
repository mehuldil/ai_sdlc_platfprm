#!/usr/bin/env bash
# Module Intelligence System (MIS) — Impact Report Generator
# Generates comprehensive impact report for changes
set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_section() { echo -e "\n${MAGENTA}========== $* ==========${NC}\n"; }

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

if [[ ! -d "$REPO_PATH/.git" ]]; then
  log_error "Not a git repository: $REPO_PATH"
  exit 1
fi

CONTRACT_DIR="$REPO_PATH/.sdlc/module-contracts"
if [[ ! -d "$CONTRACT_DIR" ]]; then
  log_error "No module contracts found. Run: sdlc mis init $REPO_PATH"
  exit 1
fi

MODULE_NAME=$(basename "$REPO_PATH")
REPORT_FILE="$CONTRACT_DIR/impact-reports/$(date +%Y%m%d-%H%M%S)-impact-report.md"
mkdir -p "$CONTRACT_DIR/impact-reports"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log_section "MIS Impact Report Generator: $MODULE_NAME"

# ============================================================================
# COLLECT CHANGE DATA
# ============================================================================

collect_changes() {
  cd "$REPO_PATH"

  local base_branch=$(git rev-parse --abbrev-ref HEAD | grep -v HEAD || echo "main")
  local current_branch=$(git rev-parse --abbrev-ref HEAD)

  # Get file changes
  local files=$(git diff --name-only "$base_branch"..."$current_branch" 2>/dev/null || echo "")

  # Count by type
  local java_files=$(echo "$files" | grep -c "\.java$" || echo "0")
  local sql_files=$(echo "$files" | grep -c "\.sql$" || echo "0")
  local config_files=$(echo "$files" | grep -c "\.yml\|\.yaml\|\.properties$" || echo "0")
  local test_files=$(echo "$files" | grep -c "Test\.java\|\.test\.js\|\.spec\.ts$" || echo "0")

  # Get commits
  local commits=$(git log "$base_branch"..."$current_branch" --oneline 2>/dev/null | head -20 || echo "")
  local commit_count=$(echo "$commits" | wc -l)

  # Get additions/deletions
  local stats=$(git diff --stat "$base_branch"..."$current_branch" 2>/dev/null | tail -1 || echo "")
  local insertions=$(echo "$stats" | grep -oE "[0-9]+ insertion" | grep -oE "[0-9]+" || echo "0")
  local deletions=$(echo "$stats" | grep -oE "[0-9]+ deletion" | grep -oE "[0-9]+" || echo "0")
}

# ============================================================================
# GENERATE MARKDOWN REPORT
# ============================================================================

generate_markdown_report() {
  log_info "Generating impact report..."

  collect_changes

  cat > "$REPORT_FILE" << EOF
# Impact Report: $MODULE_NAME

**Generated:** $TIMESTAMP
**Module:** $MODULE_NAME
**Repository:** $REPO_PATH

---

## 1. Change Summary

### File Changes
- **Java files modified:** $java_files
- **SQL migrations added:** $sql_files
- **Configuration changes:** $config_files
- **Test files modified:** $test_files
- **Total commits:** $commit_count
- **Code changes:** +$insertions lines, -$deletions lines

### Recent Commits
\`\`\`
$commits
\`\`\`

---

## 2. API Impact Analysis

### Endpoints Modified
Check \`.sdlc/module-contracts/api-contract.yaml\` for:
- New endpoints added
- Endpoints removed or renamed
- Request/response schema changes
- Status code modifications

### Recommendations
- [ ] Document new endpoints in API contract
- [ ] Identify breaking changes
- [ ] Notify consuming services:
  - mobile-app
  - web-app
  - admin-panel
  - any other API clients
- [ ] Update API documentation
- [ ] Add migration guide if breaking

---

## 3. Database Impact Analysis

### Schema Changes
Check \`.sdlc/module-contracts/data-contract.yaml\` for:
- New tables created
- Table schema modifications
- Column additions/removals
- Index or constraint changes

### Migration Safety
- [ ] Test forward migration
- [ ] Test rollback capability
- [ ] Verify downtime requirements
- [ ] Check for data type conversions
- [ ] Validate constraints on existing data

### Commands to Test Rollback
\`\`\`bash
# Maven with Liquibase
./mvnw liquibase:rollback -Dliquibase.rollback.count=1

# Direct SQL rollback
psql -d dbname -f db/migrations/rollback.sql

# Using migration framework
./gradlew flywayUndo
\`\`\`

### Recommendations
- [ ] Document migration plan
- [ ] Verify rollback tested
- [ ] Schedule downtime if needed
- [ ] Backup database before deployment
- [ ] Update database documentation

---

## 4. Event/Kafka Impact Analysis

### Event Schema Changes
Check \`.sdlc/module-contracts/event-contract.yaml\` for:
- New event topics
- Event schema modifications
- Breaking changes to existing events
- Topic configuration changes

### Affected Services
- **Producing changes:** Impact downstream consumers
- **Consuming changes:** May require updates to event handlers
- **Topic changes:** May require consumer group rebalancing

### Recommendations
- [ ] Document event schema changes
- [ ] Identify affected consumer services
- [ ] Notify consumer teams
- [ ] Test event serialization/deserialization
- [ ] Update event documentation

---

## 5. Dependency Impact Analysis

### Library Changes
Check \`.sdlc/module-contracts/dependencies.yaml\` for:
- New dependencies added
- Dependency version updates
- Security patches
- Breaking changes in dependencies

### Service Dependencies
- [ ] Verify external service compatibility
- [ ] Check SLA requirements
- [ ] Test failure scenarios
- [ ] Update timeout configurations

### Recommendations
- [ ] Review security advisories for new libraries
- [ ] Test compatibility with existing services
- [ ] Update documentation
- [ ] Review license compliance

---

## 6. Breaking Changes Summary

### Detected Breaking Changes
Run the following to analyze:
\`\`\`bash
sdlc mis analyze-change
\`\`\`

Current breaking changes: Check \`last-change-analysis.json\`

### Approval Workflow
1. **Identify:** Mark as breaking change
2. **Document:** Add to breaking-changes.md
3. **Create ADO:** Link issue (AB#XXXXX)
4. **Notify:** Contact all affected services
5. **Set deadline:** Usually 6 months
6. **Approve:** Get stakeholder sign-off
7. **Merge:** Only after approval

### Migration Guides
Create migration guides for:
- [ ] API consumers (docs/migration/v2.0-api.md)
- [ ] Database changes (docs/migration/v2.0-schema.md)
- [ ] Event consumers (docs/migration/v2.0-events.md)

---

## 7. Cross-Service Impact

### Services That May Be Affected

**If API changed:**
- mobile-app (iOS/Android clients)
- web-app (Frontend consumers)
- admin-panel
- Any service using @FeignClient

**If database schema changed:**
- Read replicas
- Data warehouse/analytics
- Backup/restore procedures
- ORM mappings in other services

**If events changed:**
- notification-service
- analytics-service
- audit-service
- Any @KafkaListener services

### Coordination Checklist
- [ ] Identify all affected services
- [ ] Create cross-service issue (Epic in ADO)
- [ ] Schedule sync meeting with teams
- [ ] Coordinate deployment order
- [ ] Test integration points
- [ ] Plan rollback procedure

---

## 8. Rollback Plan

### Rollback Triggers
Rollback if:
- Critical bugs discovered in production
- Performance degradation
- Data corruption
- Security vulnerability
- Integration failures with dependent services

### Rollback Steps

**1. Revert code changes**
\`\`\`bash
git revert -n <commit-hash>
git commit -m "Revert: [reason]"
\`\`\`

**2. Rollback database schema (if applicable)**
\`\`\`bash
./mvnw liquibase:rollback -Dliquibase.rollback.count=1
\`\`\`

**3. Clear Kafka topics (if applicable)**
\`\`\`bash
kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic topic-name
\`\`\`

**4. Notify dependent services**
- Post in incident channel
- Contact service owners
- Provide status updates

---

## 9. Testing Checklist

### Unit Tests
- [ ] All unit tests pass
- [ ] New code has test coverage
- [ ] Edge cases tested

### Integration Tests
- [ ] Database migrations work
- [ ] Event schemas validate
- [ ] External service calls work
- [ ] Cross-service APIs compatible

### End-to-End Tests
- [ ] Full workflow tested
- [ ] API contracts verified
- [ ] Data integrity checked
- [ ] Event flow tested

### Performance Tests
- [ ] Database queries optimized
- [ ] API response times acceptable
- [ ] No memory leaks
- [ ] Load test passed

---

## 10. Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] ADO issues linked
- [ ] Documentation updated
- [ ] Stakeholders notified
- [ ] Rollback plan ready
- [ ] Database backup created (if schema changed)

### Deployment
- [ ] Feature flags configured (if applicable)
- [ ] Gradual rollout plan ready
- [ ] Monitoring alerts configured
- [ ] On-call engineer notified

### Post-Deployment
- [ ] Health checks passing
- [ ] Error rates normal
- [ ] Performance metrics normal
- [ ] User feedback collected
- [ ] Data consistency verified

---

## 11. Risk Assessment

### Overall Risk Score
Based on analysis: See \`last-change-analysis.json\`

### Risk Factors
- [ ] Breaking changes present
- [ ] Database migrations required
- [ ] Event schema changes
- [ ] Cross-service dependencies
- [ ] New external services

### Mitigations
- [ ] Detailed testing completed
- [ ] Rollback plan ready
- [ ] Monitoring configured
- [ ] Stakeholders notified
- [ ] Phased rollout available

---

## 12. Sign-Off

### Required Approvals
- [ ] Code review approved
- [ ] QA testing completed
- [ ] Database admin approval (if schema changes)
- [ ] Service owner approval
- [ ] Release manager approval (if breaking changes)

### Sign-Off Checklist
- [ ] All recommendations addressed
- [ ] Impact understood by team
- [ ] Deployment plan finalized
- [ ] Rollback plan tested
- [ ] Ready to deploy

---

## Resources

- **Module Contracts:** \`.sdlc/module-contracts/\`
- **Change Analysis:** \`.sdlc/module-contracts/last-change-analysis.json\`
- **Validation Report:** \`.sdlc/module-contracts/validation-report.json\`
- **Breaking Changes:** \`.sdlc/module-contracts/breaking-changes.md\`

## Commands

\`\`\`bash
# Analyze changes
sdlc mis analyze-change

# Validate before merge
sdlc mis validate

# Generate this report
sdlc mis report

# Show contracts
sdlc mis show api
sdlc mis show data
sdlc mis show events
\`\`\`

---

**Generated by:** AI SDLC Platform v2.0 — Module Intelligence System v1.0
**Report file:** $REPORT_FILE
EOF

  log_success "Impact report generated"
}

# ============================================================================
# GENERATE SUMMARY OUTPUT
# ============================================================================

output_summary() {
  log_section "IMPACT REPORT SUMMARY"

  echo "Report generated: $REPORT_FILE"
  echo ""
  echo "Key areas to review:"
  echo "  1. API Changes — May affect consuming services"
  echo "  2. Database Changes — Test rollback capability"
  echo "  3. Event Changes — Notify kafka consumers"
  echo "  4. Breaking Changes — Require approval and migration plans"
  echo "  5. Rollback Plan — Tested and documented"
  echo ""
  echo "Next steps:"
  echo "  1. Review the impact report"
  echo "  2. Run validation: sdlc mis validate"
  echo "  3. Get approvals from stakeholders"
  echo "  4. Coordinate with affected services"
  echo "  5. Deploy with confidence!"
  echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

generate_markdown_report
output_summary

log_success "Report saved to: $REPORT_FILE"
