# Batch Operations

Nimbus provides batch endpoints for performing bulk create, update, and delete operations in a single API call. This reduces network overhead and improves throughput for large data changes.

## Batch Endpoint

All batch operations use a dedicated endpoint:

```
POST /v1/batch
Content-Type: application/json
```

The request body contains an array of operations:

```json
{
  "operations": [
    { "method": "POST", "path": "/v1/tasks", "body": { "name": "Task A", "project_id": "proj_01" } },
    { "method": "PATCH", "path": "/v1/tasks/task_05", "body": { "status": "done" } },
    { "method": "DELETE", "path": "/v1/tasks/task_03" }
  ]
}
```

## Batch Size Limits

| Tier | Max Operations |
|------|---------------|
| Free | 25 |
| Pro | 100 |
| Enterprise | 500 |

Requests exceeding the limit receive a `400` error with code `BATCH_SIZE_EXCEEDED`.

## Transaction Semantics

By default, batch operations are **non-transactional** — each operation executes independently. To enable all-or-nothing behavior, set the `transactional` flag:

```json
{
  "transactional": true,
  "operations": [...]
}
```

In transactional mode, if any operation fails, all changes are rolled back. The response includes the failed operation's error details.

## Partial Failure Handling

In non-transactional mode, each operation returns its own status:

```json
{
  "results": [
    { "index": 0, "status": 201, "data": { "id": "task_50" } },
    { "index": 1, "status": 200, "data": { "id": "task_05" } },
    { "index": 2, "status": 404, "error": { "code": "NOT_FOUND", "message": "Task not found" } }
  ],
  "summary": { "succeeded": 2, "failed": 1 }
}
```

The overall HTTP status is `207 Multi-Status` when results are mixed.

## Operation Ordering

Operations execute in array order. Later operations can reference resources created by earlier operations using the `$ref` syntax:

```json
{
  "operations": [
    { "method": "POST", "path": "/v1/projects", "body": { "name": "New Project" }, "ref": "new_project" },
    { "method": "POST", "path": "/v1/tasks", "body": { "name": "First Task", "project_id": "$ref:new_project.id" } }
  ]
}
```

## Rate Limiting

Batch requests count as a single API call for rate limiting, but each operation counts toward per-endpoint limits. A batch of 100 task creates counts as 100 against the tasks endpoint limit.

## See Also

- [REST Overview](rest-overview.md) — single-resource API conventions
- [Rate Limits](rate-limits.md) — how batch affects rate limits
- [Idempotency](idempotency.md) — idempotency keys for batch operations
- [Imports Endpoint](imports-endpoint.md) — CSV/JSON bulk import alternative

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: batch size limits, transaction support, or $ref syntax changes -->
