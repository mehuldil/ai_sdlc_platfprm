# TypeScript & React Native Coding Standards

## Naming Conventions
- **Components**: PascalCase (UserProfile, LoginForm)
- **Files**: PascalCase for components, camelCase for utilities
- **Functions**: camelCase (getUser(), handlePress())
- **Constants**: UPPER_SNAKE_CASE (DEFAULT_TIMEOUT)
- **Types**: PascalCase (User, ApiResponse)

## TypeScript Types
- Always define interfaces/types for objects
- No `any` — use `unknown` or generics instead
- Strict null checks enabled
- Union types for state:
  ```typescript
  type Status = "idle" | "loading" | "success" | "error";
  ```

## React Components
- Functional components only
- Props typed with interfaces
- Pattern:
  ```typescript
  interface UserRowProps {
    user: User;
    onPress?: (id: number) => void;
  }
  
  const UserRow: React.FC<UserRowProps> = ({ user, onPress }) => (
    <TouchableOpacity onPress={() => onPress?.(user.id)}>
      <Text>{user.name}</Text>
    </TouchableOpacity>
  );
  ```

## Hooks Best Practices
- Dependencies array always explicit
- Custom hooks for reusable logic
- Never call hooks conditionally
- Example:
  ```typescript
  const useUser = (id: number) => {
    const [user, setUser] = useState<User | null>(null);
    
    useEffect(() => {
      fetchUser(id).then(setUser);
    }, [id]);
    
    return user;
  };
  ```

## Error Handling
- Try/catch in async functions
- Specific error types (not generic Error)
- Pattern:
  ```typescript
  try {
    const data = await api.fetch();
    setData(data);
  } catch (error) {
    if (error instanceof NetworkError) {
      showNetworkAlert();
    }
  }
  ```

## Comments
- Explain *why*, not *what*
- JSDoc for public functions
- No commented-out code

---
**Last Updated**: 2026-04-10  
**Stack**: React Native
