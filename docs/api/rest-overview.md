# REST API Overview

The Nimbus REST API follows standard RESTful conventions. All resource endpoints use predictable URL structures, standard HTTP methods, and consistent JSON response envelopes.

## Base URL

All API requests are made to:

```
https://api.nimbus.io/v1
```

For the v2 preview API:

```
https://api.nimbus.io/v2
```

Each tenant has a workspace slug used in some multi-tenant contexts, but the base URL remains the same. Tenant resolution is handled via the `Authorization` header or `X-Workspace-Id` header.

## HTTP Methods

| Method | Usage |
|--------|-------|
| GET | Retrieve a resource or list of resources |
| POST | Create a new resource |
| PUT | Full replacement of a resource |
| PATCH | Partial update of a resource |
| DELETE | Remove a resource (soft-delete by default) |

## Request Format

All request bodies must be sent as `application/json` unless uploading files (use `multipart/form-data`). The `Content-Type` header is required for all requests with a body.

```json
{
  "name": "My Project",
  "description": "A sample project",
  "visibility": "private"
}
```

## Response Envelope

All responses follow a consistent envelope:

```json
{
  "data": { ... },
  "meta": {
    "request_id": "req_abc123",
    "timestamp": "2026-03-15T10:30:00Z"
  }
}
```

List endpoints wrap results in an array under `data` and include pagination metadata under `meta.pagination`.

## HATEOAS Links

Resources include a `_links` object for discoverable navigation:

```json
{
  "data": {
    "id": "proj_001",
    "name": "My Project",
    "_links": {
      "self": "/v1/projects/proj_001",
      "tasks": "/v1/projects/proj_001/tasks",
      "members": "/v1/projects/proj_001/members"
    }
  }
}
```

## Status Codes

Nimbus uses standard HTTP status codes: 200 for success, 201 for creation, 204 for deletion, 400 for bad requests, 401 for authentication failures, 403 for authorization failures, 404 for missing resources, and 429 for rate limiting.

## See Also

- [Authentication](authentication.md) — how to authenticate API requests
- [Error Codes](error-codes.md) — standard error response format
- [Versioning](versioning.md) — API version strategy
- [Pagination](pagination.md) — how list responses are paginated
- [GraphQL](graphql.md) — alternative query interface

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: API base URL, envelope format, or HTTP method conventions change -->
