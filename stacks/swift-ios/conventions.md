# Swift/iOS Conventions

## Overview
iOS projects use modern Swift with async/await, SwiftUI for new screens, and UIKit for legacy code. Automatic Reference Counting (ARC) manages memory.

## Architecture: MVVM + Coordinator Pattern

### Model
- Codable structs for API responses
- Core Data entities for persistence
- Business logic in services

### View
- SwiftUI views (new code)
- UIViewController/UIView (legacy)
- Minimal state management

### ViewModel
- Publishes state via @Published (Combine)
- Handles business logic
- Equatable for diffing

### Coordinator
- Navigation orchestration
- Dependency injection
- No circular references

## Memory Management: ARC
- `strong` (default): Normal reference
- `weak`: For delegates, closures capturing self
- `unowned`: When nil is impossible
- Pattern:
  ```swift
  weak var delegate: UserDelegate?
  { [weak self] in
    self?.handleResponse()
  }
  ```

## Async/Await
- No callbacks; use async/await exclusively
- Tasks managed by SwiftUI lifecycle
- Example:
  ```swift
  Task {
    do {
      let users = try await api.getUsers()
      state.users = users
    } catch {
      state.error = error
    }
  }
  ```

## SwiftUI + UIKit Coexistence
- New screens: SwiftUI only
- Legacy screens: UIViewController (will migrate)
- Bridge via UIViewControllerRepresentable for integration

## Module Structure
```
iOS/
├── App/
│   ├── Coordinators/
│   ├── Scenes/
│   │   ├── Auth/
│   │   │   ├── Views/
│   │   │   ├── ViewModels/
│   │   ├── Profile/
├── Core/
│   ├── Services/
│   ├── Models/
```

## Build Configuration
- **Deployment Target**: iOS 14.0+
- **Swift Version**: 5.9+
- **Package Manager**: Swift Package Manager (SPM) or CocoaPods

---
**Last Updated**: 2026-04-10  
**Stack**: Swift/iOS
