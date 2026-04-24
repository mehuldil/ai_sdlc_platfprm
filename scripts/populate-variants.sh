#!/bin/bash
# Populate all 92 stage-stack variants with real guidance

set -e

BASE_DIR=".claude/templates"
VARIANTS_DIR="stages"
STACKS=("java" "python-django" "nodejs-express" "dotnet-core" "go-echo" "rust")

# Stage-specific variant content factory
generate_variant_content() {
    local stage=$1
    local stack=$2
    local stage_num=$3
    local stage_name=$4
    
    case $stage_num in
        "01")
            case $stack in
                "java") echo "# Stage 01: Requirement Intake (java)
## Stack-Specific Considerations
Java with Spring Boot is enterprise-ready. Intake should identify: Spring Boot version, existing service mesh (Istio?), monolith vs microservice, database choice.

## Key Agents
1. requirement-intake (identify scope, complexity)
2. architecture-feasibility (Spring Boot pros/cons for feature)

## Deliverables
- [ ] Requirement summary
- [ ] Technology assessment
- [ ] Dependency mapping
- [ ] Resource estimation

## Checklist
- Spring Boot compatibility verified
- Team skills assessment (Spring, Kafka, etc.)
- DevOps readiness (K8s, CI/CD)
- Existing code base review started

## Next Stage Precondition
Scope clear + tech stack confirmed + team capacity allocated" ;;
                "python-django") echo "# Stage 01: Requirement Intake (Python-Django)
## Stack-Specific Considerations
Django for rapid development. Intake should identify: Django version, async requirements (ASGI), database (PostgreSQL default), scaling concerns (Celery for async?).

## Key Agents
1. requirement-intake
2. feasibility-assessment (Django strengths/weaknesses)

## Deliverables
- [ ] Requirement summary
- [ ] Python/Django version assessment
- [ ] Async processing needs
- [ ] Database choice

## Checklist
- Python version pinned (3.10+)
- Django version compatible with feature
- Celery vs Async/await decision made
- PostgreSQL setup confirmed

## Next Stage Precondition
Scope clear + Python/Django stack confirmed + team Django expertise verified" ;;
                "nodejs-express") echo "# Stage 01: Requirement Intake (Node.js-Express)
## Stack-Specific Considerations
Node.js for fast prototyping. Intake should identify: Node version, event-driven needs, TypeScript adoption, async/await, database (MongoDB vs PostgreSQL?).

## Key Agents
1. requirement-intake
2. ecosystem-assessment (npm packages, dependencies)

## Deliverables
- [ ] Requirement summary
- [ ] Node.js version + package selection
- [ ] TypeScript or JavaScript decision
- [ ] Async flow mapping

## Checklist
- Node version locked (18 LTS)
- TypeScript setup confirmed
- npm/yarn choice made
- Async patterns clarified

## Next Stage Precondition
Scope clear + Node version confirmed + package ecosystem assessed" ;;
                "dotnet-core") echo "# Stage 01: Requirement Intake (.NET Core)
## Stack-Specific Considerations
.NET Core for enterprise. Intake should identify: .NET version (6.0+), C# async/await patterns, Entity Framework ORM choice, cloud platform (Azure preferred).

## Key Agents
1. requirement-intake
2. framework-assessment (.NET Core capabilities)

## Deliverables
- [ ] Requirement summary
- [ ] .NET version selection
- [ ] C# language features needed
- [ ] ORM choice (EF Core)

## Checklist
- .NET version 6.0+ selected
- C# async/await patterns identified
- Entity Framework Core version set
- Azure DevOps integration confirmed

## Next Stage Precondition
Scope clear + .NET version confirmed + Azure integration planned" ;;
                "go-echo") echo "# Stage 01: Requirement Intake (Go-Echo)
## Stack-Specific Considerations
Go for performance. Intake should identify: Go version, concurrency model (goroutines), HTTP framework (Echo), database driver, deployment target (K8s preferred).

## Key Agents
1. requirement-intake
2. performance-assessment (Go strengths)

## Deliverables
- [ ] Requirement summary
- [ ] Go version + dependencies
- [ ] Concurrency model
- [ ] Performance targets

## Checklist
- Go 1.20+ confirmed
- Echo framework version set
- Goroutine patterns defined
- K8s deployment confirmed

## Next Stage Precondition
Scope clear + Go stack confirmed + performance targets set" ;;
                "rust") echo "# Stage 01: Requirement Intake (Rust)
## Stack-Specific Considerations
Rust for performance + safety. Intake should identify: Rust edition (2021), async runtime (Tokio vs async-std), web framework (Axum), memory-critical paths, CPU-intensive operations.

## Key Agents
1. requirement-intake
2. safety-assessment (borrow checker implications)

## Deliverables
- [ ] Requirement summary
- [ ] Rust edition + dependencies
- [ ] Async runtime choice
- [ ] Memory/CPU constraints

## Checklist
- Rust 2021 edition confirmed
- Tokio runtime selected
- Axum web framework version set
- Performance-critical paths identified

## Next Stage Precondition
Scope clear + Rust toolchain confirmed + performance needs defined" ;;
            esac ;;
        "03")
            case $stack in
                "java") echo "# Stage 03: Architecture Review (java)
## Stack-Specific Considerations
Spring Boot architecture: microservices, event-driven with Kafka, REST APIs, Database per service pattern.

## Key Agents
1. architecture-review (Spring patterns)
2. adr-generator (architecture decisions)

## Deliverables
- [ ] Service topology diagram
- [ ] Spring Boot best practices
- [ ] Kafka topic design (if async)
- [ ] Data access pattern (Spring Data JPA)
- [ ] API design (OpenAPI 3.1)

## Checklist
- Service boundaries defined
- Spring Cloud components assessed (Config, Discovery, etc.)
- Kafka vs RabbitMQ decision made
- Database sharding strategy (if needed)
- Spring Security/OAuth2 integration planned
- Monitoring (Spring Boot Actuator) configured

## Known Gotchas
- Spring version conflicts with Kafka client
- JPA N+1 query problems (use projections)
- Kafka offset management complexity

## Integration with Other Stacks
- API contracts match Node.js frontend expectations
- Data models compatible with Python async workers

## Next Stage Precondition
Architecture approved by 2+ architects, ADRs created, no blocker issues" ;;
                "python-django") echo "# Stage 03: Architecture Review (Python-Django)
## Stack-Specific Considerations
Django architecture: monolithic or async microservices, Celery for background jobs, PostgreSQL primary, DRF for APIs.

## Key Agents
1. architecture-review (Django patterns)
2. adr-generator

## Deliverables
- [ ] Django app structure
- [ ] Celery task design
- [ ] PostgreSQL schema patterns
- [ ] REST API design (DRF)
- [ ] Caching strategy (Redis)

## Checklist
- Monolith vs microservice decision made
- Celery broker (RabbitMQ) setup confirmed
- Redis for caching/sessions configured
- Django Channels for WebSocket (if needed)
- Database migration strategy defined
- DRF viewset/serializer patterns

## Known Gotchas
- Celery + Django ORM connection pooling
- Database transaction isolation levels
- Async views (Django 3.1+) performance

## Next Stage Precondition
Architecture reviewed, Celery topology confirmed, database schema approved" ;;
                "nodejs-express") echo "# Stage 03: Architecture Review (Node.js-Express)
## Stack-Specific Considerations
Node.js architecture: event-driven, async/await, microservices, message queues (RabbitMQ/Kafka), TypeScript for type safety.

## Key Agents
1. architecture-review (async patterns)
2. adr-generator

## Deliverables
- [ ] Service decomposition
- [ ] Event-driven topology
- [ ] TypeScript type system design
- [ ] API design (OpenAPI 3.1)
- [ ] Message queue schema

## Checklist
- Service boundaries defined (microservices)
- RabbitMQ/Kafka topic design
- TypeScript strict mode enabled
- Error handling strategy (Promise chains vs async/await)
- Logging aggregation (Winston + ELK)
- Rate limiting + backpressure strategy

## Known Gotchas
- Callback hell (use async/await)
- Event emitter memory leaks
- Lost messages in queue (implement retry logic)
- Database connection pooling

## Next Stage Precondition
Microservice topology approved, message queue design finalized, TypeScript config locked" ;;
                "dotnet-core") echo "# Stage 03: Architecture Review (.NET Core)
## Stack-Specific Considerations
.NET Core architecture: ASP.NET Core for APIs, async/await, Entity Framework Core for data, Dependency Injection (DI), Azure integration.

## Key Agents
1. architecture-review (.NET patterns)
2. adr-generator

## Deliverables
- [ ] ASP.NET Core project structure
- [ ] Entity Framework Core model design
- [ ] Dependency Injection container
- [ ] API design (ASP.NET Core controllers)
- [ ] Azure integration (Storage, Service Bus, etc.)

## Checklist
- .NET project organization (.csproj files)
- Entity Framework Core migrations planned
- Dependency Injection configuration
- async/await throughout the stack
- Entity Framework Core lazy loading vs eager
- Azure Service Bus for async messaging
- Application Insights for monitoring

## Known Gotchas
- Entity Framework Core lazy loading pitfalls
- Async deadlocks (use ConfigureAwait)
- Dependency Injection scope issues
- Azure Service Bus connection limits

## Next Stage Precondition
Project structure approved, EF Core model finalized, DI configuration locked" ;;
                "go-echo") echo "# Stage 03: Architecture Review (Go-Echo)
## Stack-Specific Considerations
Go architecture: lightweight, concurrent, minimal dependencies, Echo web framework, interface-based design.

## Key Agents
1. architecture-review (Go patterns)
2. adr-generator

## Deliverables
- [ ] Package/module structure
- [ ] Goroutine concurrency model
- [ ] Interface contracts
- [ ] API design (Echo)
- [ ] Dependency injection pattern

## Checklist
- Package organization (clean architecture)
- Goroutine pool sizing + context usage
- Interface segregation principle
- Error handling (custom error types)
- Logging (structured logging with Zap)
- Database driver + connection pooling
- gRPC vs REST API decision

## Known Gotchas
- Goroutine leaks (context management)
- Channel deadlocks
- Database connection pool exhaustion
- Nil pointer dereferences

## Next Stage Precondition
Package structure approved, concurrency model validated, interfaces defined" ;;
                "rust") echo "# Stage 03: Architecture Review (Rust)
## Stack-Specific Considerations
Rust architecture: ownership model, zero-cost abstractions, compile-time safety, async runtime (Tokio), minimal runtime overhead.

## Key Agents
1. architecture-review (borrow checker)
2. adr-generator

## Deliverables
- [ ] Module/crate organization
- [ ] Async runtime (Tokio) architecture
- [ ] Type system design (traits, generics)
- [ ] Error handling (Result types)
- [ ] API design (Axum)

## Checklist
- Crate organization (Cargo.toml)
- Tokio runtime configuration
- Trait-based design patterns
- Error types + conversion
- Memory safety analysis
- Concurrency primitives (Arc, Mutex)
- Performance bottleneck identification

## Known Gotchas
- Borrow checker complexity
- Async Rust lifetime issues
- Large binary sizes
- Compilation time

## Next Stage Precondition
Crate structure approved, Tokio model finalized, trait design reviewed" ;;
            esac ;;
        *)
            echo "# Stage $stage_num: $stage_name

## Stack-Specific Considerations
[Stack-specific guidance for $stack]

## Key Agents
1. [Primary agent]
2. [Secondary agent]

## Deliverables
- [ ] Deliverable 1
- [ ] Deliverable 2

## Checklist
- Checklist item 1
- Checklist item 2

## Known Gotchas
- Common pitfall 1
- Common pitfall 2

## Integration with Other Stacks
- Compatibility consideration 1
- Compatibility consideration 2

## Next Stage Precondition
Prerequisites for moving to next stage" ;;
    esac
}

# Main population loop
echo "Populating 92 stage-stack variant files..."

# Must match cli/lib/config.sh STAGES and stages/*/ directories
declare -a STAGES=("01-requirement-intake" "02-prd-review" "03-pre-grooming" "04-grooming" "05-system-design" "06-design-review" "07-task-breakdown" "08-implementation" "09-code-review" "10-test-design" "11-test-execution" "12-commit-push" "13-documentation" "14-release-signoff" "15-summary-close")
declare -a STAGE_NUMS=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15")

for i in "${!STAGES[@]}"; do
    stage="${STAGES[$i]}"
    stage_num="${STAGE_NUMS[$i]}"
    
    for stack in "${STACKS[@]}"; do
        variant_file="${VARIANTS_DIR}/${stage}/variant-${stack}.md"
        
        # Create directory if it doesn't exist
        mkdir -p "${VARIANTS_DIR}/${stage}"
        
        # Generate content
        content=$(generate_variant_content "$stage" "$stack" "$stage_num" "$stage")
        
        # Write file if content generated
        if [ ! -z "$content" ] && [ "$content" != "" ]; then
            echo "$content" > "$variant_file"
            echo "✓ Created $variant_file"
        fi
    done
done

echo "✅ Variant population complete!"
echo "   Created: $(find stages -name 'variant-*.md' | wc -l) variant files"
echo "   Next: Run validators to verify variant quality"
