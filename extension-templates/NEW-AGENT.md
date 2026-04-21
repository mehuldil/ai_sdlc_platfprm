# Agent Template: [Agent Name]

Replace `[Agent Name]` with agent name (e.g., "Code Security Agent", "Performance Analyzer Agent").

---

## Agent Definition

### Role Embodied
[Which role does this agent embody? E.g., "Backend Engineer", "QA Lead"]

### Function
[One sentence describing what the agent does. E.g., "Scans code for security vulnerabilities, hardcoding, and compliance issues."]

## When Invoked

### Stages
List stages where this agent runs:
- Stage [N] ([Stage Name]): [Purpose, e.g., "Code review during development"]
- Stage [N] ([Stage Name]): [Purpose]

### Triggered By
- [Work item tag, e.g., "When work item has `security:required` tag"]
- [Specific condition, e.g., "Every PR to main branch"]

## Gates Checked

| Gate | Check | Consequence |
|------|-------|-------------|
| G[N] | [What is validated?] | [What happens if not met?] |

Example:
| Gate | Check | Consequence |
|------|-------|-------------|
| G6 | No critical vulnerabilities? | Creates blocking task if found |
| G10 | Security sign-off obtained? | Blocks release until approved |

## Skills Invoked

List the skills this agent uses:

1. **Skill Name 1**
   - Input: [File type, context, e.g., "Python source files, PR diff"]
   - Output: [Format, e.g., "JSON with vulnerabilities by severity"]
   - Model: [claude-opus, sonnet, haiku]

2. **Skill Name 2**
   - Input: [...]
   - Output: [...]
   - Model: [...]

## Execution Steps

1. [Step 1, e.g., "Load work item from ADO"]
2. [Step 2, e.g., "Load gate checklist from gate-enforcement.md"]
3. [Step 3, e.g., "Invoke skill-1 with code diff"]
4. [Step 4, e.g., "Synthesize findings and recommendations"]
5. [Step 5, e.g., "Ask user: proceed/fix/skip"]

## ADO Actions

List what this agent does to the work item:

- **Tags**: Add [e.g., `security:reviewed`]
- **Blocking Tasks**: Create if [condition, e.g., "critical vulnerability found"]
- **Comments**: Add [e.g., "Security scan results: X vulnerabilities found"]
- **Linked Items**: Link to [e.g., "Related security tasks"]

## Example Invocation and Output

**Input**:
```
Work item: Feature/PR with new API endpoint (Python)
Gates: G6 (Dev Complete)
```

**Output**:
```markdown
## Security Review Results

### Status: ⚠️ Warning

### Findings
1. [Finding 1]: Severity, location, impact
2. [Finding 2]: Severity, location, impact

### Recommendations
1. [Fix 1]: How to remediate
2. [Fix 2]: How to remediate

### Gate Status
- G6: Partial (1 medium vulnerability unresolved)

### User Decision Needed
(1) Proceed anyway  (2) Fix first  (3) Defer to later
```

---

## Cross-References

**Role**: `roles/[role].md`  
**Referenced in Stage**: `stages/[N]-[stage]/STAGE.md`  
**Uses Skills**: `skills/[role]/SKILL.md`, `skills/shared/SKILL.md`  

---

**Created**: [YYYY-MM-DD]  
**Last Updated**: [YYYY-MM-DD]  
**Governed By**: AI-SDLC Platform
