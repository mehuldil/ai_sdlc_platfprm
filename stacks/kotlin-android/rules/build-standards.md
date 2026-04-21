# Gradle Build Standards (Kotlin/Android)

## Build Configuration
File: `build.gradle.kts` (Kotlin DSL)

```kotlin
android {
  compileSdk = 35
  defaultConfig {
    minSdk = 24
    targetSdk = 34
    versionCode = 1
    versionName = "1.0.0"
  }
  
  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }
  
  kotlinOptions {
    jvmTarget = "17"
  }
}
```

## Dependencies
- Platform: `libs.versions.toml` for centralized versioning
- Scopes: `implementation`, `testImplementation`, `androidTestImplementation`
- Common libraries:
  ```kotlin
  implementation("androidx.compose.ui:ui:1.6.0")
  implementation("com.google.dagger:hilt-android:2.47")
  implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.1")
  ```

## ProGuard Rules
File: `proguard-rules.pro`

```
# Hilt
-keep class com.google.dagger.hilt.** { *; }
-keep class javax.inject.** { *; }

# Data classes
-keepclassmembers class ** {
  *** component1();
  *** component2();
}

# Room database
-keep class * extends androidx.room.RoomDatabase
```

## Test Configuration
- Unit tests: JUnit4 + Mockito
- Integration tests: AndroidX Test
- Path: `src/test/` and `src/androidTest/`

## CI/CD Integration
- `./gradlew build` — Full build (test + lint)
- `./gradlew test` — Unit tests only
- `./gradlew connectedAndroidTest` — Device tests

---
**Last Updated**: 2026-04-10  
**Stack**: Kotlin/Android
