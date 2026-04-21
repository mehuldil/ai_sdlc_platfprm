# Tech Stack Template: [Stack Name]

Replace `[Stack Name]` with stack name (e.g., "Go Backend", "Python ML", "Vue.js Frontend").

Create this at: `stacks/[stack]/conventions.md`

---

## Stack Overview

### Name
[E.g., "Go 1.21+ Backend with PostgreSQL"]

### Technology Choices

#### Languages & Frameworks
- **Language**: [E.g., "Go 1.21+"]
- **Web Framework**: [E.g., "Gin", "Fiber", "Echo"]
- **Testing Framework**: [E.g., "Go testing stdlib + stretchr/testify"]
- **Database ORM**: [E.g., "GORM", "sqlc"]

#### Data & Infrastructure
- **Database**: [E.g., "PostgreSQL 15+"]
- **Cache**: [E.g., "Redis 7+"]
- **Message Queue**: [E.g., "RabbitMQ 3.12+", "none"]
- **Search**: [E.g., "Elasticsearch 8+", "none"]

#### Deployment & DevOps
- **Containerization**: [E.g., "Docker", "containerd"]
- **Orchestration**: [E.g., "Kubernetes 1.27+", "Docker Compose", "None (VMs)"]
- **CI/CD**: [E.g., "GitHub Actions", "GitLab CI"]
- **Monitoring**: [E.g., "Prometheus + Grafana", "DataDog"]

### Version Requirements
- [Language/Framework]: Minimum [version], Recommended [version]
- [Language/Framework]: Minimum [version], Recommended [version]

### Why These Choices?
[Business/technical rationale. E.g., "Go selected for: type safety, fast compilation, concurrent request handling. PostgreSQL selected for: ACID compliance, familiar SQL, strong ecosystem."]

## Compatibility Matrix

### Supported Platforms
- [ ] Linux (x86_64, ARM64)
- [ ] macOS (Intel, Apple Silicon)
- [ ] Windows (WSL2)

### Node/Runtime Compatibility
[E.g., "Go 1.21.0+", "Node 18+", "Python 3.11+"]

### Database Compatibility
[E.g., "PostgreSQL 12.0+", "MySQL 8.0+"]

---

## Development Setup

### Prerequisites
1. [E.g., "Go 1.21+ installed"]
2. [E.g., "PostgreSQL 15+ running locally"]
3. [E.g., "Docker installed"]

### Quick Start
```bash
# Clone repo
git clone [repo]
cd [repo]

# Install dependencies
[e.g., "go mod download"]

# Set up database
[e.g., "psql -U postgres < schema.sql"]

# Run server
[e.g., "go run main.go"]

# Run tests
[e.g., "go test ./..."]
```

---

## Stack-Specific Rules

This stack includes specialized rules in `stacks/[stack]/rules/`:

1. **api-standards.md** — API contract patterns (REST, gRPC, GraphQL, etc.)
2. **coding-conventions.md** — Language idioms, code style, naming
3. **testing-standards.md** — Unit, integration, e2e test patterns
4. **deployment.md** — Build, package, deployment checklist
5. **performance-guidelines.md** — Optimization, profiling, benchmarking
6. **security-guidelines.md** — Authentication, authorization, data protection

---

## Stack-Specific Agents

[Optional: List agents that understand this stack]

- `agents/backend/[stack]-developer-agent.md` — Code review for this stack
- [Other agents as needed]

---

## Common Patterns

### Project Structure
```
[repo]/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── api/
│   │   ├── handlers.go
│   │   └── routes.go
│   ├── service/
│   │   └── business_logic.go
│   ├── repository/
│   │   └── db_queries.go
│   └── config/
│       └── config.go
├── migrations/
├── tests/
├── Dockerfile
├── docker-compose.yml
└── go.mod
```

### Dependency Management
[E.g., "`go.mod` and `go.sum` tracked in git; lock file behavior"]

### Build & Release
[E.g., "Compiled binary", "Docker image"]

---

## Common Tools & Extensions

### IDE Support
- [E.g., "VS Code with Go extension"]
- [E.g., "GoLand (JetBrains)"]

### Linting & Formatting
- [E.g., "golangci-lint"]
- [E.g., "gofmt (built-in)"]

### Testing Tools
- [E.g., "go test", "TestifyAssert", "GoConvey"]

### Performance Profiling
- [E.g., "pprof (built-in)", "wrk (load testing)"]

---

## Known Gotchas & Solutions

| Issue | Solution |
|-------|----------|
| [E.g., "Slow compilation on Windows"] | [E.g., "Use WSL2"] |
| [E.g., "Memory leaks in goroutines"] | [E.g., "Always cancel context"] |
| [E.g., "Database migration conflicts"] | [E.g., "Use numbered migrations"] |

---

## Troubleshooting

### Common Issues

**Issue**: [E.g., "Docker build fails on Apple Silicon"]  
**Solution**: [E.g., "Use `--platform linux/amd64` flag"]

**Issue**: [E.g., "Tests timeout in CI"]  
**Solution**: [E.g., "Increase timeout, check for blocked goroutines"]

---

## See Also

- `stacks/[stack]/rules/` — Stack-specific rules directory
- `agents/backend/[stack]-developer-agent.md` — Stack-specific agent
- [`docs/CONTRIBUTOR-GUIDE.md`](../../docs/CONTRIBUTOR-GUIDE.md) — How to extend with new stack

---

**Created**: [YYYY-MM-DD]  
**Last Updated**: [YYYY-MM-DD]  
**Governed By**: AI-SDLC Platform
