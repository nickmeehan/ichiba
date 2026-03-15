# API Design Conventions

Nimbus exposes a RESTful JSON API at `api.nimbus.io/v1/`. This guide covers resource naming, HTTP method usage, status codes, and response format conventions.

## Resource Naming

Resources use plural nouns in kebab-case:

```
GET    /api/v1/projects
GET    /api/v1/projects/:projectId
POST   /api/v1/projects
PATCH  /api/v1/projects/:projectId
DELETE /api/v1/projects/:projectId

GET    /api/v1/projects/:projectId/tasks
POST   /api/v1/projects/:projectId/tasks
```

Rules:
- Use **plural nouns** for collections (`projects`, not `project`).
- Use **kebab-case** for multi-word resources (`project-members`, not `projectMembers`).
- Nest resources one level deep maximum. Use filtering for deeper relationships.

## HTTP Method Semantics

| Method | Semantics | Idempotent | Request body |
|--------|----------|------------|-------------|
| `GET` | Read resource(s) | Yes | No |
| `POST` | Create resource | No | Yes |
| `PATCH` | Partial update | Yes | Yes (partial) |
| `DELETE` | Remove resource | Yes | No |
| `PUT` | Full replacement (rarely used) | Yes | Yes (complete) |

Prefer `PATCH` over `PUT` for updates. Clients should only send the fields they want to change.

## Status Code Usage

| Code | Meaning | When to return |
|------|---------|---------------|
| 200 | OK | Successful GET, PATCH, DELETE |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE with no response body |
| 400 | Bad Request | Validation failure |
| 401 | Unauthorized | Missing or invalid auth token |
| 403 | Forbidden | Valid auth but insufficient permissions |
| 404 | Not Found | Resource does not exist (or tenant cannot access it) |
| 409 | Conflict | Optimistic concurrency conflict |
| 422 | Unprocessable Entity | Valid input but business rule violation |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server failure |

## Response Format

All responses follow a consistent envelope:

```json
// Success (single resource)
{
  "data": { "id": "task-123", "title": "Implement search", ... }
}

// Success (collection)
{
  "data": [ ... ],
  "meta": {
    "total": 142,
    "page": 1,
    "limit": 20,
    "hasNextPage": true
  }
}

// Error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      { "field": "title", "message": "Title is required" }
    ]
  }
}
```

## Hypermedia Links

Collection responses include pagination links:

```json
{
  "data": [ ... ],
  "meta": { ... },
  "links": {
    "self": "/api/v1/tasks?page=2&limit=20",
    "next": "/api/v1/tasks?page=3&limit=20",
    "prev": "/api/v1/tasks?page=1&limit=20"
  }
}
```

## Field Naming

Response fields use **camelCase** (matching TypeScript conventions). The API transforms between camelCase (API) and snake_case (database) using a serialization layer.

```json
{
  "id": "task-123",
  "title": "Implement search",
  "projectId": "proj-456",
  "createdAt": "2026-03-15T10:30:00Z",
  "updatedAt": "2026-03-15T14:22:00Z"
}
```

Timestamps are always ISO 8601 in UTC. IDs are prefixed strings (`task-`, `proj-`, `user-`).

## See Also

- [Input Validation](../guides/security/input-validation.md) — request validation with Zod
- [Error Handling Patterns](error-handling-patterns.md) — error response structure
- [Contract Tests](../testing/contract-tests.md) — verifying API contracts

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: API versioning strategy, response format, or field naming conventions change -->
