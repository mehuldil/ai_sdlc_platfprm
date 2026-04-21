# Global Documentation & Code Standards

## Documentation Format
- **Language**: English (all code comments and docs)
- **Markup**: Markdown CommonMark 0.30
- **Line Length**: Max 120 characters
- **Diagrams**: Mermaid 8.x syntax

## Mermaid Rules
- No colons (`:`) inside node labels
- Wrap labels containing special characters in double quotes
- Use lowercase for node IDs
- Limit nesting depth to 3 levels for readability

## Commit Message Format
**Conventional Commits + Azure DevOps Work Item Reference**

```
<type>(<scope>): <description> AB#<work-item-id>

<body (optional)>

<footer (optional)>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`

Example:
```
feat(auth): implement OAuth2 provider integration AB#12345

- Added provider discovery endpoint
- Implemented token exchange flow
- Added unit tests for auth flow

Closes AB#12345
```

## Pull Request Standards
- **Title**: Conventional Commits format
- **Description**: Link to ADO Work Item(s) using `AB#<id>`
- **PR ↔ PRD**: Use the reference scheme in `traceability-pr-prd.md` (PRD path + `PRD-REF-…` + `AB#`)
- **Branch**: `feature/AB-<id>-slug` or `fix/AB-<id>-slug`
- **Reviewers**: Minimum 2 approvals before merge
- **CI/CD**: Must pass all gates (see gate-enforcement.md); merge blocking and source-of-truth: `merge-and-source-of-truth.md`

## Code Comment Guidelines
- Single-line comments: `//` (inline explanations)
- Block comments: Explain *why*, not *what* (code shows what)
- Deprecation: Use language-standard deprecation markers
- TODO: Format as `TODO(owner): description [target-version]`

## File Structure
```
src/
├── main/
│   ├── code/
│   └── resources/
├── test/
└── docs/
```

## Encoding
- UTF-8 for all source files
- BOM not allowed

---
**Last Updated**: 2026-04-10  
**Governed By**: AI-SDLC Platform  
**Tags**: `standards`, `documentation`, `code-style`
