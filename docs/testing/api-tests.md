# API Testing

API tests verify REST endpoint behavior including request validation, response shape, authentication, authorization, and error handling.

## Supertest Usage

Nimbus uses [supertest](https://github.com/ladderlife/supertest) for API testing. Tests run against the Express app without starting a full HTTP server:

```typescript
import { createTestApp } from '@nimbus/test-utils';

const app = createTestApp();

describe('POST /api/v1/tasks', () => {
  it('creates a task with valid input', async () => {
    const project = await app.factories.project.create();

    const res = await app.request
      .post('/api/v1/tasks')
      .auth(app.tokens.member)
      .send({
        title: 'Implement search',
        projectId: project.id,
        priority: 'high',
      });

    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({
      title: 'Implement search',
      priority: 'high',
      projectId: project.id,
    });
  });
});
```

## Request/Response Validation

Every API test should verify:

1. **Status code**: Correct HTTP status for the scenario.
2. **Response shape**: Body matches the expected schema (use `toMatchObject` for partial matching).
3. **Headers**: Content-Type is `application/json`, pagination headers are present for list endpoints.
4. **Side effects**: Database records created/updated, events emitted, jobs enqueued.

Use Zod schemas to validate response shape in tests:

```typescript
import { TaskResponseSchema } from '@nimbus/shared/schemas';

const parsed = TaskResponseSchema.safeParse(res.body.data);
expect(parsed.success).toBe(true);
```

## Auth Test Helpers

The `createTestApp` helper provides pre-configured auth tokens:

| Token | Role | Tenant |
|-------|------|--------|
| `app.tokens.admin` | Admin | Default test tenant |
| `app.tokens.member` | Member | Default test tenant |
| `app.tokens.viewer` | Viewer (read-only) | Default test tenant |
| `app.tokens.otherTenant` | Admin | Different tenant |

Use `app.tokens.otherTenant` to test tenant isolation:

```typescript
it('returns 404 when accessing another tenant task', async () => {
  const task = await app.factories.task.create(); // Default tenant

  const res = await app.request
    .get(`/api/v1/tasks/${task.id}`)
    .auth(app.tokens.otherTenant);

  expect(res.status).toBe(404);
});
```

## Error Scenario Testing

Test all expected error responses:

```typescript
it('returns 400 for missing required fields', async () => {
  const res = await app.request
    .post('/api/v1/tasks')
    .auth(app.tokens.member)
    .send({});

  expect(res.status).toBe(400);
  expect(res.body.errors).toContainEqual(
    expect.objectContaining({ field: 'title', code: 'required' })
  );
});

it('returns 401 without authentication', async () => {
  const res = await app.request.get('/api/v1/tasks');
  expect(res.status).toBe(401);
});

it('returns 403 when viewer tries to create a task', async () => {
  const res = await app.request
    .post('/api/v1/tasks')
    .auth(app.tokens.viewer)
    .send({ title: 'Test', projectId: 'proj-1', priority: 'low' });

  expect(res.status).toBe(403);
});
```

## See Also

- [Integration Tests](integration-tests.md) — broader integration testing
- [API Design Conventions](../conventions/api-design.md) — endpoint design standards
- [Input Validation](../guides/security/input-validation.md) — validation schemas

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: supertest version, auth helpers, or API response format changes -->
