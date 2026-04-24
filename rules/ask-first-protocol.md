# ASK-First Protocol

**Unified rule consolidating ASK-First Protocol, Safety Guardrails, and Chat-First Ask guidance.**

---

## Universal Principle
**DO NOT ASSUME — Always ASK → PLAN → DESIGN → Implement → TEST → Merge → Build → Deploy**

**Core mandate:** AI generates; humans approve. No autonomous actions that bypass human decision-making.

Every AI agent, every stage, every workflow MUST follow this sequence. No step can be skipped or auto-decided.

---

## Prohibited AI Actions

### Code & Deployment
- ❌ Auto-merge pull requests
- ❌ Auto-deploy to production or pre-production
- ❌ Override quality gates (coverage, linting, security scans)
- ❌ Modify code outside the scope of the current story
- ❌ Delete or force-push to main/master branches
- ❌ Create branches without asking developer for name/source/strategy
- ❌ Choose merge strategy without asking (squash vs merge vs rebase)

### Work Item Management
- ❌ Auto-close stories without explicit user approval
- ❌ Auto-change story state without gate verification AND user approval
- ❌ Auto-remove or add tags without showing changes and asking
- ❌ Auto-link stories without human review
- ❌ Create work items without asking for type, title, parent, assignment
- ❌ Post ADO comments without showing draft and asking
- ❌ Assume work item fields — always fetch current state first

### Data & Secrets
- ❌ Log, cache, or transmit sensitive data (PII, API keys, credentials)
- ❌ Store ADO PAT or other secrets in memory or logs
- ❌ Access user files outside mounted directories

---

## Mandatory AI Actions

### Before Any Implementation
1. **Present findings** — Show what needs to be done with evidence
2. **Present options** — If multiple approaches, show numbered options with pros/cons
3. **Ask for decision** — Explicitly ask user for approval (numbered choice or free text)
4. **Wait for human** — NEVER proceed without explicit approval
5. **Confirm understanding** — Repeat back what user decided before executing

### After Implementation
1. **Show results** — Present what was done with evidence (diff, test output, etc.)
2. **Log decision** — Record user approval in ADO comment
3. **Update status** — Change tags/state only after user confirms
4. **Report summary** — Concise summary of outcomes

### When Unsure
**Stop, state uncertainty, present numbered options, wait for user clarification.** See §Core ASK Rules below.

---

## Core ASK Rules

### Before ANY action:
1. If requirement is unclear → ASK user to clarify
2. If scope is ambiguous → ASK user to define boundaries  
3. If multiple approaches exist → PRESENT options with pros/cons, ASK user to choose
4. If dependency exists → ASK user to confirm resolution
5. If out of scope → ASK user to confirm new story creation

### When ASKing:
- Present numbered options (never free text prompts)
- Include "Other (type your input)" as last option
- Keep options to 3-5 maximum
- Show impact/consequence of each option
- Wait for explicit user response before proceeding

### When NOT to ASK:
- When user has already given clear, explicit instruction
- When previous answer in same session covers the question
- When the action is pure read-only (fetching data, displaying info)

## ADO Work Item Rules

1. **Create**: ASK for type, title, parent, assignment before creating
2. **Update**: Show current state → Show proposed changes → ASK to confirm
3. **State Change**: Show gate requirements → Show evidence → ASK to approve
4. **Close**: Show completion criteria → Verify all met → ASK to close
5. **Comment**: Show draft → ASK before posting

## Branch Strategy Rules

1. Before creating any branch → ASK for:
   - Branch name preference
   - Source branch (main, develop, release/*, etc.)
   - Feature or hotfix type
2. Before merging → ASK:
   - Target branch confirmation
   - Squash vs merge commit preference
   - PR reviewer assignment
3. Confirm repo context before any git operation

## PR Rules

1. Before creating PR → ASK for target branch, reviewers, title/description
2. Before approving → Show all checks status → ASK
3. Before merging → Show merge strategy options → ASK
4. Before posting comments → Show draft → ASK

## Gate Validation (ALWAYS ASK)

For each gate (G1-G10):
1. Present gate requirements
2. Show evidence collected
3. Show what's missing (if anything)
4. ASK user: Approve / Reject / Edit / Skip (with justification)
5. Log decision in ADO comment

## Token Optimization

- ASK once, capture completely — don't re-ask same question
- Batch related questions into single prompt
- Use numbered options for fastest user response
- Cache answers in .sdlc/memory/ for session continuity

---

## Chat-First ASK in IDE (Cursor & Claude Code)

**For all ASK-first matters in IDE chat (missing role, stack, stage, ambiguous intent):**

1. **Ask in the chat thread** — Present numbered options (and "Other" / free text)
2. **Wait for the user's reply in chat** — Never direct users to answer in Terminal
   - IDE-invoked shells have no TTY; `read` in bash cannot receive chat input
   - User keyboard in chat is NOT connected to process stdin
3. **After the user answers**, run the appropriate non-interactive command:
   - Example: `sdlc use backend --stack=java`
   - Example: `sdlc run 05-system-design --story=US-851789`
4. **Secrets:** Never ask for ADO PAT or credentials in chat
   - Direct users to `env/.env` and `env/env.template`

**Escape hatch:** Users in real terminal (Git Bash, etc.) can set `SDL_FORCE_INTERACTIVE=1` to enable prompts.

---

## Scope Creep Prevention

### Story Scope Rules
1. **Code changes**: Only within files listed in story acceptance criteria
2. **Configuration changes**: ADO work items only if linked with `dependency:` tag
3. **Cross-team impact**: Require cross-team dependency tag

### Scope Challenge Process
If user requests out-of-scope work:
1. **Acknowledge** request
2. **Document** scope boundary
3. **ASK**: "This is outside story scope. Options: (1) Create new story (2) Expand current scope (3) Skip for now"
4. **Wait** for user decision before proceeding

---

## Token Budget Enforcement

### Daily Limit: 50K tokens / 50 invocations
- Monitor via `env/.token-usage.log`
- Haiku calls: ~2-4K per invocation
- Sonnet calls: ~8-16K per invocation
- Opus calls: ~16-32K per invocation

### Optimization Rules
- ASK once, capture completely — don't re-ask the same question
- Batch related questions into single prompt (max 3-5 questions)
- Use numbered options for fastest user response
- Cache answers in `.sdlc/memory/` for session continuity
- Load context progressively (Tier 1 → Tier 2 → Tier 3)

### When Budget Exceeded
1. Stop all non-critical invocations
2. Log overage in `env/.token-usage.log`
3. Alert user: "Daily token budget exceeded. Current: XXK / 50K"
4. Resume next calendar day

---

## Quality Gate Validation (Advisory, NOT Blocking)

### Pre-Merge Checklist (AI validates and reports, user decides)
- Coverage measured and reported (target ≥80%)
- Linting status checked and reported
- Security scan results reviewed and reported
- Architecture ADR reference checked
- Gate criteria status presented to user

### Gate Tags
- Gates are **checkpoints, NOT blockers** — AI validates and presents, user decides
- **ALWAYS** present gate status and ASK for user input
- **NEVER** block progress — if user says proceed, AI proceeds
- Missing gate evidence = Show gaps, ASK user what to do (proceed/fix/skip)

---

## Enforcement

- Every agent MUST read this file before execution
- Every stage MUST validate context against this protocol
- Violation = immediate halt + ask user

---

**Last Updated**: 2026-04-11  
**Consolidated from**: ask-first-protocol.md + guardrails.md + chat-first-ask.md  
**Governed By**: AI-SDLC Platform
