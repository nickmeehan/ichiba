# Database Conventions

Nimbus uses PostgreSQL 16 with Prisma ORM. This guide covers naming conventions for tables, columns, indexes, and migrations.

## Table Naming

Tables use **snake_case** and **plural** nouns:

```sql
tasks
projects
project_members
task_comments
billing_invoices
```

Join tables are named by combining both table names in alphabetical order: `project_members` (not `member_projects`).

## Column Types

Standard column types used across the schema:

| Concept | PostgreSQL type | Prisma type | Notes |
|---------|---------------|-------------|-------|
| Primary key | `TEXT` | `String @id @default(cuid())` | CUID for distributed uniqueness |
| Foreign key | `TEXT` | `String` | References another table's PK |
| Tenant ID | `TEXT` | `String` | Present on every tenant-scoped table |
| Timestamps | `TIMESTAMPTZ` | `DateTime` | Always with timezone |
| Status | `TEXT` | `String` (enum in app) | Stored as text, validated in app |
| Money | `INTEGER` | `Int` | Stored as cents to avoid floating point |
| JSON data | `JSONB` | `Json` | Use sparingly; prefer normalized columns |
| Boolean | `BOOLEAN` | `Boolean` | Default to `false`, never nullable |

## Standard Columns

Every tenant-scoped table includes these columns:

```prisma
model Task {
  id        String   @id @default(cuid())
  tenantId  String   @map("tenant_id")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  tenant Tenant @relation(fields: [tenantId], references: [id])

  @@map("tasks")
}
```

`createdAt` and `updatedAt` are present on every table. Soft deletes use a `deletedAt` column (`DateTime?`).

## Foreign Key Naming

Foreign key columns follow the pattern `<referenced_table_singular>_id`:

```
tenant_id    → references tenants.id
project_id   → references projects.id
assignee_id  → references users.id (alias for clarity)
```

Prisma relation fields are named without the `_id` suffix: `tenant`, `project`, `assignee`.

## Migration Naming

Prisma migrations are named with a timestamp prefix and a descriptive slug:

```
20260315120000_add_task_dependencies
20260310090000_create_billing_invoices
20260308140000_add_index_tasks_tenant_status
```

The slug should describe what the migration does, not why. Keep it under 60 characters.

## Index Naming

Indexes follow the pattern `idx_<table>_<columns>`:

```prisma
@@index([tenantId, status], map: "idx_tasks_tenant_id_status")
@@index([tenantId, projectId, createdAt], map: "idx_tasks_tenant_id_project_id_created_at")
@@unique([tenantId, email], map: "uniq_users_tenant_id_email")
```

Every table must have an index on `tenantId` (or a composite index starting with `tenantId`) since every query is tenant-scoped.

## Query Performance Rules

- Every `WHERE` clause must include `tenant_id` (enforced by Prisma middleware).
- Add composite indexes for frequently used query patterns.
- Avoid `SELECT *` — use Prisma's `select` to fetch only needed columns.
- Use cursor-based pagination for large datasets (not `OFFSET`).
- Test query plans with `EXPLAIN ANALYZE` for queries touching > 10K rows.

## See Also

- [Data Migration](../guides/data-migration.md) — migration playbook
- [Naming Conventions](naming.md) — general naming rules
- [Performance Profiling](../guides/performance-profiling.md) — query analysis

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Prisma version, PostgreSQL version, or database schema conventions change -->
