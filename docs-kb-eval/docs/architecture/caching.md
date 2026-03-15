# Caching

Nimbus uses Redis as a centralized cache layer to reduce database load and improve response times for frequently accessed data. The caching strategy is designed around the cache-aside pattern with event-driven invalidation.

## Cache-Aside Pattern

The application follows a read-through cache-aside approach:

1. **Read**: Check Redis for the cached value. If present (cache hit), return it directly.
2. **Miss**: On a cache miss, query PostgreSQL, store the result in Redis with a TTL, and return the value.
3. **Write**: When data is modified, the service layer emits a domain event. An event handler invalidates the relevant cache keys.

This pattern ensures that cache invalidation is handled consistently through the event system rather than scattered across individual service methods.

## TTLs by Entity Type

| Entity         | Cache Key Pattern              | TTL      | Rationale                                      |
|---------------|-------------------------------|----------|-------------------------------------------------|
| Workspace     | `ws:{tenantId}`               | 1 hour   | Rarely changes after initial setup               |
| User Profile  | `user:{userId}`               | 30 min   | Updated occasionally (name, avatar)              |
| Project Config| `proj:{projectId}:config`     | 15 min   | Board columns and settings change infrequently   |
| Task          | `task:{taskId}`               | 5 min    | Frequently updated, short TTL limits staleness   |
| Permission Set| `perms:{userId}:{tenantId}`   | 10 min   | Role changes are rare but security-sensitive     |
| Feature Flags | `flags:{tenantId}`            | 2 min    | Must reflect changes quickly for rollouts        |

## Cache Invalidation

Invalidation is triggered by domain events. When a `task.updated` event fires, the cache handler deletes the corresponding `task:{taskId}` key. For entities that appear in list views, the handler also invalidates related collection keys using a wildcard pattern (e.g., `proj:{projectId}:tasks:*`).

### Invalidation Examples

```
Event: task.updated     → delete task:{taskId}
Event: task.moved       → delete task:{taskId}, proj:{projectId}:board:*
Event: member.removed   → delete perms:{userId}:{tenantId}
Event: workspace.updated → delete ws:{tenantId}
```

## Cache Warming

During deployment, a startup script pre-populates the cache with high-traffic data:

- Active workspace configurations
- Permission sets for currently online users
- Feature flag states for all tenants

This prevents a thundering herd of cache misses immediately after a deploy when all pods restart simultaneously.

## Cache Key Namespacing

All cache keys are prefixed with the environment name (`prod:`, `staging:`) to allow multiple environments to share a Redis cluster during development without key collisions.

## Monitoring

Cache hit rate and miss rate are tracked as Prometheus metrics. An alert fires if the hit rate drops below 80% over a 10-minute window, which may indicate an invalidation bug or an unexpected traffic pattern.

## See Also

- [Data Flow](./data-flow.md) - Where caching fits in the request lifecycle
- [Event-Driven Architecture](./event-driven.md) - Event-based invalidation mechanism
- [Redis / Rate Limiting](./services/rate-limiting.md) - Other Redis usage patterns

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New cached entity types are added or TTL values are adjusted -->
