---
name: React Native Implementation Variant
description: Implementation RPI rules and guardrails for React Native
stack: react-native
---

# React Native Implementation Variant

## Tech Stack
- Language: TypeScript (strict mode)
- Runtime: React Native 0.72+
- Build: Expo or React Native CLI (0.72+)
- State: Redux + Redux Toolkit or Zustand
- Async: async/await, Promises
- Testing: Jest + React Native Testing Library
- Navigation: React Navigation 6+

## RPI Rules

**Serialization:** [rpi-serialization-baseline.md](../../_includes/rpi-serialization-baseline.md) — phase locks for every stack. **Normative:** [rpi-workflow.md](../../../rules/rpi-workflow.md).

### Research Phase
- Load max 10 files (2K chars each)
- Read: package.json (dependencies, React Native version)
- Read: relevant screen, component, reducer, saga files
- Read: react-native-dev-standards.md, typescript-rules.md
- Read: navigation-patterns.md, state-management-guide.md

### Plan Phase
- Plan component hierarchy (screens, components)
- Define state structure (Redux store shape)
- List API contracts (endpoints)
- Estimate lines per file
- No code in plan, structure only

### Implement Phase
- Screens: function components with hooks
- State: Redux slices with createSlice (Redux Toolkit)
- Async: thunk middleware for API calls
- Styling: StyleSheet.create() with constants (not inline)
- Lists: FlatList with keyExtractor, NOT ScrollView + map
- Navigation: useNavigation, @react-navigation/native
- TypeScript: strict types for props, state, callbacks

## Guardrails

### Code Style
- Naming: camelCase for files/functions, PascalCase for components
- Components: export default or named export (pick one pattern)
- Hooks: useXxx pattern for custom hooks
- Arrow functions: prefer for components and callbacks
- Props: use TypeScript interfaces (not type aliases for objects)

### Performance
- Rendering: memo() for expensive components
- Lists: FlatList with updateCellsBatchingPeriod, maxToRenderPerBatch
- Async: avoid blocking JavaScript thread
- Images: optimize size before shipping, use FastImage if needed
- Memory: profile with React Native Debugger, fix leaks
- Navigation: lazy load screens if heavy

### Security
- Secrets: use environment variables (.env.example in repo, .env in .gitignore)
- Network: certificate pinning (Metro bundler or axios interceptor)
- Storage: use AsyncStorage with encryption (not plain)
- Authentication: OAuth2 PKCE, store tokens securely
- No hardcoded URLs; use config per environment

### Testing
- Unit tests: test Redux slices, selectors with Jest
- Component tests: React Native Testing Library for screens
- Integration tests: E2E with Detox (optional)
- Coverage: aim for 70%+ code coverage
- Mock API: use MSW (Mock Service Worker) or jest.mock

## Dependency Checklist
- React Native 0.72+
- TypeScript (strict mode)
- React Navigation 6+ (@react-navigation/native, @react-navigation/bottom-tabs or stack)
- Redux Toolkit + React-Redux
- Redux Thunk (middleware)
- Axios (HTTP client)
- AsyncStorage (@react-native-async-storage/async-storage)
- Jest + React Native Testing Library (testing)
- ESLint + Prettier (code style)
