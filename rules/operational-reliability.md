# Operational reliability: LLM variance, MCP/ADO, idempotency

## LLM non-determinism (cannot eliminate — control it)

| Practice | Why |
|----------|-----|
| **Structured outputs** | Use templates (`templates/`), fixed sections in stories/design |
| **Two-pass** | Generate → **validate** (story-validator, AC checks) before ADO post |
| **Low temperature** for extraction | Classify / extract fields with stricter settings where the IDE allows |
| **Human gate** | Grooming / design **Approve / Edit / Reject** before publish |
| **Version artifacts** | Store accepted markdown in repo or ADO history |

## MCP / Azure DevOps drift

| Risk | Mitigation |
|------|------------|
| Stale WI after edit | **Get** before **update**; patch only changed fields |
| Duplicate creates | Search WIQL **before** create; use idempotent titles/tags sparingly |
| PAT expiry | Rotate PAT; `sdlc doctor` / validate-config |
| Partial failure | Retry **read** to confirm state after **write**; log correlation ID in comment |

**Not guaranteed by MCP alone:** reconcile with **`sdlc ado show`** or WIQL when in doubt.

## Traceability without a corporate standard

Start with **`rules/traceability-pr-prd.md`** + PR template + **AB#** in commits/PRs. Tighten when compliance assigns global IDs.

## Token efficiency

- Load **only** the stage variant + role file needed.
- Reuse **shared skills** instead of pasting long prompts in chat.
