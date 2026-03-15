# OpenAPI Specification

Nimbus maintains a comprehensive OpenAPI 3.1 specification that serves as the source of truth for the entire API surface. The spec drives documentation generation, SDK generation, and request validation.

## Accessing the Spec

The live specification is available at:

```
GET /v1/openapi.json   # JSON format
GET /v1/openapi.yaml   # YAML format
```

Version-specific specs are also available:

```
GET /v2/openapi.json   # v2 preview spec
```

## Spec Organization

The specification is organized into logical sections:

- **Paths** — grouped by resource (projects, tasks, users, etc.)
- **Schemas** — shared data models under `components/schemas`
- **Parameters** — reusable query parameters (pagination, filtering, sorting)
- **Responses** — common response shapes (error envelope, list envelope)
- **Security Schemes** — Bearer token and API key definitions

## Schema Components

All request and response bodies reference shared schema components:

```yaml
components:
  schemas:
    Task:
      type: object
      properties:
        id:
          type: string
          example: "task_42"
        name:
          type: string
          maxLength: 500
        status:
          type: string
          enum: [open, in_progress, in_review, done, archived]
        priority:
          type: integer
          minimum: 1
          maximum: 5
```

Schemas use `allOf` for inheritance (e.g., `TaskCreate` extends a base `TaskInput` schema) and `oneOf` for discriminated unions.

## Examples

Every endpoint includes request and response examples:

```yaml
paths:
  /v1/tasks:
    post:
      requestBody:
        content:
          application/json:
            example:
              name: "Design homepage"
              project_id: "proj_01"
              priority: 3
```

Examples are validated against schemas in CI to prevent drift.

## Spec Validation

The spec is validated on every commit using `spectral` with custom rulesets. Validation checks include:

- All paths have descriptions and operation IDs
- All schemas have examples
- No unused schema components
- Consistent naming conventions (snake_case for fields, kebab-case for paths)
- All error responses reference the standard error schema

## Documentation Generation

API documentation at `docs.nimbus.io` is generated from the OpenAPI spec using Redoc. The generation runs automatically on spec changes and deploys within minutes.

## See Also

- [SDK Generation](sdk-generation.md) — client generation from the spec
- [REST Overview](rest-overview.md) — conventions reflected in the spec
- [Versioning](versioning.md) — version-specific specifications
- [Error Codes](error-codes.md) — error schema definitions

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: spec format version, validation rules, or documentation generation tooling changes -->
