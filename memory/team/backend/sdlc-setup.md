# Backend Team SDLC Setup

**Team**: Backend  
**Last Updated**: 2026-04-10  

---

## Development Environment

### Prerequisites
- Java 17 JDK (Amazon Corretto or Eclipse Temurin)
- Gradle 8.x
- Git 2.40+
- Docker (for local PostgreSQL/Kafka/Redis)
- Docker Compose 2.x

### Local Setup
```bash
# Clone repo
git clone https://github.com/example-org/auth-service.git
cd auth-service

# Install dependencies
./gradlew build

# Start local services (Docker Compose)
docker-compose up -d

# Run service
./gradlew bootRun
```

### Docker Compose (docker-compose.yml)
- PostgreSQL 14 (port 5432)
- Redis 7 (port 6379)
- Kafka 3 (port 9092)
- localstack (AWS mock, port 4566)

---

## CI/CD Pipeline

### GitHub Actions
- **Trigger**: Push to any branch
- **Steps**:
  1. Lint (Checkstyle)
  2. Test (JUnit)
  3. Build (Gradle)
  4. Coverage (JaCoCo, ≥80% required)
  5. SAST (SonarQube)
  6. Push to ECR (image registry)

### Branch Strategy
- `main` — Production-ready (protected)
- `develop` — Integration branch (CI/CD required)
- `feature/AB-{id}-slug` — Feature branches (PR required)

### PR Requirements
- 2 approvals (code review)
- CI/CD pipeline green
- Coverage ≥80%
- No unresolved comments

---

## Testing Strategy
- **Unit Tests**: src/test/java (JUnit4)
- **Integration Tests**: src/integrationTest/java (TestContainers)
- **Load Tests**: jmeter/ (JMeter)
- **Coverage Target**: ≥80%

---

## Deployment

### Staging
- Trigger: Merge to develop
- Deployment: Automatic (no manual approval)
- Environment: AWS EKS (staging namespace)
- URL: https://staging-api.example.invalid

### Production
- Trigger: Manual (release manager)
- Deployment: Blue-green (zero downtime)
- Environment: AWS EKS (production namespace)
- URL: https://api.example.invalid
- Rollback: 1-click (previous version)

---

## Monitoring & Alerts
- **Metrics**: Prometheus (8-hour retention)
- **Dashboards**: Grafana (custom per service)
- **Logs**: ELK Stack
- **Alerts**: PagerDuty (on-call rotation)

---

**Onboarding Doc**: [Link to wiki]  
**Support Channel**: #backend-team Slack
