# React Native Conventions

## Overview
Cross-platform mobile apps using TypeScript (strict mode), React hooks, and native modules for platform-specific code.

## TypeScript
- **Mode**: Strict (`"strict": true`)
- **No `any` types**: Use `unknown` or generics
- **ESLint**: Enforced in CI
- Example:
  ```typescript
  interface User {
    id: number;
    name: string;
    email: string;
  }
  ```

## React Hooks Architecture
- Functional components only (no class components)
- State: `useState`
- Effects: `useEffect` with explicit dependency array
- Context: Custom hooks wrapping useContext
- Pattern:
  ```typescript
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  
  useEffect(() => {
    fetchUsers().then(setUsers);
  }, []);
  ```

## List Rendering
- **FlatList** for long lists (virtualized)
- **map()** for short lists (<20 items)
- Never use index as key
- Example:
  ```typescript
  <FlatList
    data={users}
    keyExtractor={(user) => user.id.toString()}
    renderItem={({ item }) => <UserRow user={item} />}
  />
  ```

## Styling
- **StyleSheet** for all styles (optimized)
- No inline styles except responsive values
- Pattern:
  ```typescript
  const styles = StyleSheet.create({
    container: { flex: 1, padding: 16 },
    text: { fontSize: 16, fontWeight: "600" }
  });
  ```

## Native Module Bridge
- Core Bridge pattern for platform-specific code
- Location: `src/native/`
- Namespaced: `ios/` and `android/`

## Module Structure
```
src/
├── modules/
│   ├── {module}/
│   │   ├── components/
│   │   ├── screens/
│   │   ├── hooks/
│   │   ├── services/
│   │   ├── types/
├── native/
│   ├── ios/
│   ├── android/
├── utils/
```

## Build Tools
- **Metro Bundler**: JavaScript/TypeScript bundling
- **Hermes Engine**: JavaScript execution (smaller bundle)
- **Bundle Size**: Target <50MB per platform

---
**Last Updated**: 2026-04-10  
**Stack**: React Native
