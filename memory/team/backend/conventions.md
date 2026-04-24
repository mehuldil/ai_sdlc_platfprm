# Backend Team Conventions

**Team**: Backend  
**Last Updated**: 2026-04-10  
**Governed By**: stacks/java/conventions.md  

---

## Code Style
- Language: Java 17
- Framework: RestExpress (TEJ)
- Build: Gradle Kotlin DSL
- Package naming: `com.example.app.{service}.{layer}`

## Naming Standards
- Classes: PascalCase
- Methods: camelCase
- Constants: UPPER_SNAKE_CASE
- Packages: lowercase, dot-separated

## Error Handling
- Base: ApplicationServiceException
- No raw RuntimeException
- All errors logged with SLF4J

## Database
- Parameterized SQL only (no string concat)
- JPA repositories for abstraction
- Liquibase migrations (src/main/resources/db/migration/)

## Testing
- Unit: JUnit4 + Mockito
- Coverage: ≥80%
- Integration: TestContainers for DB/Kafka

---

## PR/Code Review Checklist
- [ ] SQL parameterized?
- [ ] SLF4J logging (no System.out)?
- [ ] Try-with-resources for I/O?
- [ ] ApplicationServiceException (not raw Exception)?
- [ ] Coverage ≥80%?
- [ ] Linting passes?

---

**See Also**: stacks/java/ directory for detailed standards
