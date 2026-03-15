# Contract Testing

Contract tests verify that API providers and consumers agree on the shape of requests and responses. This prevents breaking changes from reaching production.

## Pact Setup

Nimbus uses [Pact](https://pact.io/) for consumer-driven contract testing. The Pact broker is hosted at `https://pact.nimbus.io` (internal).

```
tests/contracts/
├── consumer/
│   ├── web-api.pact.ts       # Web app consuming the API
│   └── worker-api.pact.ts    # Worker consuming the API
└── provider/
    └── api-verification.ts   # API verifying all consumer contracts
```

## Consumer Tests

Consumer tests define the expected interactions from the consumer's perspective:

```typescript
import { PactV3 } from '@pact-foundation/pact';

const provider = new PactV3({
  consumer: 'nimbus-web',
  provider: 'nimbus-api',
});

describe('Task API contract', () => {
  it('returns a task by ID', async () => {
    await provider
      .given('a task with ID task-123 exists')
      .uponReceiving('a request for task task-123')
      .withRequest({ method: 'GET', path: '/api/v1/tasks/task-123' })
      .willRespondWith({
        status: 200,
        body: {
          data: {
            id: 'task-123',
            title: like('Sample task'),
            status: like('active'),
            createdAt: iso8601DateTime(),
          },
        },
      });

    await provider.executeTest(async (mockProvider) => {
      const client = new ApiClient(mockProvider.url);
      const task = await client.getTask('task-123');
      expect(task.id).toBe('task-123');
    });
  });
});
```

## Provider Verification

The API provider verifies all consumer contracts:

```typescript
import { Verifier } from '@pact-foundation/pact';

const verifier = new Verifier({
  providerBaseUrl: 'http://localhost:4000',
  pactBrokerUrl: 'https://pact.nimbus.io',
  provider: 'nimbus-api',
  providerVersion: process.env.GIT_SHA,
  stateHandlers: {
    'a task with ID task-123 exists': async () => {
      await seedTask({ id: 'task-123', title: 'Sample task' });
    },
  },
});
```

## Contract Broker

The Pact broker stores contracts and verification results:

- Consumer tests publish contracts on every PR build.
- Provider verification runs on every API PR and on `main`.
- The `can-i-deploy` check prevents deploying if contracts are not verified.

```bash
# Check if safe to deploy
pnpm pact:can-i-deploy --pacticipant nimbus-api --version $GIT_SHA
```

## CI Integration

Contract tests run as part of the CI pipeline:

1. Consumer contract tests run during the consumer's CI build.
2. Contracts are published to the Pact broker.
3. A webhook triggers provider verification.
4. The `can-i-deploy` check gates deployment.

## Breaking Change Detection

When a provider change would break a consumer contract:

1. The provider verification fails in CI.
2. The engineer identifies which consumer expectation broke.
3. Options: (a) coordinate the breaking change with the consumer team, (b) version the API endpoint, or (c) use the expand-contract pattern.

## See Also

- [API Tests](api-tests.md) — complementary API testing
- [API Design](../conventions/api-design.md) — API versioning conventions
- [CI Test Config](ci-test-config.md) — contract test pipeline configuration

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Pact version, broker configuration, or contract testing workflow changes -->
