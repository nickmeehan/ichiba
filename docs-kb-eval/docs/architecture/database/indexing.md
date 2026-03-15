# Database Indexing

This document describes the indexing strategy for the Nimbus PostgreSQL database. Indexes are designed to support the multi-tenant query patterns and common access paths used by the application.

## Composite Indexes for Multi-Tenant Queries

Every query in Nimbus is scoped to a single tenant. Therefore, most indexes lead with `tenant_id` to narrow the search space before filtering on other columns:

```sql
CREATE INDEX idx_tasks_tenant_project ON tasks (tenant_id, project_id);
CREATE INDEX idx_tasks_tenant_assignee ON tasks (tenant_id, assignee_id);
CREATE INDEX idx_tasks_tenant_sprint ON tasks (tenant_id, sprint_id);
CREATE INDEX idx_tasks_tenant_status ON tasks (tenant_id, project_id, status);
CREATE INDEX idx_comments_tenant_task ON comments (tenant_id, task_id, created_at);
```

The `tenant_id` prefix ensures that the index is efficient even for tenants with small datasets, because PostgreSQL can skip directly to the relevant portion of the B-tree.

## Partial Indexes

Partial indexes cover queries that filter on a specific condition, reducing index size and improving write performance:

```sql
-- Only index open tasks for the "my tasks" view
CREATE INDEX idx_tasks_open_assigned ON tasks (tenant_id, assignee_id)
  WHERE status NOT IN ('done', 'archived');

-- Only index active sprints for the board view
CREATE INDEX idx_sprints_active ON sprints (tenant_id, project_id)
  WHERE status = 'active';
```

## GIN Indexes for JSONB

Custom field values are stored in a JSONB column on the tasks table. A GIN index supports efficient queries on custom field values:

```sql
CREATE INDEX idx_tasks_custom_fields ON tasks USING GIN (custom_fields jsonb_path_ops);
```

This enables queries like:

```sql
SELECT * FROM tasks
WHERE tenant_id = $1
  AND custom_fields @> '{"severity": "critical"}'::jsonb;
```

## Full-Text Search Indexes

A GIN index on the `search_vector` tsvector column supports in-project text search:

```sql
CREATE INDEX idx_tasks_search ON tasks USING GIN (search_vector);
```

The `search_vector` column is maintained by a trigger that concatenates the task title, description, and comment bodies on insert and update.

## Index Monitoring

Slow queries are identified through `pg_stat_statements` and the PostgreSQL slow query log (threshold: 100ms). The operations team reviews the top slow queries weekly and adds or modifies indexes as needed.

Key metrics monitored:
- **Index hit ratio**: Should stay above 99%. A drop indicates missing indexes.
- **Index size**: Tracked per table to catch bloat from unused or redundant indexes.
- **Sequential scans**: Tables with frequent sequential scans on large tables are candidates for new indexes.

Unused indexes are identified via `pg_stat_user_indexes` (where `idx_scan = 0` over a 30-day window) and dropped to reduce write overhead.

## See Also

- [Schema](./schema.md) - Table definitions the indexes reference
- [Queries](./queries.md) - Query patterns the indexes support
- [Monitoring](../infrastructure/monitoring.md) - Database performance dashboards

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New indexes are added or indexing strategy changes -->
