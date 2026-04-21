# Java 17 Coding Standards

## Naming
- Classes: `PascalCase`
- Methods: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- Packages: `com.example.app.{service}.{layer}`

## Structure & Formatting
- **Line length**: Max 120 characters
- **Indentation**: 4 spaces (no tabs)
- **Braces**: Allman style (opening brace on new line)
  ```java
  if (condition)
  {
    doSomething();
  }
  ```
- **Imports**: Sorted, grouped (java, javax, com.jio, others)

## Classes & Methods
- One public class per file
- Methods: Max 30 lines (complexity indicator)
- Constructors before methods
- Static methods at end
- Private helpers near callers

## Variables
- Final by default (mutability is exceptional)
- Descriptive names (no single letters except loop counters: i, j, k)
- Type inference: Use `var` for obvious types
  ```java
  var users = userRepository.findAll();  // Clear
  var x = repository.query();             // Too vague
  ```

## Null Safety
- Prefer Optional<T> over null returns
- Null checks: Use Objects.requireNonNull() in constructors
- Never return null collections (return empty instead)

## Comments
- Explain *why*, not *what*
- Javadoc for public APIs only
- No commented-out code (use git history)

---
**Last Updated**: 2026-04-10  
**Stack**: Java 17 TEJ/RestExpress
