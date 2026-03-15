# CORS (Cross-Origin Resource Sharing)

Nimbus configures CORS headers to allow browser-based applications to access the API from different origins. This document covers allowed origins, preflight handling, and credential support.

## Allowed Origins

By default, the Nimbus API allows requests from:

- `https://*.nimbus.io` — all Nimbus subdomains
- Origins registered in workspace settings for custom integrations

The `Access-Control-Allow-Origin` header is set dynamically based on the request's `Origin` header. If the origin is not in the allow list, the header is omitted and the browser blocks the response.

## Configuring Custom Origins

Workspace admins can add custom allowed origins via the admin API:

```
POST /v1/admin/cors-origins
Content-Type: application/json

{ "origin": "https://app.example.com" }
```

Up to 20 custom origins can be configured per workspace. Wildcard subdomains are supported: `https://*.example.com`.

## Preflight Handling

Browsers send `OPTIONS` preflight requests for non-simple requests. Nimbus responds with:

```
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
Access-Control-Allow-Headers: Authorization, Content-Type, Idempotency-Key, X-Workspace-Id
Access-Control-Max-Age: 86400
```

Preflight responses are cached for 24 hours (`Max-Age: 86400`) to minimize redundant OPTIONS requests.

## Credential Support

CORS requests with credentials (cookies, Authorization headers) are supported:

```
Access-Control-Allow-Credentials: true
```

When credentials are included, `Access-Control-Allow-Origin` must be a specific origin (not `*`). Nimbus enforces this automatically.

## Custom Headers

The following custom headers are exposed to browser JavaScript via `Access-Control-Expose-Headers`:

- `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- `X-Total-Count`
- `X-Request-Id`
- `X-Idempotent-Replayed`
- `Retry-After`

## Debugging CORS Issues

Common CORS problems and solutions:

1. **Origin not allowed**: Add the origin in workspace admin settings
2. **Missing credentials header**: Ensure `withCredentials: true` is set on the client
3. **Preflight failure**: Check that the `OPTIONS` method is not blocked by a proxy
4. **Header not exposed**: Verify the header is in the `Expose-Headers` list

## See Also

- [Authentication](authentication.md) — credential handling
- [REST Overview](rest-overview.md) — request format
- [Admin Endpoint](admin-endpoint.md) — managing CORS origins
- [Rate Limits](rate-limits.md) — rate limit headers exposed via CORS

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: allowed origin defaults, exposed headers, or preflight cache duration changes -->
