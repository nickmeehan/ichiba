# Integration Testing

Integration tests verify that multiple components work correctly together, including database interactions, API-to-service communication, and cross-package dependencies.

## Test Database Setup

Integration tests run against a real PostgreSQL instance. The test database is managed automatically:

```bash
# Start the test database (Docker)
docker compose up -d postgres-test

# Run migrations on the test database
DATABASE_URL=postgresql://nimbus:nimbus@localhost:5433/nimbus_test pnpm db:migrate
```

The test database runs on port 5433 (separate from the dev database on 5432) to avoid conflicts.

## Test Lifecycle

Each test file gets a clean database state:

```typescript
import { createTestContext } from '@nimbus/test-utils';

const ctx = createTestContext();

beforeEach(async () => {
  await ctx.reset(); // Truncates all tables, re-seeds essential data
});

afterAll(async () => {
  await ctx.cleanup(); // Closes database connections
});
```

The `createTestContext` helper manages database connections, provides a Prisma client, and seeds a default tenant and admin user.

## API Integration Tests

API integration tests start the Express server and make real HTTP requests:

```typescript
import { createTestApp } from '@nimbus/test-utils';

const app = createTestApp();

it('creates a task and returns it with the project relation', async () => {
  const project = await app.factories.project.create();

  const response = await app.request
    .post('/api/v1/tasks')
    .auth(app.tokens.admin)
    .send({ title: 'New task', projectId: project.id, priority: 'medium' });

  expect(response.status).toBe(201);
  expect(response.body.data.project.id).toBe(project.id);
});
```

## Service Integration Tests

Test service-to-service interactions where one service calls another:

```typescript
describe('NotificationService', () => {
  it('sends an email when a task is assigned', async () => {
    const emailSpy = jest.spyOn(emailService, 'send');

    await taskService.assign(task.id, user.id);

    expect(emailSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        to: user.email,
        template: 'task-assigned',
      })
    );
  });
});
```

## Test Isolation

Integration tests must be isolated from each other:

- **Database**: Each test starts with a truncated database. Tests do not share state.
- **External services**: All external HTTP calls are intercepted by MSW. No real network requests.
- **Time**: Use `jest.useFakeTimers()` when testing time-dependent behavior (due dates, expiry).
- **Randomness**: Seed the random number generator for deterministic factory output.

If a test depends on data created by another test, it is a test design bug. Fix the dependency.

## See Also

- [API Tests](api-tests.md) — focused API endpoint testing
- [Test Data](test-data.md) — factories for creating test data
- [Mocking](mocking.md) — external service mocking with MSW

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: test database setup, test utilities, or isolation patterns change -->
