# Event Sourcing

Nimbus uses event sourcing for the Task and Project aggregates to maintain a complete audit trail, support undo operations, and enable real-time projections. Events are the source of truth for these aggregates; the current state is derived by replaying events.

## Event Store Design

Events are stored in a PostgreSQL `events` table with the following schema:

```sql
CREATE TABLE events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL,
  aggregate_type VARCHAR(50) NOT NULL,   -- 'Task', 'Project'
  aggregate_id  UUID NOT NULL,
  event_type    VARCHAR(100) NOT NULL,   -- 'TaskCreated', 'TaskStatusChanged'
  payload       JSONB NOT NULL,
  metadata      JSONB NOT NULL,          -- userId, correlationId, timestamp
  version       INTEGER NOT NULL,        -- aggregate version for optimistic concurrency
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (aggregate_id, version)
);
```

The `(aggregate_id, version)` unique constraint enforces optimistic concurrency. If two concurrent writes produce the same version number, the second write fails and must retry after re-reading the aggregate.

Events are append-only. They are never updated or deleted (except during GDPR erasure, which is handled by a separate process -- see [GDPR](gdpr.md)).

## Event Types

Task aggregate events:

| Event | Payload |
|-------|---------|
| `TaskCreated` | Full initial task data |
| `TaskStatusChanged` | `{ from: Status, to: Status }` |
| `TaskReassigned` | `{ from: UserId, to: UserId }` |
| `TaskPriorityChanged` | `{ from: Priority, to: Priority }` |
| `TaskCompleted` | `{ completedBy: UserId }` |
| `SubtaskAdded` | `{ subtaskId, title }` |
| `CommentAdded` | `{ commentId, authorId, body }` |

## Event Replay

To reconstruct the current state of an aggregate, all events for that aggregate are loaded in version order and applied sequentially:

```ts
function rehydrate(events: DomainEvent[]): Task {
  return events.reduce((task, event) => task.apply(event), Task.empty());
}
```

Replay is used during aggregate loading and for debugging historical state. The `replay` CLI tool can reconstruct the state of any aggregate at any point in time: `nimbus replay task task_abc123 --at 2026-03-01`.

## Snapshots

For aggregates with many events (100+), loading all events becomes slow. Snapshots store a serialized aggregate state at a specific version:

```sql
CREATE TABLE snapshots (
  aggregate_id   UUID PRIMARY KEY,
  version        INTEGER NOT NULL,
  state          JSONB NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

When loading an aggregate, the system loads the latest snapshot and replays only events after the snapshot version. Snapshots are created automatically when an aggregate exceeds 100 events since its last snapshot.

## Projections

Projections transform the event stream into read-optimized views:

- **Task list projection**: Maintains a denormalized `tasks_view` table for fast list queries with filtering and sorting.
- **Activity feed projection**: Builds a chronological activity feed per project from task and comment events.
- **Analytics projection**: Aggregates task completion rates, cycle times, and velocity into ClickHouse tables for reporting.

Projections run as background consumers of the event stream. They can be rebuilt from scratch by replaying all events, which is useful after schema changes.

## Eventual Consistency

Projections are eventually consistent with the event store. The typical lag is under 100 milliseconds. The system handles this by:

- Returning the write result directly after a mutation (not reading from a projection)
- Using optimistic updates on the frontend so the UI reflects changes immediately
- Showing a subtle "syncing" indicator if a projection query returns data older than the last known write

## See Also

- [Data Models](models.md) for aggregate design and domain events
- [Caching Strategies](caching-strategies.md) for cache invalidation driven by events
- [Reporting](reporting.md) for analytics projections in ClickHouse

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: event store schema changes or new aggregate types adopt event sourcing -->
