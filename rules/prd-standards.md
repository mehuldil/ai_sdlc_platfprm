# PRD Standards (Product Requirements Document)

## Mandatory Sections (10 Required)
Every PRD must contain these 10 sections:

### 1. Problem Statement
- Clear description of the problem being solved
- User pain points and business impact
- Market or operational context

### 2. Goals & Success Metrics
- Quantifiable goals (KPIs)
- How success will be measured
- Target timelines

### 3. Non-Goals
- Explicitly state what is OUT of scope
- Clarify boundaries for this release

### 4. User Stories
- Feature described from user perspective
- "As a [user], I want [capability], so that [benefit]"
- Acceptance criteria for each story

### 5. Acceptance Criteria
- Testable, unambiguous requirements
- Definition of "done" for each story
- Edge cases and error scenarios

### 6. Analytics Events
- Complete JSON schema for each event
- Event naming convention (e.g., `user_signup`)
- Required vs optional properties
- Measurement approach

### 7. NFR Targets
- Latency (P50, P95, P99)
- Availability and error rates
- Throughput requirements
- Memory, CPU, startup time (if applicable)
- Reference `rules/nfr-targets.md` for defaults

### 8. Out of Scope
- Explicitly list what is NOT included
- Future work or backlog items
- Known limitations

### 9. Dependencies
- Internal teams or systems required
- External APIs or integrations
- Platform or infrastructure needs
- Timeline dependencies

### 10. Open Questions
- Unanswered technical decisions
- Clarifications needed from stakeholders
- Risks or assumptions

## Content Requirements
- **Figma link**: Include for any UI/UX designs
- **License status**: Clarify licensing for any third-party content
- **Numeric NFRs**: All performance targets must be concrete numbers
- **Analytics schema**: Include full JSON structure, not just field names

## Document Format
- **Markdown**: Use CommonMark format
- **Language**: English (US)
- **Audience**: Development, QA, Product, and Stakeholders

---
**Last Updated**: 2026-04-11  
**Governed By**: AI-SDLC Platform
