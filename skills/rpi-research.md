# RPI Research — Scope Isolation

**Model:** Claude 3.5 Sonnet | **Trigger:** `sdlc rpi research <story-id>` or `/project:rpi-research AB#<id>`

---

## What It Does

This skill executes Phase 1 of the RPI workflow: scope isolation and risk analysis. It reads the codebase and documentation to build a comprehensive understanding of what needs to be done, WITHOUT making any changes.

1. Fetch ADO work item (title, description, AC, tags, comments)
2. Search codebase for relevant files (max 10 files, max 2K chars per file extract)
3. Search Wiki.js for architecture docs, API contracts, known constraints
4. Identify risks: edge cases, breaking changes, cross-service dependencies
5. Output `.sdlc/rpi/{story-id}/research.md` and STOP for human review

---

## Execution Steps

### Step 1: Fetch ADO Work Item

```bash
# Get work item details
mcp__AzureDevOps__get_work_item <story-id>
```

Extract:
- Title: {story-title}
- Description: {narrative}
- Acceptance Criteria: {list}
- Tags: {all tags}
- Comments: {extended discussion from thread}
- Type: Feature / Bug / Refactor / Task

### Step 2: Identify Relevant Files

Search codebase for files related to story:
- **MUST cite concrete repo paths** in the output (not only component names). When `.sdlc/module/` exists, cross-check `.sdlc/module/contracts/*.yaml` and `.sdlc/module/knowledge/*.md` for APIs, data shapes, and known issues.
- **Locate existing tests** near the change (`*Test*`, `__tests__`, `spec.ts`, etc.) and note which scenarios they already cover—this informs regression risk for Plan/Implement.
- Use keywords from title, description, AC
- Identify max 10 files to review
- For each file:
  - Full path
  - Current line count
  - Brief purpose (read first 100 lines)
  - Extract max 2K characters of actual code

**Codebase search strategy:**
```
# Read .sdlc/route to determine stack
ROUTE="$(cat .sdlc/route 2>/dev/null || echo 'NEW_FEATURE')"

# For backend tasks
find . -name "*.java" -o -name "*.kt" | xargs grep -l "{keyword}" | head -10

# For frontend tasks
find . -name "*.tsx" -o -name "*.ts" | xargs grep -l "{keyword}" | head -10

# For database tasks
find . -name "*.sql" -o -name "*migration*" | xargs grep -l "{keyword}" | head -10
```

Limit results to max 10 files. Extract code up to 2K characters per file.

### Step 3: Wiki.js Lookup

Search Wiki.js for related documentation:

```
# Architecture docs
wiki_search("architecture", "diagram", "service", "{service-name}")

# API contracts
wiki_search("openapi", "api", "contract", "endpoint")

# Known constraints
wiki_search("constraint", "limitation", "deprecated", "error-handling")

# Patterns
wiki_search("pattern", "convention", "best-practice", "{domain}")
```

For each relevant doc found:
- Page title and URL
- Relevant section (with line numbers if possible)
- How it impacts this story

**Max search results:** 5 wiki documents

### Step 4: Risk Identification

For each file and cross-service interaction:
1. **Edge cases**: What happens if {field} is null, empty, negative, etc.?
2. **Breaking changes**: Does this change affect other services/APIs?
3. **Data migration**: Does this require schema changes? Rollback strategy?
4. **Performance**: Could this cause N+1 queries, cache misses, timeouts?
5. **Security**: Does this introduce auth/validation gaps?

Document each risk with:
- Description: What could go wrong?
- Mitigation: How to prevent/handle it

### Step 5: Estimate Token Budget

Forecast tokens needed for Plan + Implement phases based on:
- File count (max 10)
- Lines of change (estimated from AC)
- Test complexity
- Team dependencies

**Formula:**
```
tokens_for_plan = (files * 500) + (complexity_factor * 1000)
tokens_for_implement = (tokens_for_plan * 1.5) + (test_cost * 500)
total = tokens_for_plan + tokens_for_implement + 2000 (verify margin)
```

---

## Output Format

Create `.sdlc/rpi/{story-id}/research.md`:

```markdown
# Research Summary: {story-title}

## Story Context
- **ID**: {story-id}
- **Type**: Feature / Bug / Refactor / Task
- **Route**: NEW_FEATURE / BUG_FIX / CONFIG_CHANGE / etc.
- **Scope**: {1-2 sentence scope statement}
- **Acceptance Criteria**: 
  - AC-01: {first AC}
  - AC-02: {second AC}
  - ...

## Problem Statement
{From work item description}

## Relevant Codebase Context

### Files to Modify (Max 10)
- **{path/to/file1.java}** (L45-120, 200 lines total)
  - Current: {Brief description of current implementation}
  - Key sections: {List important methods/classes}
  - Extract:
    ```
    {max 500 chars of current code relevant to change}
    ```
  - Impact: {Why this file needs to change}

- **{path/to/file2.kt}** (L10-95, 150 lines total)
  - ...

### Key Patterns & Conventions Found
- {Framework pattern}: {How it's used in codebase}
- {Naming convention}: {Examples from codebase}
- {Architecture pattern}: {How implemented}

## Wiki.js Context

### Architecture Documents
- **{Wiki page title}**: {Link if possible}
  - Relevant section: {Summary of what's relevant}
  - Impact on story: {How this constrains or enables the work}

### API & Service Contracts
- **{API name}**: {OpenAPI version or format}
  - Endpoint: {POST /endpoint}
  - Relevant schema: {Field names}
  - Breaking change risk: {Yes/No + rationale}

### Known Constraints
- {Constraint}: {Explanation}
- {Limitation}: {Explanation}

## Dependencies & Cross-Team Impact

### Internal Dependencies
- **Service A**: {What dependency exists, what's the impact}
- **Database**: {Schema dependencies, migration needs}
- **Cache layer**: {Cache key patterns, invalidation strategy}

### External Dependencies
- **{Service}**: {Version, SLA, failure mode}
- **{API}**: {Rate limits, auth requirements}

### Affected Teams
- **Backend team**: {What they need to do or provide}
- **Frontend team**: {UI changes or contract consumption}
- **DevOps team**: {Deployment, scaling considerations}
- **QA team**: {Test scenarios, environments}

## Risk Assessment

### Edge Cases & Error Scenarios
| Scenario | Description | Current Handling | Mitigation |
|----------|-------------|-----------------|-----------|
| Null user object | What if user object is null? | {Current} | Add null check at line 45 |
| Missing field | What if optional field is missing? | {Current} | Default to empty string |
| Timeout | What if service call times out? | {Current} | Add retry with exponential backoff |
| Invalid state | What if system is in unexpected state? | {Current} | Log error and skip operation |

### Breaking Changes
- **{Change 1}**: {What breaks, which services affected, migration path}
- **{Change 2}**: {Impact analysis}

### Performance Implications
- **N+1 queries**: {If applicable, current vs fixed}
- **Cache impact**: {Cache invalidation costs}
- **Memory usage**: {Estimated increase/decrease}

## ADO Comments & Extended Discussion
{Summary of any key discussion in work item comments thread}

**Example**: Stakeholder noted that feature X must support mobile-first approach, should be reflected in AC.

## Token Budget Forecast

Based on file count, complexity, and test requirements:

| Phase | Model | Estimated Input | Estimated Output | Total |
|-------|-------|---|---|---|
| **Plan** (Phase 2) | Opus | 1,000 | 2,500 | 3,500 |
| **Implement** (Phase 3) | Sonnet | 1,500 | 3,000 | 4,500 |
| **Verify** (Phase 4) | Sonnet | 800 | 1,000 | 1,800 |
| **TOTAL** | | | | ~10K |

**Notes**: {Any assumptions about complexity, dependencies, or potential overages}

## Recommended Approach
{1-2 sentence recommendation on implementation strategy, e.g. "Implement via contract-first approach, define OpenAPI first, then backend, then frontend."}

## Sign-Off
- **Researcher**: {AI model, e.g. "Claude 3.5 Sonnet"}
- **Date**: {ISO 8601, e.g. 2026-04-11T15:30:00Z}
- **Status**: READY FOR REVIEW

---
**Next Step**: Human reviews this research, then approves or requests changes.  
**After approval**: `.sdlc/rpi/{story-id}/.approved-research` marker created, proceed to Plan phase.
```

---

## Rules & Constraints

### Codebase Search
- **Max 10 files** to extract
- **Max 2K chars per file** — summarize long files
- **Read-only** — do NOT make changes
- **Follow .gitignore** — respect ignored files
- **Token efficiency** — Prefer **paths + short excerpts** in `research.md`; do not paste entire source files. When using `.sdlc/module/`, cite contracts and use `sdlc module load` slices rather than dumping all YAML (`rules/repo-grounded-change.md`).

### Wiki Search
- **Max 5 documents** to include in research
- **Extract relevant sections only** — max 1K per doc
- **Link to pages** if available
- **Explain relevance** to story

### Risk Identification
- **Identify, don't solve** — plan phase handles solutions
- **Be conservative** — flag potential risks even if low probability
- **Cross-team review** — note any dependencies on other teams

### Token Budgeting
- **Forecast conservatively** — round up for margin
- **Note assumptions** — e.g., "assumes 8 new tests"
- **Flag if >15K** — alert user to potential need for story split

### After Output
- **ALWAYS STOP** and wait for human approval
- **Do NOT proceed to Plan** until `.approved-research` marker exists
- **Do NOT make changes** to research.md after output
- Provide `.sdlc/rpi/{story-id}/research.md` path for human to review

---

## Example Output (Abbreviated)

```markdown
# Research Summary: Implement OAuth2 provider integration

## Story Context
- **ID**: US-1234
- **Type**: Feature
- **Route**: NEW_FEATURE
- **Scope**: Add OAuth2 support for third-party provider login
- **Acceptance Criteria**:
  - AC-01: User can initiate OAuth2 flow
  - AC-02: System redirects to provider
  - AC-03: User is logged in after callback

## Problem Statement
Currently, ExampleApp only supports email/password login. Feature request: add OAuth2 provider support (Google, GitHub, etc.) to improve user acquisition.

## Relevant Codebase Context

### Files to Modify
- **src/auth/AuthService.java** (L1-200, 400 lines total)
  - Current: Handles email/password flow only
  - Extract:
    ```java
    public class AuthService {
      public LoginResponse login(String email, String password) { ... }
      // No provider support
    }
    ```
  - Impact: Add OAuth2Provider parameter and flow

- **src/config/SecurityConfig.java** (L50-80, 150 lines total)
  - Current: Spring Security configured for form-based auth
  - Impact: Add OAuth2 client registration

- **db/schema/users_table.sql** (V001, 50 lines)
  - Current: email, password_hash columns
  - Impact: Add provider_id, provider_name columns

...

## Wiki.js Context

### API & Service Contracts
- **OAuth2 Standard**: RFC 6749
  - Endpoints: /authorize, /token, /callback
  - Breaking change risk: No (additive only)

### Known Constraints
- Security: Must validate provider signatures
- Privacy: OAuth2 scope must be minimal (email, basic profile)

## Risk Assessment

### Edge Cases
| Scenario | Mitigation |
|----------|-----------|
| Provider endpoint down | Fallback to email login |
| User exists in both systems | Merge accounts via email |
| Token expired mid-flow | Re-initiate OAuth2 flow |

### Token Budget Forecast
- Plan: ~3.5K tokens
- Implement: ~4.5K tokens
- Verify: ~1.8K tokens
- Total: ~10K tokens

## Status: READY FOR REVIEW
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Wiki.js connection fails | Log error, continue with codebase research only |
| >10 files found | Recommend story split; document top 10 by relevance |
| Token budget >20K | Flag to user; may need story decomposition |
| Missing AC in story | Note as risk; proceed with available info |

---

## Integration Points

- **Input**: ADO work item (via MCP)
- **Output**: `.sdlc/rpi/{story-id}/research.md`
- **Gate**: `.sdlc/rpi/{story-id}/.approved-research` (created by human)
- **Next phase**: `/project:rpi-plan AB#{story-id}` (after approval)

---

**Last Updated**: 2026-04-11  
**Part of**: RPI Workflow (rules/rpi-workflow.md)
