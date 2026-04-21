# Kotlin Coding Standards (Android)

## Naming Conventions
- **Classes**: PascalCase (UserViewModel, LoginActivity)
- **Functions**: camelCase (getUser(), displayError())
- **Constants**: UPPER_SNAKE_CASE (DEFAULT_TIMEOUT, MAX_RETRIES)
- **Private members**: Prefix underscore (_users, _error)

## Null Safety
- Prefer `?` (nullable) only when necessary
- Use `!!` (non-null assertion) sparingly
- Safe calls: `user?.name` instead of null checks
- Elvis operator: `name ?: "Unknown"`
- Never return null from functions; return empty list/Optional

## Coroutine Patterns
- Always use `viewModelScope` or `lifecycleScope`
- Cancel scopes automatically (lifecycle-aware)
- Pattern:
  ```kotlin
  viewModelScope.launch {
    val data = repository.fetch()
    _state.value = data
  }
  ```

## Data Classes
- Auto-generate copy(), equals(), hashCode(), toString()
- Example:
  ```kotlin
  data class User(
    val id: Long,
    val name: String,
    val email: String
  )
  ```

## Extension Functions
- Utility functions on existing types
- Named logically (e.g., `String.isValidEmail()`)
- Location: `util/Extensions.kt`

## Sealed Classes
- Use for type-safe enums with associated data
- Pattern:
  ```kotlin
  sealed class UiState {
    object Loading : UiState()
    data class Success(val data: List<User>) : UiState()
    data class Error(val message: String) : UiState()
  }
  ```

## Comments
- Explain *why*, not *what*
- KDoc for public APIs
- No commented-out code

---
**Last Updated**: 2026-04-10  
**Stack**: Kotlin/Android
