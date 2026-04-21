# Frontend Architecture Decisions

**Team**: Frontend  
**Last Updated**: 2026-04-10  

---

## Key Decisions (Rationale)

### Component Architecture (ADR-020)
- **Decision**: Hooks-based composition with Storybook isolation
- **Rationale**: Easier testing, simpler state management, team familiarity
- **Status**: Active (React 18.3)

### State Management (ADR-021)
- **Decision**: useReducer for complex state; Context API for global (no Redux)
- **Rationale**: Avoid over-engineering; Context sufficient for current scale
- **Status**: Active (pending review for 1M+ user scale)

### Design System Integration (ADR-019)
- **Decision**: Figma tokens auto-synced via figma-tokens plugin (weekly)
- **Rationale**: Single source of truth; maintain consistency
- **Status**: Active (dark mode tokens added 2026-03-20)

### API Client Library (ADR-022)
- **Decision**: Axios with custom interceptors (auth, retry, errors)
- **Rationale**: Simple, reliable, team familiar (vs Fetch or SWR)
- **Status**: Active (v2.1)

---

## Architecture Review Schedule
- **Q2 2026**: Evaluate React 19 migration path
- **Q3 2026**: Review state management for 1M+ users
- **Next ADR**: Dynamic imports for code splitting (planned)

---

**Maintained By**: Carol Davis, Architecture Lead
