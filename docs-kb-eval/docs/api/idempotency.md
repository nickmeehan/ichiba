# Idempotency

Nimbus supports idempotency keys on all mutating endpoints (POST, PUT, PATCH, DELETE) to enable safe retries without duplicate side effects.

## Idempotency Keys

Include an `Idempotency-Key` header with a unique value (typically a UUID) on any request you might retry:

```
POST /v1/tasks
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{ "name": "Deploy staging", "project_id": "proj_01" }
```

If the same key is sent again within the retention window, Nimbus returns the original response without executing the operation again.

## Retry Safety

When retrying a request with the same idempotency key:

1. If the original request succeeded, the stored response is returned with a `200` status
2. If the original request failed with a client error (4xx), the error is returned and the key can be reused with corrected input
3. If the original request failed with a server error (5xx), the operation is retried

The response includes an `X-Idempotent-Replayed: true` header when returning a cached result.

## Duplicate Detection

Nimbus fingerprints the request body along with the idempotency key. If the same key is used with a different request body, the API returns:

```json
{
  "error": {
    "code": "IDEMPOTENCY_KEY_CONFLICT",
    "message": "This idempotency key was already used with a different request body."
  }
}
```

## Key Format

Idempotency keys must be:
- Between 1 and 256 characters
- Alphanumeric, hyphens, and underscores only
- Unique per workspace

UUID v4 is the recommended format.

## Key Expiration

Idempotency keys are stored for **24 hours** after the initial request. After expiration, the same key can be reused for a new operation. Enterprise plans can configure longer retention (up to 7 days) via admin settings.

## Batch Operations

For batch requests, include a single idempotency key for the entire batch. The key covers the full set of operations — partial retries are not supported.

## Best Practices

- Always use idempotency keys for payment-related operations
- Generate keys client-side before sending the request
- Store the key alongside the request in your application for reliable retry
- Do not reuse keys across different operation types

## See Also

- [REST Overview](rest-overview.md) — request format conventions
- [Batch Operations](batch-operations.md) — idempotency in batch requests
- [Error Codes](error-codes.md) — idempotency conflict errors
- [Webhooks Inbound](webhooks-inbound.md) — webhook idempotency

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: key retention period, key format rules, or retry behavior changes -->
