# Error Handling

Nimbus uses a structured error hierarchy to ensure consistent error responses across all API endpoints. Every error carries a machine-readable code, an HTTP status mapping, and a human-readable message.

## Error Class Hierarchy

All application errors extend a base `AppError` class:

```typescript
class AppError extends Error {
  readonly code: string;
  readonly statusCode: number;
  readonly details?: Record<string, unknown>;
}
```

### Concrete Error Classes

| Class                | Code                  | HTTP Status | Usage                                            |
|---------------------|-----------------------|-------------|--------------------------------------------------|
| `NotFoundError`     | `RESOURCE_NOT_FOUND`  | 404         | Entity lookup returned no result                  |
| `ValidationError`   | `VALIDATION_FAILED`   | 400         | Request body or params failed Zod validation      |
| `AuthenticationError`| `UNAUTHENTICATED`    | 401         | Missing or expired JWT token                      |
| `AuthorizationError`| `FORBIDDEN`           | 403         | User lacks the required RBAC permission            |
| `ConflictError`     | `CONFLICT`            | 409         | Duplicate key or concurrent modification conflict |
| `RateLimitError`    | `RATE_LIMIT_EXCEEDED` | 429         | Request throttled by rate limiter                 |
| `TenantError`       | `TENANT_MISMATCH`     | 403         | Attempted access to a resource outside the tenant |
| `ExternalServiceError`| `EXTERNAL_FAILURE`  | 502         | Third-party API call failed                       |

## Error Response Format

All error responses follow a consistent JSON structure:

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Task title is required and must be between 1 and 200 characters.",
    "details": {
      "field": "title",
      "constraint": "minLength",
      "value": ""
    },
    "requestId": "req_abc123"
  }
}
```

The `requestId` field matches the `X-Request-Id` header, making it straightforward to correlate client-side errors with server logs.

## Error Middleware

A global error-handling middleware catches all thrown errors. If the error is an instance of `AppError`, the middleware uses its `statusCode` and `code`. Unrecognized errors are logged at the `error` level and returned as a generic 500 response to avoid leaking internal details.

```typescript
app.use((err, req, res, next) => {
  if (err instanceof AppError) {
    logger.warn({ err, requestId: req.id }, err.message);
    return res.status(err.statusCode).json({ error: { ... } });
  }
  logger.error({ err, requestId: req.id }, 'Unhandled error');
  return res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred.' }
  });
});
```

## Logging Strategy

- **warn**: Known application errors (4xx responses). These are expected but worth monitoring for patterns.
- **error**: Unexpected failures (5xx responses). These trigger alerts.
- **info**: Successful operations at key business milestones (user created, payment processed).

Logs are structured JSON emitted via Pino, shipped to a centralized log aggregator, and retained for 90 days.

## See Also

- [Data Flow](./data-flow.md) - How errors propagate through the request lifecycle
- [Rate Limiting](./services/rate-limiting.md) - Rate limit error details
- [Monitoring](./infrastructure/monitoring.md) - Error rate alerting

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New error classes are added or the error response format changes -->
