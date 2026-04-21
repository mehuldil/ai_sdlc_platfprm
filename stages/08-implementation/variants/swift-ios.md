---
name: Swift iOS Implementation Variant
description: Implementation RPI rules and guardrails for iOS (Swift)
stack: swift-ios
---

# Swift iOS Implementation Variant

## Tech Stack
- Language: Swift 5.9+
- UI: SwiftUI (preferred) or UIKit
- Async: async/await, Tasks
- Persistence: CoreData or SwiftData
- Networking: URLSession or Alamofire
- Testing: XCTest, XCUITest
- Build: Xcode 15+, Swift Package Manager or CocoaPods

## RPI Rules

**Serialization:** [rpi-serialization-baseline.md](../../_includes/rpi-serialization-baseline.md) — phase locks for every stack. **Normative:** [rpi-workflow.md](../../../rules/rpi-workflow.md).

### Research Phase
- Load max 10 files (2K chars each)
- Read: Package.swift or Podfile (dependencies)
- Read: relevant ViewModel, Repository, View (SwiftUI) or ViewController (UIKit)
- Read: swift-dev-standards.md, swiftui-patterns.md
- Read: memory-management-guide.md (ARC, retain cycles)

### Plan Phase
- Plan module structure: Presentation, Domain, Data layers
- Define ViewModels, Models, Services
- List database schema changes
- Estimate lines per file
- No code in plan, structure only

### Implement Phase
- SwiftUI: @State, @StateObject, @EnvironmentObject for state
- async/await: async functions, await calls, structured concurrency
- ARC: use [weak self] in closures to avoid retain cycles
- Networking: async URLSession, decode with Codable
- No delegate callbacks; use Combine publishers or async/await
- Error handling: Result type, try-catch for throwing functions

## Guardrails

### Code Style
- Swift naming: camelCase for variables/functions, PascalCase for types
- Optionals: use ? for optional chaining, ! only if guaranteed non-nil
- Properties: computed properties for derived state
- Extensions: organize by protocol conformance
- Comments: explain "why", not "what"

### Memory Management (ARC)
- Avoid retain cycles: weak references in closures
- No strong self capture unless necessary
- Deinit: use for cleanup (observers, timers)
- Autoreleasepool: wrap tight loops creating objects
- Weak delegates: UITableViewDelegate delegates are weak by default

### Security
- Keychain: store sensitive data (tokens, passwords)
- Network: certificate pinning with URLSessionDelegate
- Encryption: use CryptoKit for sensitive operations
- Logging: never log tokens or credentials
- Deeplinks: validate URL scheme and parameters

### Performance
- Images: use Image(systemName:) for SF Symbols, resize large images
- Lists: use List in SwiftUI (lazy loading), UITableView with pagination
- Background tasks: use BGTask for background work
- Memory: use Instruments (Allocations, Leaks) to find leaks
- Battery: avoid frequent network requests, use URLCache

### Testing
- Unit tests: test ViewModels with XCTest, mock dependencies
- UI tests: use XCUITest for critical flows
- Coverage: aim for 75%+ core logic coverage
- Mock network: use URLProtocol or stub URLSession

## Dependency Checklist
- SwiftUI or UIKit (UI framework)
- Combine (reactive programming)
- CoreData or SwiftData (persistence)
- URLSession (networking)
- Codable (JSON serialization)
- CryptoKit (cryptography)
- XCTest (unit testing)
- XCUITest (UI testing)
