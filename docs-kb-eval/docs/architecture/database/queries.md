# Query Patterns

This document describes the query patterns used in the Nimbus backend, including the repository pattern, common query techniques, and strategies for avoiding performance pitfalls.

## Repository Pattern

All database access goes through repository classes that extend `BaseRepository`. The base class automatically scopes queries to the current tenant and provides common CRUD methods:

```typescript
class TaskRepository extends BaseRepository<Task> {
  constructor() {
    super('tasks');
  }

  async findByProject(projectId: string): Promise<Task[]> {
    return this.query()
      .where({ project_id: projectId })
      .orderBy('position', 'asc');
  }
}
```

The `this.query()` method returns a Knex query builder pre-filtered by `tenant_id`, so repository methods never need to manually add tenant conditions.

## Query Builder Usage

Nimbus uses the Knex.js query builder exclusively for database access. Raw SQL is avoided except in migrations and performance-critical queries that cannot be expressed through the builder. When raw SQL is necessary, it must include the tenant_id filter explicitly.

## N+1 Prevention

The most common performance issue in data access layers is the N+1 query problem. Nimbus prevents this through:

1. **Eager loading**: Repository methods accept an `include` option that joins related tables:
   ```typescript
   const tasks = await taskRepo.findByProject(projectId, {
     include: ['assignee', 'comments'],
   });
   ```

2. **Batch loading**: When joins are not practical, a DataLoader pattern batches individual lookups into a single `WHERE id IN (...)` query per request cycle.

3. **Code review rule**: PRs that add new database queries must demonstrate that list endpoints do not produce N+1 patterns.

## Cursor Pagination

List endpoints use cursor-based pagination instead of offset pagination. The cursor encodes the sort field value and the row ID:

```typescript
async findPaginated(cursor?: string, limit = 50): Promise<PaginatedResult<Task>> {
  const query = this.query().orderBy('created_at', 'desc').orderBy('id', 'desc').limit(limit + 1);

  if (cursor) {
    const { createdAt, id } = decodeCursor(cursor);
    query.where(function () {
      this.where('created_at', '<', createdAt)
        .orWhere(function () {
          this.where('created_at', '=', createdAt).andWhere('id', '<', id);
        });
    });
  }

  const rows = await query;
  const hasMore = rows.length > limit;
  const items = rows.slice(0, limit);
  const nextCursor = hasMore ? encodeCursor(items[items.length - 1]) : null;

  return { items, nextCursor, hasMore };
}
```

This approach provides stable pagination even when new rows are inserted between page fetches.

## Full-Text Search Queries

PostgreSQL's built-in `tsvector` and `tsquery` types are used for simple text searches within a project. For cross-entity full-text search, the Elasticsearch-backed search service is used instead.

```typescript
async searchInProject(projectId: string, searchTerm: string): Promise<Task[]> {
  return this.query()
    .where({ project_id: projectId })
    .whereRaw("search_vector @@ plainto_tsquery('english', ?)", [searchTerm])
    .orderByRaw("ts_rank(search_vector, plainto_tsquery('english', ?)) DESC", [searchTerm]);
}
```

## See Also

- [Schema](./schema.md) - Table definitions used in queries
- [Indexing](./indexing.md) - Indexes that support these query patterns
- [Search Service](../services/search.md) - Elasticsearch for full-text search

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Query patterns change or new pagination strategies are adopted -->
