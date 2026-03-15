# Data Validation

Nimbus validates data at every system boundary using Zod schemas. Validation schemas are shared between frontend and backend through the `packages/schemas` package, ensuring consistent rules across the entire stack. Invalid data is rejected early with structured error responses.

## Validation at Boundaries

Data is validated at three boundaries:

1. **API ingress**: Every incoming request body, query parameter, and path parameter is validated by Zod schemas in the route handler middleware. Invalid requests receive a 422 response before any business logic runs.

2. **Domain layer**: Aggregate methods validate business invariants (e.g., a task cannot have more than 50 subtasks). These throw domain-specific errors, not Zod errors.

3. **Frontend forms**: React Hook Form uses Zod resolvers for client-side validation. See [Forms](../frontend/forms.md) for details.

## Zod Schema Conventions

Schemas live in `packages/schemas/src/` organized by domain:

```
packages/schemas/src/
  task.ts          # TaskCreateSchema, TaskUpdateSchema, TaskFilterSchema
  project.ts       # ProjectCreateSchema, ProjectUpdateSchema
  user.ts          # UserCreateSchema, UserUpdateSchema, UserProfileSchema
  comment.ts       # CommentCreateSchema
  common.ts        # EmailSchema, UrlSchema, PaginationSchema, SortSchema
```

Naming convention: `<Entity><Operation>Schema` (e.g., `TaskCreateSchema`, `ProjectUpdateSchema`).

### Schema Patterns

```ts
// Strict creation schema -- all required fields
export const TaskCreateSchema = z.object({
  title: z.string().min(1, "Title is required").max(200, "Title cannot exceed 200 characters"),
  description: z.string().max(10000).optional(),
  projectId: z.string().regex(/^proj_/, "Invalid project ID"),
  priority: z.enum(["low", "medium", "high", "urgent"]).default("medium"),
  assigneeId: z.string().regex(/^user_/).nullable().default(null),
  dueDate: z.coerce.date().optional(),
});

// Partial update schema -- all fields optional
export const TaskUpdateSchema = TaskCreateSchema.partial().omit({ projectId: true });
```

## Custom Validators

For rules that Zod cannot express natively, use `.refine()` or `.superRefine()`:

```ts
export const DateRangeSchema = z.object({
  startDate: z.coerce.date(),
  endDate: z.coerce.date(),
}).refine(
  (data) => data.endDate >= data.startDate,
  { message: "End date must be on or after start date", path: ["endDate"] }
);
```

For async validation (e.g., checking slug uniqueness), expose a separate validation endpoint and use `z.string().refine(async (val) => ...)` only on the server.

## Validation Error Formatting

API validation errors follow a consistent response format:

```json
{
  "error": "VALIDATION_ERROR",
  "message": "Request validation failed",
  "details": [
    { "path": ["title"], "message": "Title is required" },
    { "path": ["dueDate"], "message": "Due date must be in the future" }
  ]
}
```

The `formatZodError` utility in `packages/schemas/src/errors.ts` transforms `ZodError` instances into this structure. Frontend form error mapping reads the `path` array to call `form.setError` on the correct field.

## Tenant ID Injection

Tenant ID is never accepted from the request body. It is injected by middleware from the authenticated session and added to the validated data before it reaches the service layer. This prevents tenants from accessing each other's data.

## See Also

- [Forms](../frontend/forms.md) for frontend Zod integration with React Hook Form
- [Data Models](models.md) for domain-level invariant validation
- [Serialization](serialization.md) for output validation and response shaping

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Zod is upgraded or validation error format changes -->
