# API Versioning

Nimbus uses URL-based versioning to manage API evolution. Major versions are included in the URL path, and deprecation follows a structured timeline.

## URL-Based Versioning

The API version is specified in the URL path:

```
https://api.nimbus.io/v1/projects
https://api.nimbus.io/v2/projects
```

Currently supported versions:
- **v1** — Stable, production-ready. Full feature coverage.
- **v2** — Preview. Available for select endpoints with breaking changes from v1.

## Version Lifecycle

Each API version passes through four stages:

| Stage | Duration | Description |
|-------|----------|-------------|
| Preview | 3-6 months | New version under active development, may have breaking changes |
| Stable | 18+ months | Production-ready, fully supported |
| Deprecated | 12 months | Still functional but no new features, sunset warning headers |
| Sunset | — | Version removed, requests return 410 Gone |

## Deprecation Process

When a version enters deprecation:

1. The `Sunset` header is added to all responses with the shutdown date
2. The `Deprecation` header indicates the deprecation start date
3. Email notifications are sent to workspace admins
4. Dashboard banners appear in the Nimbus UI

```
Sunset: Sat, 01 Mar 2027 00:00:00 GMT
Deprecation: Sat, 01 Mar 2026 00:00:00 GMT
Link: <https://docs.nimbus.io/migration/v1-to-v2>; rel="successor-version"
```

## Sunset Headers

After the sunset date, all requests to the retired version return:

```json
{
  "error": {
    "code": "VERSION_SUNSET",
    "message": "API v1 has been retired. Please migrate to v2.",
    "migration_guide": "https://docs.nimbus.io/migration/v1-to-v2"
  }
}
```

## Migration Guides

Each major version transition includes a detailed migration guide covering:
- Breaking changes and their rationale
- Field-by-field mapping between versions
- Code examples for common migration patterns
- A compatibility shim library for gradual migration

## Per-Endpoint Versioning

Individual endpoints can be versioned independently when changes are isolated. Check the `X-API-Version` response header for the effective version of each response.

## See Also

- [REST Overview](rest-overview.md) — base URL structure
- [Deprecation Policy](deprecation-policy.md) — full deprecation timeline and policy
- [OpenAPI Spec](openapi-spec.md) — version-specific API specifications
- [SDK Generation](sdk-generation.md) — generating version-specific SDKs

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: supported API versions, lifecycle stages, or deprecation timeline changes -->
