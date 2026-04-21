# Rule Template: [Rule Name]

Replace `[Rule Name]` with rule name (e.g., "API Documentation Standard", "Performance Budget").

---

## Rule Statement

### The Rule
[Clear, imperative statement of the rule. E.g., "All public APIs must be documented in OpenAPI 3.1 format."]

### Scope
[Who does this apply to? E.g., "All Backend engineers", "All frontend components", "JavaScript/TypeScript only"]

### Applies At
[Which stages enforce this? E.g., "Stage 09 (Code Review)", "Stage 08 (Implementation)"]

## Rationale

### Why This Rule Exists
[Business or technical reason. E.g., "API contracts enable frontend integration in parallel with backend development. Without contracts, teams wait for implementation to start work."]

### Exceptions
[When can this rule be broken? E.g., "Internal/private APIs behind feature flags; exclude sandbox/test endpoints"]

## Examples

### Good ✓
[Example of code/work that follows the rule. E.g., API with OpenAPI spec, all endpoints documented]

```
GET /api/v1/users/{id}
Description: Retrieve user by ID
Parameters:
  - id (string, required)
Responses:
  200: User object
  404: User not found
```

### Bad ✗
[Example of code/work that violates the rule. E.g., undocumented API]

```
GET /api/v1/users/{id}
[No documentation, engineers must read source code]
```

## Enforcement

### How This Rule Is Checked
[Which agent or skill validates? E.g., "Code Review Agent in Stage 09 checks if API is documented in OpenAPI."]

### Consequences of Violation
[What happens if violated? E.g., "Blocking task created; PR cannot merge until contract added."]

### Tool/Automation
[Any tool that can auto-validate? E.g., "swagger-cli validate", "API contract checker script"]

## Implementation Guidance

### For Teams Implementing This Rule
[How to follow the rule. E.g., "Add openapi.yml to repo; reference in README; validate with CI/CD."]

### Checklists
- [ ] [Check 1, e.g., "API has OpenAPI specification"]
- [ ] [Check 2, e.g., "All endpoints documented"]
- [ ] [Check 3, e.g., "Examples provided for common scenarios"]

## Related Rules

[Other rules that work together. E.g., "Complements 'Error Handling Standard'", "Conflicts with 'Minimal Documentation Rule' if applied together"]

---

**Created**: [YYYY-MM-DD]  
**Last Updated**: [YYYY-MM-DD]  
**Governed By**: AI-SDLC Platform
