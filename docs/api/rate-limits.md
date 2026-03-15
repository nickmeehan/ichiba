# Rate Limits

Nimbus enforces rate limits to ensure fair usage and platform stability. Limits are applied per endpoint, per tenant, and per authentication method.

## Default Limits

| Tier | Requests/minute | Requests/hour |
|------|-----------------|---------------|
| Free | 60 | 1,000 |
| Pro | 300 | 10,000 |
| Enterprise | 1,000 | 50,000 |

These are per-workspace limits. Individual API keys within a workspace share the workspace quota.

## Per-Endpoint Limits

Some endpoints have stricter limits due to computational cost:

- `POST /v1/reports/generate` — 10 requests/minute
- `POST /v1/exports` — 5 requests/minute
- `POST /v1/search` — 120 requests/minute
- `POST /v1/imports` — 3 requests/minute

## Rate Limit Headers

Every API response includes rate limit headers:

```
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 287
X-RateLimit-Reset: 1710489600
X-RateLimit-Policy: workspace
```

`X-RateLimit-Reset` is a Unix timestamp indicating when the current window resets.

## 429 Handling

When rate limited, the API returns HTTP 429 with a `Retry-After` header:

```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded. Retry after 32 seconds.",
    "retry_after": 32
  }
}
```

Clients should implement exponential backoff with jitter. Do not retry immediately in a tight loop — this will extend the rate limit window.

## Per-Tenant Quotas

Enterprise workspaces can configure custom rate limits via the admin API. Quotas are tracked per workspace and can be monitored in the admin dashboard. Quota overages are logged in the audit trail.

## Burst Allowance

All tiers include a burst allowance of 2x the per-minute limit for short spikes. Burst tokens regenerate at the standard rate. Sustained usage above the base rate will still trigger rate limiting.

## Best Practices

Use batch endpoints where available to reduce request count. Cache responses client-side when data is not time-sensitive. Use webhooks instead of polling for real-time updates.

## See Also

- [Authentication](authentication.md) — rate limits vary by auth method
- [Batch Operations](batch-operations.md) — reduce request count with bulk operations
- [Error Codes](error-codes.md) — error format for 429 responses
- [Admin Endpoint](admin-endpoint.md) — configure custom rate limits

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: rate limit tiers, per-endpoint limits, or burst policy changes -->
