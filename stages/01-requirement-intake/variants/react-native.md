# Variant Template

**Use this template to create stack-specific variants for any stage.**

---

## Instructions

1. Copy this file to: `stages/XX-name/variants/{STACK_NAME}.md`
   - Replace `{STACK_NAME}` with variant name from `STACK_VARIANT_MAP` in cli/sdlc.sh
   - Example: `java-backend.md`, `react-native.md`, `swift-ios.md`

2. Fill in sections below with stack-specific guidance

3. Reference agents that are relevant to this stack for this stage

4. Test: `sdlc run XX --stack=<stack>` should load variant

---

## Template

```markdown
# react-native Variant: Stage 01

**Stage**: requirement-intake  
**Stack**: react-native  
**Variant Owner**: {PRIMARY_ROLE} (e.g., Backend, Frontend, QA)  
**Token Budget**: 5000  
**Updated**: 2026-04-11  

## Overview

[2-3 sentences on how this stack differs in this stage]

**Example**: 
Java Backend (Stage 08 Implementation) differs from React Native because:
- Java requires OpenAPI contract first (FE waits on APIs)
- Kafka integration adds async complexity not present in mobile
- Database migrations must be coordinated with pre-prod deployment

## Key Agents for This Stack

Ranked by execution order:

| Agent | Purpose | Invocation |
|-------|---------|-----------|
| agent-1 | What it does | `sdlc agent invoke <agent-id> --role=<role>` |
| agent-2 | What it does | `sdlc agent invoke <agent-id> --role=<role>` |

**Example for Java Stage 08**:
| Agent | Purpose | Invocation |
|-------|---------|-----------|
| api-contract | Define OpenAPI spec from design | `sdlc agent invoke api-contract --role=backend --stage=08` |
| be-developer-agent | Implement Java services | `sdlc agent invoke be-developer-agent --role=backend --stage=08` |
| dependency-resolver | Map Kafka + service deps | `sdlc agent invoke dependency-resolver --role=backend --stage=08` |

## Stack-Specific Checklist

Verify before moving to next stage:

- [ ] Item 1
- [ ] Item 2
- [ ] Item 3

**Example for Java Stage 08**:
- [ ] OpenAPI spec published (api-contract output)
- [ ] Gradle build succeeds with >80% test coverage
- [ ] Kafka topics provisioned (ops coordination)
- [ ] DB migrations generated and tested
- [ ] Logging/metrics instrumentation in place

## Deliverables for This Stage

| Deliverable | Format | Owner | Blocks Next Stage? |
|-------------|--------|-------|-------------------|
| Deliverable 1 | Format | Role | Yes/No |
| Deliverable 2 | Format | Role | Yes/No |

**Example for Java Stage 08**:
| Deliverable | Format | Owner | Blocks Next Stage? |
|-------------|--------|-------|-------------------|
| Source code | Merged to main | Backend | Yes (G6 gate) |
| OpenAPI spec | YAML in repo | Backend | Yes (G6 gate) |
| DB migrations | SQL files | Backend | Yes (pre-prod deploy) |
| Unit tests | JUnit 5 | Backend | Yes (>80% coverage) |

## Known Gotchas for This Stack

Pitfalls specific to this stack + stage:

- **Gotcha 1**: Explanation + how to avoid
- **Gotcha 2**: Explanation + how to avoid

**Example for Java Stage 08**:
- **Async Kafka bugs**: Java async patterns can hide race conditions. Use `@ExtendWith(MockitoExtension.class)` and `await().atMost(Duration.ofSeconds(5))` for timing-sensitive tests.
- **DB lock timeouts**: Long-running transactions block CI. Add explicit transaction boundaries in code. Verify lock wait times in pre-prod.
- **OpenAPI breaking changes**: Adding required fields breaks API contract. Use deprecation warnings first, only make required in next major version.

## Integration with Other Stacks

If this stage involves cross-stack coordination:

| Other Stack | How They Interact | Blocker? |
|-------------|-------------------|----------|
| Stack A | Describes interaction | Yes/No |
| Stack B | Describes interaction | Yes/No |

**Example for Java Stage 08**:
| Other Stack | How They Interact | Blocker? |
|-------------|-------------------|----------|
| React Native | FE waits on OpenAPI spec before implementing client | Yes (FE can't start stage 08) |
| Swift iOS | Same as React Native | Yes |
| JMeter | BE shares performance baseline | No (parallel) |

## Next Stage Preconditions

Before moving to Stage {XX+1}, verify:

- [ ] Precondition 1
- [ ] Precondition 2

**Example for Java Stage 08 → Stage 09 (Code Review)**:
- [ ] All commits pushed to main + merged
- [ ] CI/CD green (no failing tests)
- [ ] Coverage report ≥80%
- [ ] Code review checklist completed (2+ approvals)
- [ ] OpenAPI spec validated in sandbox

## References

Links to relevant docs for this stack + stage:

- Link 1
- Link 2

**Example for Java Stage 08**:
- [Java TEJ Stack Guide](../../stacks/java/conventions.md)
- [OpenAPI 3.0 Spec](https://swagger.io/specification/)
- [JUnit 5 Documentation](https://junit.org/junit5/)
- [Gradle Best Practices](https://gradle.org/guides/)
- [Kafka Producer Configuration](https://kafka.apache.org/documentation/#producerconfigs)

## Questions?

Contact: [TBD](mailto:owner@example.com)
```

---

## Variant File Naming

Use variant names from **cli/sdlc.sh** `STACK_VARIANT_MAP`:

```bash
["java"]="java-backend"
["kotlin-android"]="kotlin-android"
["swift-ios"]="swift-ios"
["react-native"]="react-native"
["jmeter"]="jmeter-perf"
["figma-design"]="figma-design"
```

So create files as:
- `java-backend.md`
- `kotlin-android.md`
- `swift-ios.md`
- `react-native.md`
- `jmeter-perf.md`
- `figma-design.md`

---

## Minimal Example

If stack has no special considerations for a stage, minimal variant:

```markdown
# Java Backend: Stage 12 Commit/Push

**Stage**: 12-commit-push  
**Stack**: java  
**Token Budget**: 500 tokens  

## Overview

Java commits to main branch with standard Maven/Gradle conventions.

## Key Agents

| Agent | Invocation |
|-------|-----------|
| code-review | `sdlc agent invoke code-review --role=backend --stage=12` |

## Checklist

- [ ] Code formatting: `./gradlew spotlessApply`
- [ ] Commit message: `feat: <description> (#<issue>)`
- [ ] Branch deleted after merge

## Next Stage Preconditions

- [ ] CI/CD green
- [ ] All tests passing
```

---

## Generating All Variants

To create variant files for all stacks × all stages:

```bash
# From platform root
for stage_dir in stages/*/; do
  stage_name=$(basename "$stage_dir")
  stage_num="${stage_name%%-*}"
  stage_full="${stage_name#*-}"
  
  for stack in java-backend kotlin-android swift-ios react-native jmeter-perf figma-design; do
    variant_file="$stage_dir/variants/${stack}.md"
    
    # Skip if already exists
    [[ -f "$variant_file" ]] && continue
    
    # Create from template
    cat VARIANT_TEMPLATE.md | \
      sed "s/01/$stage_num/g" | \
      sed "s/requirement-intake/$stage_full/g" | \
      sed "s/react-native/$stack/g" | \
      sed "s/TBD/[TBD]/g" | \
      sed "s/5000/5000/g" \
      > "$variant_file"
    
    echo "Created: $variant_file"
  done
done
```

---

## Directory Structure After Variants Created

```
stages/
├── 01-requirement-intake/
│   ├── STAGE.md
│   ├── ROUTING.md
│   └── variants/
│       ├── java-backend.md ✓
│       ├── kotlin-android.md ✓
│       ├── swift-ios.md ✓
│       ├── react-native.md ✓
│       ├── jmeter-perf.md ✓
│       └── figma-design.md ✓
├── 02-prd-review/
│   ├── STAGE.md
│   └── variants/
│       ├── java-backend.md ✓
│       ├── ... (all 6)
├── ... (13 more stages, all with 6 variants each)
```

Total: 15 stages × 6 variants = 90 variant files

---

## See Also

- **STAGE.md Template**: `stages/XX-name/STAGE.md`
- **Stack Conventions**: `stacks/{stack}/conventions.md`
- **Agent Capability Matrix**: `agents/CAPABILITY_MATRIX.md`
