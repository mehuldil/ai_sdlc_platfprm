# Kotlin/Android Conventions

## Overview
Android projects follow MVVM (Model-View-ViewModel) architecture with modern Kotlin patterns. Target API 34 (Android 14).

## Architecture: MVVM

### Model
- Data classes, repositories, local/remote data sources
- Location: `app/src/main/java/com/jio/cloud/{feature}/data/`

### View
- Activities, Fragments, Composables
- Minimal logic; delegates to ViewModel
- Location: `app/src/main/java/com/jio/cloud/{feature}/ui/`

### ViewModel
- Business logic, state management
- Extends AndroidViewModel (lifecycle-aware)
- Exposes LiveData/StateFlow for UI
- Location: `app/src/main/java/com/jio/cloud/{feature}/viewmodel/`

## Dependency Injection: Hilt
- Scopes: `@Singleton`, `@ActivityScoped`, `@FragmentScoped`
- Module pattern for bindings
- Example:
  ```kotlin
  @Singleton
  @Provides
  fun provideUserRepository(api: UserApi): UserRepository {
    return UserRepositoryImpl(api)
  }
  ```

## Async: Kotlin Coroutines
- No callbacks; use suspend functions
- ViewModel launches with `viewModelScope`
- Example:
  ```kotlin
  fun loadUsers() {
    viewModelScope.launch {
      try {
        val users = userRepository.getUsers()
        _users.value = users
      } catch (e: Exception) {
        _error.value = e.message
      }
    }
  }
  ```

## UI Framework
- **Jetpack Compose** for new screens
- **Traditional Layout XML** for legacy screens (coexist during migration)
- Min SDK: 24, Target SDK: 34

## Module Structure
```
app/
├── src/main/java/com/jio/cloud/
│   ├── auth/
│   │   ├── data/
│   │   ├── ui/
│   │   ├── viewmodel/
│   ├── profile/
│   │   ├── ...
├── build.gradle.kts
feature_modules/
├── feature-auth/
├── feature-profile/
```

## Gradle Build
- **Language**: Kotlin DSL (build.gradle.kts)
- **Minimum API**: 24
- **Target API**: 34
- **Compile SDK**: 35

---
**Last Updated**: 2026-04-10  
**Stack**: Kotlin/Android
