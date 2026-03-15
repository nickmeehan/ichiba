# Error Handling Patterns

This guide covers how Nimbus handles errors consistently across the stack, from API responses to React error boundaries.

## Result Type

For operations that can fail in expected ways, use the `Result` type instead of throwing exceptions:

```typescript
// packages/shared/src/types/result.ts
type Result<T, E = AppError> =
  | { ok: true; data: T }
  | { ok: false; error: E };

// Usage in a service
async function assignTask(taskId: string, userId: string): Promise<Result<Task>> {
  const task = await db.task.findUnique({ where: { id: taskId } });
  if (!task) {
    return { ok: false, error: new NotFoundError('Task', taskId) };
  }
  if (task.status === 'completed') {
    return { ok: false, error: new BusinessRuleError('Cannot assign a completed task') };
  }
  const updated = await db.task.update({ where: { id: taskId }, data: { assigneeId: userId } });
  return { ok: true, data: updated };
}
```

Reserve thrown exceptions for truly unexpected errors (programming bugs, infrastructure failures).

## Error Classes

Nimbus defines a hierarchy of error classes in `packages/shared/src/errors/`:

| Error class | HTTP status | When to use |
|------------|-------------|-------------|
| `NotFoundError` | 404 | Resource does not exist or is not accessible to the tenant |
| `ValidationError` | 400 | Input fails schema validation |
| `BusinessRuleError` | 422 | Input is valid but violates a business rule |
| `AuthenticationError` | 401 | Missing or invalid credentials |
| `AuthorizationError` | 403 | Valid credentials but insufficient permissions |
| `ConflictError` | 409 | Optimistic concurrency conflict |
| `RateLimitError` | 429 | Too many requests |

## Error Boundary Placement

React error boundaries catch rendering errors and prevent the entire app from crashing:

```
<RootErrorBoundary>          ← Catches catastrophic errors, shows "Something went wrong"
  <Layout>
    <FeatureErrorBoundary>   ← Catches feature-level errors, shows inline error state
      <TaskList />
    </FeatureErrorBoundary>
  </Layout>
</RootErrorBoundary>
```

- Place `FeatureErrorBoundary` around each major feature section.
- The root error boundary is a last resort and triggers an error report to Sentry.

## Retry Strategies

For transient failures (network errors, database connection drops), use exponential backoff:

```typescript
import { retry } from '@nimbus/shared/utils';

const result = await retry(() => externalApi.call(), {
  maxAttempts: 3,
  baseDelayMs: 500,
  maxDelayMs: 5000,
  retryOn: (error) => error.status >= 500 || error.code === 'ECONNRESET',
});
```

Do not retry on 4xx errors (client errors are not transient).

## User-Facing Error Messages

API error responses follow a consistent format:

```json
{
  "error": {
    "code": "TASK_NOT_FOUND",
    "message": "The requested task could not be found.",
    "details": [
      { "field": "taskId", "message": "No task exists with ID task-xyz" }
    ]
  }
}
```

Rules for user-facing messages:
- Never expose stack traces, SQL queries, or internal IDs.
- Use clear, actionable language ("The task could not be found" not "null reference error").
- Include an error `code` that the frontend can use for i18n.

## See Also

- [Logging](logging.md) — logging errors with context
- [API Design](api-design.md) — error response format
- [TypeScript Style](typescript-style.md) — discriminated unions for Result types

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: error class hierarchy, Result type, or error response format changes -->
