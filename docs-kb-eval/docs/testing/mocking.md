# Mocking

This guide covers mocking strategies in Nimbus tests, including Jest mocks, MSW for API mocking, and patterns for isolating dependencies.

## Jest Mocks

Use Jest's built-in mocking for isolating unit tests from dependencies:

```typescript
// Mock a module
jest.mock('@nimbus/shared/flags', () => ({
  getFlag: jest.fn().mockResolvedValue(true),
}));

// Mock a specific function
import { sendEmail } from '../services/email.service';
jest.mock('../services/email.service');
const mockSendEmail = jest.mocked(sendEmail);

it('sends a welcome email on signup', async () => {
  await userService.signup({ email: 'test@example.com', name: 'Test' });
  expect(mockSendEmail).toHaveBeenCalledWith(
    expect.objectContaining({ template: 'welcome' })
  );
});
```

## MSW for API Mocking

[Mock Service Worker (MSW)](https://mswjs.io/) intercepts HTTP requests at the network level. Use it for integration tests that call external APIs:

```typescript
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  http.post('https://api.stripe.com/v1/customers', () => {
    return HttpResponse.json({ id: 'cus_test123', email: 'test@example.com' });
  }),

  http.post('https://api.sendgrid.com/v3/mail/send', () => {
    return new HttpResponse(null, { status: 202 });
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

MSW handlers are defined in `packages/test-utils/src/msw-handlers/` and shared across test files.

## Dependency Injection

For services with complex dependencies, use constructor injection to make mocking straightforward:

```typescript
class TaskService {
  constructor(
    private db: PrismaClient,
    private notifications: NotificationService,
    private flags: FeatureFlagService,
  ) {}
}

// In tests
const mockNotifications = { send: jest.fn() };
const service = new TaskService(testDb, mockNotifications, mockFlags);
```

## Mock vs. Stub vs. Spy

| Technique | When to use | Example |
|-----------|------------|---------|
| **Mock** | Replace a dependency entirely | `jest.mock('./email.service')` |
| **Stub** | Provide a fixed return value | `jest.fn().mockReturnValue(42)` |
| **Spy** | Observe calls without changing behavior | `jest.spyOn(service, 'send')` |

Prefer spies when you want to verify a call was made but still want the real implementation to execute. Use mocks when the real implementation has side effects (email, payments, external APIs).

## External Service Mocking

Each external service has a dedicated mock configuration:

| Service | Mock approach | Location |
|---------|-------------|----------|
| Stripe | MSW handlers | `test-utils/src/msw-handlers/stripe.ts` |
| SendGrid | MSW handlers | `test-utils/src/msw-handlers/sendgrid.ts` |
| LaunchDarkly | In-memory flag store | `test-utils/src/mocks/flags.ts` |
| AWS S3 | MinIO (local dev) or MSW | `test-utils/src/msw-handlers/s3.ts` |

For LaunchDarkly, use the mock flag store to control flag values per test:

```typescript
import { setTestFlag } from '@nimbus/test-utils/mocks/flags';

it('shows gantt view when flag is enabled', async () => {
  setTestFlag('project.gantt-view', true);
  // ... test the gantt view
});
```

## See Also

- [Unit Tests](unit-tests.md) — mock patterns in unit tests
- [Integration Tests](integration-tests.md) — MSW usage in integration tests
- [Test Data](test-data.md) — factories vs. mocks for data

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: MSW version, mocking patterns, or external service integrations change -->
