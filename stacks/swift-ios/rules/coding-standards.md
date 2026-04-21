# Swift Coding Standards (iOS)

## Naming Conventions
- **Types**: PascalCase (UserViewModel, LoginViewController)
- **Functions**: camelCase (getUser(), displayError())
- **Constants**: camelCase (defaultTimeout, maxRetries)
- **Enums**: PascalCase (UserState, NetworkError)

## Optionals & Null Safety
- Use Optional<T> explicitly (? suffix)
- Prefer `guard let` for unwrapping
- Safe unwrapping:
  ```swift
  guard let user = fetchUser() else { return }
  print(user.name)
  ```
- Never use `!` (force unwrap) except in initialization

## Protocol-Oriented Programming
- Prefer protocols over inheritance
- Extension-based composition
- Pattern:
  ```swift
  protocol UserFetching {
    func fetchUser(id: Int) async throws -> User
  }
  extension APIClient: UserFetching { }
  ```

## Error Handling
- Define custom error enum (Error-conforming)
- Use `throws` and `try`/`catch`
- Pattern:
  ```swift
  enum NetworkError: Error {
    case invalidURL
    case serverError(statusCode: Int)
  }
  ```

## SwiftUI Views
- Struct-based composition
- `@State` for local state
- `@ObservedObject` for external ViewModel
- Keep views under 200 lines

## Type Inference
- Let compiler infer types when obvious
- Explicit types for clarity
- Examples:
  ```swift
  let users = userService.fetchAll()  // Inferred
  let count: Int = 0                  // Explicit (needed for clarity)
  ```

## Comments
- Explain *why*, not *what*
- Documentation marks `///` for public APIs
- No commented-out code

---
**Last Updated**: 2026-04-10  
**Stack**: Swift/iOS
