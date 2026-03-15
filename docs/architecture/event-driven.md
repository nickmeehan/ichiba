# Event-Driven Architecture

Nimbus uses a domain event system to decouple core business operations from their side effects. When a significant action occurs, the responsible service emits an event, and independent handlers react to it asynchronously.

## Event Bus Implementation

The event bus is built on Redis pub/sub for real-time event distribution and BullMQ for durable, retryable event processing. Events are published to both channels simultaneously:

- **Redis pub/sub**: For latency-sensitive handlers like WebSocket broadcasts and cache invalidation. These are fire-and-forget with no delivery guarantee.
- **BullMQ queues**: For handlers that require at-least-once delivery, such as sending notifications, updating search indexes, and dispatching outbound webhooks.

## Domain Events

Each event has a type, a timestamp, and a payload containing the relevant entity data and metadata:

```typescript
interface DomainEvent {
  type: string;
  tenantId: string;
  actorId: string;
  timestamp: string;
  payload: Record<string, unknown>;
}
```

### Core Event Types

| Event                | Trigger                            | Typical Handlers                        |
|---------------------|------------------------------------|-----------------------------------------|
| `task.created`      | New task is created                | Search index, audit log, webhooks        |
| `task.assigned`     | Task assignee changes              | Notification, audit log                  |
| `task.moved`        | Task moves to a different column   | WebSocket broadcast, audit log           |
| `task.completed`    | Task marked as done                | Analytics, sprint metrics, notification  |
| `comment.added`     | New comment on a task              | Notification, search index               |
| `sprint.started`    | Sprint is activated                | Analytics, notification                  |
| `sprint.completed`  | Sprint is closed                   | Velocity calculation, report generation  |
| `member.invited`    | User invited to workspace          | Email invitation, audit log              |
| `member.removed`    | User removed from workspace        | Cache invalidation, session revocation   |

## Event Handlers

Handlers are registered in a central handler registry at application startup. Each handler specifies which event types it subscribes to and whether it requires durable delivery (BullMQ) or can tolerate message loss (pub/sub).

```typescript
eventBus.on('task.assigned', {
  handler: notifyAssignee,
  durable: true,
  retries: 3,
});
```

## Saga Pattern

Multi-step operations that span several services use a lightweight saga pattern. Each step emits a completion event that triggers the next step. If any step fails, compensating events undo the previous steps.

**Example: Task Archival Saga**

1. `task.archive_requested` - Marks the task as archiving.
2. `task.attachments_archived` - Moves attachments to cold storage.
3. `task.search_deindexed` - Removes the task from the search index.
4. `task.archived` - Final state, task is fully archived.

If step 2 fails, a `task.archive_failed` event fires, and the task returns to its original state.

## Dead Letter Queue

Events that fail after all retry attempts are moved to a dead letter queue. A background job periodically checks the DLQ and sends alerts to the on-call channel. Engineers can inspect failed events in an admin dashboard and replay them after fixing the underlying issue.

## See Also

- [Data Flow](./data-flow.md) - Event emission within the request lifecycle
- [Notifications](./services/notifications.md) - Notification handler implementation
- [Webhooks Outbound](./services/integrations/webhooks-outbound.md) - Webhook delivery via events

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New domain events are added or the event bus infrastructure changes -->
