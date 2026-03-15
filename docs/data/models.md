# Data Models

Nimbus follows domain-driven design (DDD) principles for organizing its data layer. The domain model is divided into bounded contexts, each with clearly defined aggregates, entities, value objects, and domain events. All models enforce tenant isolation through a required `tenantId` field.

## Core Domain Model

The primary bounded contexts and their root aggregates:

| Bounded Context | Aggregate Root | Key Entities |
|----------------|---------------|--------------|
| Project Management | `Project` | Milestone, Board, Column |
| Task Tracking | `Task` | Subtask, Checklist, ChecklistItem |
| Collaboration | `Comment` | Reaction, Mention, Attachment |
| Identity | `User` | UserProfile, TeamMembership |
| Billing | `Subscription` | Invoice, PaymentMethod |
| Tenant | `Tenant` | TenantSettings, TenantTheme |

## Entity Relationships

Entities within an aggregate reference each other directly. Cross-aggregate references use IDs only, never object references:

```ts
// Within the Task aggregate (direct reference)
interface Task {
  id: TaskId;
  tenantId: TenantId;
  projectId: ProjectId;       // cross-aggregate reference (ID only)
  subtasks: Subtask[];         // within-aggregate (direct)
  checklists: Checklist[];     // within-aggregate (direct)
  assigneeId: UserId | null;   // cross-aggregate reference (ID only)
}
```

Cross-aggregate data is loaded via separate queries, never via JOINs across aggregate boundaries in write paths. Read paths may use denormalized views for performance.

## Value Objects

Value objects are immutable types with no identity. They are compared by value, not by reference:

- **`TaskId`**, **`ProjectId`**, **`UserId`**: Branded string types using TypeScript template literals (`task_${string}`).
- **`Priority`**: Enum value object with levels `low`, `medium`, `high`, `urgent`.
- **`DateRange`**: Start and end date pair with validation that `end >= start`.
- **`EmailAddress`**: Validated and normalized email string.
- **`Color`**: Hex color string validated against a regex and contrast ratio.

Value objects are defined in `packages/domain/src/values/` and shared between frontend and backend.

## Aggregates

Each aggregate enforces its own invariants. Operations that modify an aggregate go through methods on the aggregate root, never by mutating child entities directly:

```ts
class Task {
  addSubtask(title: string): Subtask { /* validates max 50 subtasks */ }
  reassign(userId: UserId): void { /* emits TaskReassigned event */ }
  complete(): void { /* validates all required checklists are done */ }
}
```

Aggregates are loaded and saved as a unit. The repository pattern is used: `TaskRepository.findById(id)` returns the full aggregate, and `TaskRepository.save(task)` persists all changes within a transaction.

## Domain Events

State changes on aggregates emit domain events that are published to the event bus:

| Event | Emitted When | Consumers |
|-------|-------------|-----------|
| `TaskCreated` | New task is created | Activity feed, notifications, search index |
| `TaskStatusChanged` | Task moves between columns | WebSocket broadcast, SLA tracker |
| `TaskReassigned` | Assignee changes | Notification to new assignee, activity feed |
| `CommentAdded` | Comment posted on a task | Notification to watchers, search index |
| `ProjectArchived` | Project is archived | Cleanup jobs, billing adjustment |

Events are persisted to the event store before publishing to ensure delivery. See [Event Sourcing](event-sourcing.md) for details.

## See Also

- [Data Validation](validation.md) for Zod schemas that enforce model constraints
- [Event Sourcing](event-sourcing.md) for event persistence and replay
- [Serialization](serialization.md) for API representation of domain models

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: new bounded contexts are added or aggregate boundaries are restructured -->
