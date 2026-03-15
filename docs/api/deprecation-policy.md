# Deprecation Policy

Nimbus follows a structured deprecation process to ensure clients have adequate time to migrate when API changes are necessary. This policy covers endpoints, fields, and entire API versions.

## Sunset Timeline

All deprecations follow a minimum timeline:

| Phase | Duration | Actions |
|-------|----------|---------|
| Announcement | Day 0 | Blog post, changelog entry, email to workspace admins |
| Warning Period | 0–6 months | `Deprecation` header added to responses, dashboard banner |
| Migration Period | 6–12 months | Both old and new versions available, migration guides published |
| Sunset | Month 12+ | Deprecated resource returns 410 Gone |

Enterprise customers with active contracts receive extended timelines (minimum 18 months from announcement to sunset).

## Deprecation Headers

Deprecated endpoints include headers in every response:

```
Deprecation: true
Sunset: Sat, 15 Mar 2027 00:00:00 GMT
Link: <https://docs.nimbus.io/api/v2/tasks>; rel="successor-version"
```

The `Sunset` header indicates the date after which the endpoint will stop functioning.

## Field-Level Deprecation

Individual response fields can be deprecated without removing the entire endpoint. Deprecated fields are:

1. Marked in the OpenAPI spec with `deprecated: true`
2. Documented with the replacement field name
3. Included in responses for the full deprecation period
4. Removed after sunset

## Breaking Change Policy

The following are considered breaking changes and require a deprecation cycle:

- Removing an endpoint or HTTP method
- Removing or renaming a response field
- Changing a field's data type
- Adding a new required request parameter
- Changing error response codes for existing error conditions
- Reducing rate limits

The following are **not** considered breaking changes:

- Adding new optional fields to responses
- Adding new endpoints
- Adding new optional query parameters
- Increasing rate limits
- Adding new error codes for new error conditions

## Migration Support

Each deprecation includes:

- A detailed migration guide with before/after code examples
- A compatibility shim (where feasible) that maps old requests to the new format
- Office hours with the API team during the migration period
- A migration status dashboard showing usage of deprecated endpoints

## Monitoring Deprecation Usage

Workspace admins can view deprecated endpoint usage via:

```
GET /v1/admin/deprecation-report
```

This returns a list of deprecated endpoints being called, call volume, and calling API keys.

## See Also

- [Versioning](versioning.md) — API version lifecycle
- [Error Codes](error-codes.md) — sunset error responses
- [OpenAPI Spec](openapi-spec.md) — deprecated field annotations
- [Admin Endpoint](admin-endpoint.md) — deprecation usage reports

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: deprecation timeline, breaking change definition, or migration support process changes -->
