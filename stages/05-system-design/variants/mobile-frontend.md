---
name: Mobile Frontend Design Variant
description: System design specifics for iOS, Android, React Native
stack: mobile-frontend
---

# Mobile Frontend Design Variant

## Module Architecture

### Core Bridge Pattern
- Bridge: unified TypeScript/native bridge (RN, native iOS Swift, native Android Kotlin)
- Native modules: platform-specific implementations
- JavaScript layer: shared business logic (React/hooks)
- Each platform: iOS (Swift/SwiftUI), Android (Kotlin/Compose), RN (TypeScript/React Native)

### Module Boundaries
- API Client: handle HTTP, caching, retry logic
- State Management: Redux/Context (shared logic)
- UI Components: platform-specific designs
- Utils: platform-agnostic helpers
- Models: TypeScript interfaces for type safety

## Platform-Specific Considerations

### iOS (Swift)
- ARC memory model: avoid retain cycles (weak self in closures)
- async/await for concurrency (not callbacks)
- SwiftUI for UI (declarative)
- Combine framework for reactive streams
- Target iOS 14+ for deployment

### Android (Kotlin)
- MVVM architecture pattern
- Hilt for dependency injection
- Coroutines for async (structured concurrency)
- Jetpack Compose for UI (or XML layouts)
- Target API 30+ for compilation

### React Native
- Separate iOS and Android projects initially
- Use TypeScript (strict mode)
- Hooks for state management
- FlatList for lists (not ScrollView for performance)
- StyleSheet.create() for styles (not inline)

## API Contract Design
- Same REST API for all platforms
- GraphQL option for mobile (reduces payload)
- Fallback endpoints for network resilience
- Version headers: Accept: application/vnd.jio.v1+json

## Storage & Caching
- Local database: SQLite or Realm
- Cache strategy: HTTP cache headers + local override
- Offline-first: queue mutations, retry on connection
- Encryption: Keychain (iOS), Keystore (Android)

## Security
- Certificate pinning required
- OAuth2 + PKCE for authentication
- No credentials in logs
- Biometric auth when available
