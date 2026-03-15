# Serialization

Nimbus uses a structured approach to JSON serialization to handle edge cases like dates, BigInts, circular references, and consistent API response shaping. All API responses pass through a serialization layer that transforms domain objects into client-friendly JSON.

## JSON Serialization Pipeline

Domain objects go through three stages before becoming API responses:

1. **Domain to DTO**: Aggregate roots and entities are mapped to Data Transfer Objects (DTOs) that exclude internal fields (e.g., `_version`, `_events`, soft-delete flags).
2. **DTO to JSON-safe**: Values that are not natively JSON-serializable are transformed (dates, BigInts, Sets, Maps).
3. **Envelope wrapping**: The JSON-safe DTO is wrapped in a standard response envelope.

```ts
// Example pipeline
const task = await taskRepository.findById(taskId);
const dto = TaskDTO.fromDomain(task);
const response = envelope({ data: dto });
```

## Date Handling

All dates are serialized as ISO 8601 strings in UTC:

```json
{ "createdAt": "2026-03-15T14:30:00.000Z" }
```

Rules:
- **Storage**: Dates are stored as `TIMESTAMP WITH TIME ZONE` in PostgreSQL, always in UTC.
- **Serialization**: `toISOString()` is called on all `Date` objects during DTO mapping.
- **Deserialization**: The frontend parses ISO strings back to `Date` objects using `new Date()` or `date-fns/parseISO`.
- **Display**: Dates are formatted for the user's locale and timezone using `Intl.DateTimeFormat` (see [I18n](../frontend/i18n.md)).

Never serialize dates as Unix timestamps or locale-specific strings.

## BigInt Handling

PostgreSQL `BIGINT` columns (used for counters, file sizes, and event sequence numbers) cannot be serialized to JSON natively. We handle this by converting to strings in DTOs:

```ts
class ProjectDTO {
  static fromDomain(project: Project) {
    return {
      ...project,
      totalFileSize: project.totalFileSize.toString(),
      eventSequence: project.eventSequence.toString(),
    };
  }
}
```

The frontend receives these as strings and uses `BigInt()` only when arithmetic is needed. For display purposes, `formatNumber()` handles string number formatting.

## Circular Reference Prevention

Domain objects with bidirectional relationships (e.g., Task has Comments, Comment references Task) can cause circular reference errors during serialization. Prevention strategies:

1. **DTO mapping**: DTOs include only the fields needed for the response. Nested entities include IDs, not full objects.
2. **Depth limiting**: Nested serialization stops at a configurable depth (default: 2 levels).
3. **`JSON.stringify` replacer**: A safety net replacer function detects and breaks cycles by replacing repeated references with `{ "$ref": "<entityType>:<id>" }`.

## API Response Shaping

All API responses use a standard envelope:

```json
// Single resource
{ "data": { "id": "task_123", "title": "Fix login bug" }, "meta": { "requestId": "req_abc" } }

// Collection
{ "data": [...], "meta": { "total": 142, "page": 1, "limit": 25, "requestId": "req_def" } }

// Error
{ "error": "NOT_FOUND", "message": "Task not found", "meta": { "requestId": "req_ghi" } }
```

The `meta.requestId` is included in every response for tracing. Collection responses always include pagination metadata even if the client did not request pagination.

## Field Naming

API responses use camelCase for all field names. The serialization layer transforms snake_case database columns to camelCase automatically. This transformation is handled by the ORM's naming strategy, not by manual mapping.

## See Also

- [Data Models](models.md) for domain object structure and DTO mapping
- [Data Validation](validation.md) for output validation of serialized data
- [Data Fetching](../frontend/data-fetching.md) for how the frontend consumes serialized responses

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: API response format changes or new non-serializable types are introduced -->
