# Multi-Tenancy

Nimbus is a multi-tenant application where each workspace operates as an isolated tenant. All tenants share a single PostgreSQL database, and isolation is enforced at both the application layer and the database layer.

## Tenant Identification

Each tenant is identified by a UUID stored as `tenant_id` across all tenant-scoped tables. When a user authenticates, their JWT token includes the `tenantId` claim for the workspace they are currently accessing. Users who belong to multiple workspaces receive a distinct token per workspace.

## Tenant Context Middleware

An Express middleware runs early in the request pipeline and establishes the tenant context:

1. Extracts `tenantId` from the JWT claims.
2. Validates that the authenticated user is a member of that workspace.
3. Stores the `tenantId` in Node.js `AsyncLocalStorage` so it is available throughout the request lifecycle without explicit parameter passing.

```typescript
const tenantContext = new AsyncLocalStorage<{ tenantId: string }>();

function tenantMiddleware(req, res, next) {
  const tenantId = req.auth.tenantId;
  tenantContext.run({ tenantId }, () => next());
}
```

## Repository-Level Scoping

Every repository method automatically appends a `WHERE tenant_id = ?` clause by reading the tenant ID from async local storage. This is implemented in a base repository class that all entity repositories extend:

```typescript
class BaseRepository {
  protected query() {
    const { tenantId } = tenantContext.getStore();
    return knex(this.tableName).where({ tenant_id: tenantId });
  }
}
```

This approach makes it impossible for a developer to accidentally write an unscoped query through the repository layer.

## Row-Level Security

As a defense-in-depth measure, PostgreSQL row-level security (RLS) policies enforce tenant isolation at the database level. Even if application code bypasses the repository layer and executes raw SQL, the RLS policy prevents access to rows belonging to other tenants.

```sql
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON tasks
  USING (tenant_id = current_setting('app.tenant_id')::uuid);
```

The tenant context middleware sets the `app.tenant_id` session variable on each database connection before executing queries.

## Cross-Tenant Query Prevention

An integration test suite specifically verifies tenant isolation by:

1. Creating data in tenant A.
2. Switching to tenant B's context.
3. Asserting that queries return zero rows and mutations raise `TenantError`.

These tests run on every CI build and cover all repository methods.

## Admin Operations

Internal admin tools need to query across tenants for support and analytics purposes. These operations use a dedicated database role that bypasses RLS and are restricted to authenticated admin sessions with audit logging enabled.

## See Also

- [Database Schema](./database/schema.md) - Tenant ID column placement
- [Auth Service](./services/auth.md) - JWT tenant claims
- [Data Flow](./data-flow.md) - Tenant middleware in the request pipeline

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Tenant isolation strategy changes or RLS policies are modified -->
