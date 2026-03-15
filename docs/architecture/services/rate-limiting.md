# Rate Limiting

Nimbus uses Redis-based rate limiting to protect the API from abuse, ensure fair usage across tenants, and provide predictable service levels. The implementation uses a sliding window algorithm for accurate request counting.

## Algorithm

The rate limiter uses a sliding window log approach stored in Redis sorted sets. Each request adds a timestamped entry to the set, and expired entries are pruned. The current request count is the cardinality of the set within the active window.

This approach avoids the burst boundary problem that affects fixed-window counters while keeping Redis memory usage proportional to the rate limit value.

## Rate Limit Tiers

Limits are applied at two levels: per-endpoint and per-tenant.

### Per-Endpoint Limits

| Endpoint Category    | Window  | Max Requests | Notes                           |
|---------------------|---------|--------------|---------------------------------|
| Authentication       | 1 min   | 10           | Login, token refresh             |
| Read operations      | 1 min   | 300          | GET requests                     |
| Write operations     | 1 min   | 60           | POST, PUT, PATCH, DELETE         |
| Search               | 1 min   | 30           | Full-text search queries         |
| File upload          | 1 hour  | 100          | Presigned URL generation         |
| Bulk operations      | 1 hour  | 10           | Batch imports, exports           |

### Per-Tenant Limits

In addition to per-endpoint limits, each workspace has an aggregate request limit based on its subscription tier:

| Tier       | Requests/hour | Burst Allowance |
|------------|---------------|-----------------|
| Free       | 1,000         | 50 extra        |
| Pro        | 10,000        | 500 extra       |
| Enterprise | 100,000       | 5,000 extra     |

The burst allowance permits short traffic spikes without triggering rate limit errors. Burst capacity regenerates at the standard rate once usage drops below the sustained limit.

## Response Headers

Every API response includes rate limit headers:

```
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 247
X-RateLimit-Reset: 1710504000
```

## 429 Response Handling

When a rate limit is exceeded, the API returns a `429 Too Many Requests` response with a `Retry-After` header indicating how many seconds the client should wait:

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Please retry after 23 seconds.",
    "retryAfter": 23
  }
}
```

## Exemptions

Internal service-to-service calls authenticated with service tokens bypass rate limiting. Health check and metrics endpoints are also exempt.

## Monitoring

Rate limit hits are tracked as Prometheus counters with labels for endpoint, tenant, and tier. A Grafana dashboard shows rate limit trends, and an alert fires if any single tenant hits their limit more than 100 times in an hour, which may indicate a misconfigured integration.

## See Also

- [Error Handling](../error-handling.md) - RateLimitError class
- [Billing](./billing.md) - Subscription tier limits
- [Monitoring](../infrastructure/monitoring.md) - Rate limit dashboards

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Rate limit values are adjusted or the algorithm changes -->
