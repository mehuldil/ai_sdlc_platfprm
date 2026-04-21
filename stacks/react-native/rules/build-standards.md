# Build Standards (React Native)

## Development Setup
- **Node.js**: 18 LTS or later
- **Package Manager**: npm or yarn (consistent)
- **TypeScript**: 5.0+
- **React Native**: Latest stable

## Metro Bundler Configuration
File: `metro.config.js`

```javascript
module.exports = {
  project: {
    ios: {},
    android: {}
  },
  transformer: {
    getTransformOptions: () => ({
      transform: {
        experimentalImportSupport: false,
        inlineRequires: false
      }
    })
  }
};
```

## Hermes Engine
- Enable for all production builds (smaller bundle)
- Configuration (iOS):
  ```ruby
  # ios/Podfile
  post_install do |installer|
    react_native_post_install(installer)
    __apply_Xcode_12_5_M1_post_install_workaround(installer)
  end
  ```
- Configuration (Android): `android/app/build.gradle`
  ```gradle
  enableHermes: true
  ```

## Bundle Size Optimization
- Target: <50MB per platform
- Measure: `react-native bundle --analyze-output-file=report.html`
- Remove unused dependencies: `npm prune`
- Code splitting: Dynamic imports for lazy-loaded modules

## Testing
- Unit tests: Jest
- Component tests: React Native Testing Library
- E2E tests: Detox or similar
- Configuration: `jest.config.js`

## CI/CD Integration
- `npm install` — Install dependencies
- `npm run lint` — TypeScript + ESLint
- `npm test` — Run Jest tests
- `npm run build:ios` — iOS production build
- `npm run build:android` — Android production build

---
**Last Updated**: 2026-04-10  
**Stack**: React Native
