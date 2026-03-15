# Input Validation

All user input in Nimbus must be validated and sanitized before processing. This guide covers our validation library, schema patterns, and rules for safe input handling.

## Validation Library (Zod)

Nimbus uses [Zod](https://zod.dev/) for runtime input validation on both the API server and the frontend. Zod schemas are defined in `packages/shared/src/schemas/` and shared across the stack.

```typescript
// packages/shared/src/schemas/task.ts
import { z } from 'zod';

export const CreateTaskSchema = z.object({
  title: z.string().min(1).max(200).trim(),
  description: z.string().max(10000).optional(),
  projectId: z.string().uuid(),
  assigneeId: z.string().uuid().optional(),
  priority: z.enum(['low', 'medium', 'high', 'urgent']),
  dueDate: z.string().datetime().optional(),
});
```

## Schema Definitions

Every API endpoint has a corresponding Zod schema for request validation:

| Schema location | Purpose |
|----------------|---------|
| `schemas/<resource>.ts` | Create and update schemas for each resource |
| `schemas/query.ts` | Shared query parameter schemas (pagination, sorting, filtering) |
| `schemas/common.ts` | Reusable field schemas (email, UUID, URL, date range) |

Schemas are applied via Express middleware:

```typescript
router.post('/tasks', validate(CreateTaskSchema), taskController.create);
```

The `validate` middleware returns a 400 response with structured error details if validation fails.

## Sanitization

Beyond structural validation, apply these sanitization rules:

- **HTML stripping**: Use `sanitize-html` for any field that accepts rich text. Only allow a safe subset of tags (`p`, `b`, `i`, `ul`, `ol`, `li`, `a`).
- **Trimming**: All string fields are trimmed of leading/trailing whitespace via `.trim()` in Zod.
- **Normalization**: Email addresses are lowercased. URLs are normalized with `new URL()`.

## Max Lengths

Every string field must have an explicit `max()` constraint:

| Field type | Max length | Rationale |
|-----------|-----------|-----------|
| Title / name | 200 chars | Prevents UI overflow |
| Description | 10,000 chars | Reasonable content limit |
| Comment | 5,000 chars | Prevents abuse |
| URL | 2,048 chars | Browser compatibility |
| Email | 254 chars | RFC 5321 limit |
| Search query | 500 chars | Database performance |

## Type Coercion Rules

Zod coercion is used sparingly and only where the API contract is clear:

- Query parameters: Use `z.coerce.number()` for pagination (`page`, `limit`).
- Boolean query params: Use `z.coerce.boolean()` for flags (`?archived=true`).
- Request body: Never coerce. The client must send the correct type.

## See Also

- [API Design](../../conventions/api-design.md) — request/response conventions
- [Error Handling Patterns](../../conventions/error-handling-patterns.md) — validation error responses
- [XSS Prevention](xss-prevention.md) — output encoding after validation

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Zod version, validation middleware, or input constraints change -->
