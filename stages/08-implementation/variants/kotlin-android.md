---
name: Kotlin Android Implementation Variant
description: Implementation RPI rules and guardrails for Android (Kotlin)
stack: kotlin-android
---

# Kotlin Android Implementation Variant

## Tech Stack
- Language: Kotlin 1.9+
- Build: Gradle 8.x (with AGP 8.x)
- UI: Jetpack Compose (preferred) or XML layouts
- Architecture: MVVM
- Dependency Injection: Hilt
- Async: Coroutines (not RxJava)
- Testing: JUnit 4, Mockito, Espresso

## RPI Rules

**Serialization:** [rpi-serialization-baseline.md](../../_includes/rpi-serialization-baseline.md) — phase locks for every stack. **Normative:** [rpi-workflow.md](../../../rules/rpi-workflow.md).

### Research Phase
- Load max 10 files (2K chars each)
- Read: build.gradle.kts (dependencies, Android config)
- Read: relevant ViewModel, Repository, Composable, Fragment classes
- Read: android-dev-standards.md, coroutine-patterns.md
- Read: hilt-setup.md, jetpack-compose-guide.md (if applicable)

### Plan Phase
- Plan package structure: presentation, domain, data layers
- Define ViewModels, Repositories, Composables
- List database migrations (if any)
- Estimate lines per file
- No code in plan, structure only

### Implement Phase
- Use MVVM: ViewModel for state, Repository for data
- Coroutines: launch, async, flow for async operations
- Hilt: @HiltViewModel, @Inject, @Provides
- UI: Compose Composables (state, side effects, themes)
- No callbacks; use coroutines or Flow
- Lifecycle-aware: use viewLifecycleScope, lifecycleScope

## Guardrails

### Code Style
- Kotlin naming: camelCase for variables/functions, PascalCase for classes
- Lambda formatting: single-line if < 80 chars, multi-line otherwise
- Null safety: use ?, !, ?: operators correctly
- Data classes: for models, use @Serializable

### Security
- Secrets: use BuildConfig.DEBUG check or ConfigServer
- Encryption: SharedPreferences with Tink library
- Network: certificate pinning with OkHttp
- Authentication: OAuth2 PKCE flow

### Performance
- Memory: avoid memory leaks (context, listeners)
- Lists: use LazyColumn in Compose, RecyclerView with DiffUtil in XML
- Images: use Coil or Glide with compression
- Battery: avoid constant polling, use WorkManager for background tasks
- ANR prevention: no blocking operations on main thread

### Testing
- Unit tests: test ViewModels with Mockito
- UI tests: use Espresso for XML layouts, Compose test rules for Compose
- Coverage: aim for 70%+ ViewModel coverage
- Mock network: use MockWebServer or OkHttp interceptors

## Dependency Checklist
- Androidx AppCompat, Core, Lifecycle
- Jetpack Compose (or Material Design components for XML)
- Hilt (dependency injection)
- Coroutines + Flow
- Retrofit (HTTP client)
- Gson or Moshi (JSON)
- Room (local database)
- JUnit 4, Mockito, Espresso (testing)
