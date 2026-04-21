# Database Standards (Java TEJ)

## Query Standards
- **All queries parameterized** (no string concatenation)
- PreparedStatement for all dynamic queries
- Use repositories for data access abstraction

## JPA Repositories
Pattern:
```java
public interface UserRepository extends JpaRepository<User, Long> {
  Optional<User> findByEmail(String email);
  List<User> findByStatusAndCreatedAfter(String status, LocalDateTime date);
}
```

## Database Migrations
- **Tool**: Liquibase or Flyway (organization choice)
- **Location**: `src/main/resources/db/migration/`
- **Naming**: `V###__description.sql` (Flyway) or `v###-description.xml` (Liquibase)
- **Example**: `V001__create_users_table.sql`

## Migration Checklist
- Schema: Describe all columns and constraints
- Indexes: List all index names and columns
- Foreign keys: Explicit FK constraints with CASCADE/RESTRICT
- Rollback: Include down migration (Liquibase) or undo script

## Index Requirements
Indexes required for:
- Primary keys (auto)
- Foreign keys
- Frequently queried columns
- Columns in WHERE clauses
- Columns in JOIN conditions

Example:
```sql
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_audit_created_at ON audit(created_at DESC);
```

## Connection Management
- Use connection pools (HikariCP standard)
- Configuration via application.properties:
  ```properties
  spring.datasource.hikari.maximum-pool-size=20
  spring.datasource.hikari.minimum-idle=5
  ```

---
**Last Updated**: 2026-04-10  
**Stack**: Java 17 TEJ/RestExpress
