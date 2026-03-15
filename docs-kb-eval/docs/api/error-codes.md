# Error Codes

Nimbus uses a consistent error response format across all API endpoints. Every error includes a machine-readable code, a human-readable message, and contextual details.

## Standard Error Format

All error responses follow this structure:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request body contains invalid fields.",
    "request_id": "req_abc123",
    "details": [
      {
        "field": "due_date",
        "issue": "Must be a future date",
        "value": "2020-01-01"
      }
    ]
  }
}
```

The `request_id` can be provided to Nimbus support for debugging.

## Error Catalog

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Request body failed validation |
| `INVALID_PARAMETER` | 400 | Query parameter is malformed |
| `UNAUTHORIZED` | 401 | Missing or invalid authentication |
| `TOKEN_EXPIRED` | 401 | Bearer token has expired |
| `FORBIDDEN` | 403 | Insufficient permissions for this action |
| `NOT_FOUND` | 404 | Resource does not exist or is not visible |
| `METHOD_NOT_ALLOWED` | 405 | HTTP method not supported for this endpoint |
| `CONFLICT` | 409 | Resource state conflict (e.g., duplicate key) |
| `RATE_LIMITED` | 429 | Rate limit exceeded |
| `INTERNAL_ERROR` | 500 | Unexpected server error |
| `SERVICE_UNAVAILABLE` | 503 | Temporary outage, retry later |
| `VERSION_SUNSET` | 410 | API version has been retired |

## Validation Errors

Validation errors include a `details` array listing each invalid field:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "2 validation errors occurred.",
    "details": [
      { "field": "name", "issue": "Required field is missing" },
      { "field": "priority", "issue": "Must be between 1 and 5", "value": 99 }
    ]
  }
}
```

## Business Logic Errors

Business rule violations use specific error codes:

| Code | Description |
|------|-------------|
| `SPRINT_ALREADY_ACTIVE` | Cannot start a sprint when another is active |
| `TASK_STATUS_INVALID_TRANSITION` | Status change violates workflow rules |
| `WORKSPACE_SEAT_LIMIT` | Cannot add user, seat limit reached |
| `EXPORT_IN_PROGRESS` | An export is already running for this workspace |
| `TEMPLATE_CIRCULAR_REF` | Template contains circular references |

## Retry Guidance

Errors include a `retryable` boolean when relevant. For `429` and `503` responses, always respect the `Retry-After` header.

## See Also

- [REST Overview](rest-overview.md) — response envelope format
- [Rate Limits](rate-limits.md) — rate limit error details
- [Authentication](authentication.md) — auth-related errors
- [Versioning](versioning.md) — version sunset errors

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: new error codes are added or error response format changes -->
