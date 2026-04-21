# Xcode Build Standards (Swift/iOS)

## Project Configuration
- **Deployment Target**: iOS 14.0 minimum
- **Swift Version**: 5.9+
- **Architectures**: arm64 (release), arm64 + x86_64 (debug for simulator)

## Build Settings
```
SWIFT_VERSION = 5.9
SWIFT_TREAT_WARNINGS_AS_ERRORS = YES
ENABLE_BITCODE = NO
CODE_SIGN_STYLE = Automatic
PROVISIONING_PROFILE_SPECIFIER = (Auto)
```

## Dependency Management: SPM (Primary)
- Preferred: Swift Package Manager
- Fallback: CocoaPods (legacy)
- Package.swift:
  ```swift
  .package(url: "https://github.com/foo/bar.git", from: "1.0.0")
  ```

## CocoaPods Configuration (if needed)
- File: `Podfile`
- Install: `pod install --repo-update`
- Platforms: iOS 14.0+

## Code Signing
- Automatic (Xcode-managed)
- Development Team: YourAzureProject
- Certificate: Development certificate on Mac

## Testing
- XCTest framework (standard)
- Unit tests: `target/Tests/`
- UI tests: `target/UITests/`
- Code coverage: Built-in to Xcode

## CI/CD Integration
- `xcodebuild build` — Build only
- `xcodebuild test` — Run all tests
- `xcodebuild archive` — Create IPA for distribution

---
**Last Updated**: 2026-04-10  
**Stack**: Swift/iOS
