# Caching Strategies

Nimbus uses Redis as its primary cache layer, with caching applied at the API, query, and computed-data levels. The caching strategy balances data freshness against query performance, with different approaches depending on the data's volatility and tenant sensitivity.

## Cache-Aside Pattern

The default caching pattern for read-heavy data. The application checks the cache first; on a miss, it queries the database and populates the cache:

```ts
async function getProject(projectId: string): Promise<Project> {
  const cacheKey = `project:${projectId}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const project = await db.projects.findById(projectId);
  await redis.setex(cacheKey, TTL.PROJECT, JSON.stringify(project));
  return project;
}
```

Cache-aside is used for:
- Project metadata (TTL: 5 minutes)
- User profiles (TTL: 10 minutes)
- Tenant configuration and feature flags (TTL: 2 minutes)
- Permission lookups (TTL: 1 minute)

## Write-Through Caching

For data that is read immediately after writes, the cache is updated synchronously during the write operation:

```ts
async function updateProject(projectId: string, data: ProjectUpdate): Promise<Project> {
  const project = await db.projects.update(projectId, data);
  await redis.setex(`project:${projectId}`, TTL.PROJECT, JSON.stringify(project));
  return project;
}
```

Write-through is used for:
- Task status changes (users expect to see the change immediately)
- User preference updates
- Tenant settings

## Cache Invalidation Events

When data changes, the service publishes an invalidation event to the `cache-invalidation` Redis channel. Other service instances subscribe and clear their local caches:

| Event | Invalidated Keys |
|-------|-----------------|
| `project:updated` | `project:{id}`, `projects:list:{tenantId}:*` |
| `task:updated` | `task:{id}`, `tasks:list:{projectId}:*` |
| `user:updated` | `user:{id}`, `team:{tenantId}:members` |
| `tenant:settings:updated` | `tenant:{id}:settings`, `tenant:{id}:features` |

Pattern-based invalidation uses Redis `SCAN` with glob patterns rather than `KEYS` to avoid blocking the Redis instance.

## TTL Policies

| Data Type | TTL | Rationale |
|-----------|-----|-----------|
| Feature flags | 2 minutes | Must reflect changes quickly |
| Permissions | 1 minute | Security-sensitive, short TTL |
| Project metadata | 5 minutes | Moderate change frequency |
| User profiles | 10 minutes | Rarely change |
| Report data | 1 hour | Expensive to compute, acceptable staleness |
| Static config | 30 minutes | Changes only on deploy |

## Cache Warming

On application startup and after deploys, the cache warming job pre-populates frequently accessed keys:

1. Active tenant configurations
2. Feature flag sets for all tenants
3. The 100 most recently accessed projects

Cache warming runs as a background job and completes within 30 seconds for a typical deployment.

## Tenant Isolation

All cache keys include the tenant ID as a prefix to prevent cross-tenant data leakage: `tenant:{tenantId}:project:{projectId}`. The cache client wrapper enforces this automatically; it is impossible to read or write a cache key without a tenant context.

## See Also

- [Data Models](models.md) for what data is cached and cache key structure
- [Event Sourcing](event-sourcing.md) for event-driven cache invalidation
- [Performance](../frontend/performance.md) for client-side caching with React Query

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Redis infrastructure changes or new cache tiers are introduced -->
