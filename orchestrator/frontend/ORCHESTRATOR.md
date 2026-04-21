---
name: frontend
description: Frontend orchestrator skill - routes to dev platform agents (Android, iOS, RN)
model: sonnet-4-6
token_budget: {input: 8000, output: 4000}
---

# Frontend Skill

Frontend implementation orchestration across all platforms.

## Platform Coverage

- **iOS**: Swift with SwiftUI, async/await, ARC safety
- **Android**: Kotlin with MVVM, Hilt, Coroutines
- **React Native**: TypeScript, hooks, FlatList optimization

## Orchestration

- Analyze feature specifications and extract platform-specific requirements
- Route stories to platform specialists (iOS, Android, React Native)
- Ensure cross-platform consistency and feature parity
- Coordinate design handoff from designer
- Create platform-specific tasks for specialists
- Manage code review and quality across all platforms
- Track visual fidelity and design system compliance

## Platform Delegation

- **iOS Features** → ios-dev agent
- **Android Features** → android-dev agent
- **React Native** → rn-dev agent
- **Shared Components** → All platforms coordinate

## Process Flow

1. Receive feature specification and design
2. Analyze platform-specific requirements
3. Delegate to platform specialists
4. Create platform-specific implementation tasks
5. Review implementations and coordinate reviews
6. Validate quality and consistency across platforms
7. Ensure feature parity and design compliance

## Integration Points

- Works with designer on specification clarity
- Coordinates with peer-reviewer on quality
- Aligns with qa on testing
- Communicates with architecture-guardian

## Related Agents

The frontend skill coordinates with these consolidated agents:
- **android-dev** - Android Kotlin/MVVM implementation
- **ios-dev** - iOS Swift/SwiftUI implementation
- **rn-dev** - React Native TypeScript implementation
- **designer** - Figma design spec extraction and handoff
- **developer** - Implementation orchestrator
- **peer-reviewer** - Code quality and architecture review
- **cto** - Frontend technical leadership
- **architecture-guardian** - Module boundaries and dependency monitoring
- **platform-qa** - Consolidated platform QA
- **security-agent** - Security and monitoring
- **perf-optimizer** - Performance optimization and profiling
- **scaffolding-agent** - Module generation and task sizing

## Skill Triggers

Use this skill when:
- Feature ready for frontend implementation
- Design specification complete
- Multiple platform implementation needed
- Cross-platform coordination required

## Quality Standards

- Consistent UX across platforms
- Design system compliance
- Accessibility compliance (WCAG AA)
- Performance targets met
- Code standards maintained
