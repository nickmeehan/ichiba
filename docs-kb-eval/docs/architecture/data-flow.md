# Data Flow

This document describes how a typical API request travels through the Nimbus backend, from the initial HTTP call to the database response, and how domain events propagate side effects asynchronously.

## Request Lifecycle

A request passes through the following layers in order:

1. **Load Balancer** - TLS termination, health check routing.
2. **API Gateway (Express)** - Receives the HTTP request.
3. **Global Middleware** - Request ID generation, CORS, body parsing, rate limiting.
4. **Auth Middleware** - Validates the JWT access token, attaches the authenticated user to the request context.
5. **Tenant Middleware** - Resolves the `tenant_id` from the workspace slug in the URL or from the JWT claims. Sets the tenant context on the async local storage.
6. **Route Handler** - Matches the URL pattern and HTTP method to a controller function.
7. **Controller** - Validates the request body/params using Zod schemas from the shared package. Returns early with a 400 if validation fails.
8. **Service** - Executes business logic, enforces authorization rules, orchestrates repository calls.
9. **Repository** - Builds and executes SQL queries using Knex.js. Automatically scopes all queries to the current tenant.
10. **Database** - PostgreSQL processes the query. Row-level security provides a second layer of tenant isolation.

The response travels back up the same chain. The controller serializes the service result into the API response format.

## Write Operations and Events

When a write operation completes successfully, the service layer emits one or more domain events to the event bus (Redis pub/sub):

```
Controller -> Service.createTask()
                |
                +-- Repository.insert(task)   -> DB write
                |
                +-- EventBus.emit('task.created', { taskId, tenantId, ... })
```

Event handlers run asynchronously and independently of the HTTP response. The client receives a response as soon as the primary database write completes.

## Event Propagation

Domain events are published to Redis pub/sub channels namespaced by event type. Subscribers include:

| Subscriber            | Example Event     | Action                                      |
|----------------------|-------------------|----------------------------------------------|
| Notification Service | `task.assigned`   | Send in-app and email notification           |
| Audit Log Service    | `task.updated`    | Record change in the audit trail             |
| WebSocket Broadcaster| `task.moved`      | Push real-time update to connected clients   |
| Search Indexer       | `task.created`    | Update Elasticsearch index                   |
| Analytics Collector  | `sprint.completed`| Write analytics event to ClickHouse          |
| Webhook Dispatcher   | `task.created`    | Deliver payload to registered webhook URLs   |

## Error Propagation

If a service operation fails, the error propagates up to the controller, which maps it to an HTTP status code and error response body. Event handlers that fail do not affect the primary request. Failed events are retried and eventually moved to a dead letter queue for manual inspection.

## Pagination

List endpoints use cursor-based pagination. The cursor is an opaque base64-encoded string containing the sort field value and the record ID. This approach provides stable pagination even when new records are inserted between page loads.

## See Also

- [Error Handling](./error-handling.md) - Error types and HTTP mapping
- [Event-Driven Architecture](./event-driven.md) - Event bus implementation details
- [Caching](./caching.md) - Where caching fits into the request path

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Middleware order changes or new layers are added to the request pipeline -->
