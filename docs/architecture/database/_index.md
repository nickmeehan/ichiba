# Database

This section documents the PostgreSQL database architecture for the Nimbus platform, covering schema design, migration practices, query patterns, and operational concerns like replication and backups.

## Contents

### [Schema](./schema.md)
When you need to understand the table structure, column types, relationships between entities, or how tenant isolation is implemented at the schema level.

### [Migrations](./migrations.md)
When you are adding or modifying database tables, need to understand the migration naming conventions, or want to perform a zero-downtime schema change.

### [Queries](./queries.md)
When you are writing new repository methods, optimizing slow queries, implementing pagination, or need to avoid common pitfalls like N+1 queries.

### [Indexing](./indexing.md)
When you are adding indexes to improve query performance, analyzing slow query logs, or need to understand the indexing strategy for multi-tenant tables.

### [Replication](./replication.md)
When you need to understand how read replicas are used, configure connection routing, or plan for failover scenarios.

### [Sharding](./sharding.md)
When you need to understand the future sharding plan, evaluate whether the current single-database architecture will support growth, or prepare for tenant-based sharding.

### [Backups](./backups.md)
When you need to understand the backup schedule, perform a point-in-time recovery, or verify that backup restore procedures work correctly.

## See Also

- [Multi-Tenancy](../multi-tenancy.md) - Tenant isolation strategy using tenant_id columns
- [System Design](../system-design.md) - Database within the overall architecture
- [Data Flow](../data-flow.md) - How queries flow through the repository layer

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New database-related documentation sections are added -->
