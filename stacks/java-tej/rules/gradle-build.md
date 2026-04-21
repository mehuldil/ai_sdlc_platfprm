# Gradle Build Standards (Java TEJ)

## Gradle Kotlin DSL
All projects use `build.gradle.kts` (Kotlin DSL, not Groovy)

## Basic Structure
```kotlin
plugins {
  java
  id("com.example.app.conventions") version "1.0"
}

group = "com.jio.cloud"
version = "1.0.0"

dependencies {
  implementation("com.jio.cloud:tej-core:2.1.0")
  implementation("com.google.code.gson:gson:2.10.1")
  
  testImplementation("junit:junit:4.13.2")
}

tasks.withType<Test> {
  useJUnit()
  testLogging {
    events("passed", "skipped", "failed")
  }
}
```

## Dependency Management
- Platform: `libs.versions.toml` for version catalog
- Scope: `implementation`, `testImplementation`, `runtimeOnly`
- Exclude transitive: Use `exclude` only if conflict

## Build Properties
- `sourceCompatibility = "17"`
- `targetCompatibility = "17"`
- Encoding: `options.encoding = "UTF-8"`

## Custom Tasks
- Shadow JAR: Include transitive dependencies (for microservices)
- Test coverage: JaCoCo configured at organization level

## CI/CD Integration
- `./gradlew build` — Full build
- `./gradlew test` — Unit tests only
- `./gradlew check` — Static analysis + tests

---
**Last Updated**: 2026-04-10  
**Stack**: Java 17 TEJ/RestExpress
