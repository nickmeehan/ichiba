# Test Data

This guide covers patterns for creating realistic, maintainable test data in Nimbus, including factories, fixtures, and database seeding.

## Factory Pattern

Nimbus uses a factory pattern (inspired by `fishery`) to create test data. Factories are defined in `packages/test-utils/src/factories/`:

```typescript
// packages/test-utils/src/factories/task.factory.ts
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import { prisma } from '../prisma';

export const taskFactory = Factory.define<TaskCreateInput>(({ sequence }) => ({
  title: faker.lorem.sentence({ min: 3, max: 8 }),
  description: faker.lorem.paragraph(),
  priority: faker.helpers.arrayElement(['low', 'medium', 'high', 'urgent']),
  status: 'active',
  position: sequence,
}));
```

## Faker.js Usage

[Faker.js](https://fakerjs.dev/) generates realistic random data. Use it in factories for:

| Data type | Faker method |
|-----------|-------------|
| Person name | `faker.person.fullName()` |
| Email | `faker.internet.email()` |
| UUID | `faker.string.uuid()` |
| Date | `faker.date.recent({ days: 30 })` |
| Sentence | `faker.lorem.sentence()` |
| Paragraph | `faker.lorem.paragraph()` |

Seed faker for deterministic tests: `faker.seed(12345)` in your test setup file.

## Test Fixtures

For complex scenarios requiring a specific data shape, use JSON fixtures in `tests/fixtures/`:

```
tests/fixtures/
├── project-with-tasks.json       # Project with 10 tasks in various states
├── billing-scenario.json         # Tenant with subscription and invoices
└── import-csv-sample.csv         # CSV for testing import functionality
```

Load fixtures in tests:

```typescript
import projectFixture from '../../fixtures/project-with-tasks.json';

beforeEach(async () => {
  await seedFromFixture(projectFixture);
});
```

## Database Seeding

The seed script (`packages/db/prisma/seed.ts`) creates a standard development dataset. For tests, use the lightweight seeder:

```typescript
import { seedTestDatabase } from '@nimbus/test-utils';

// Creates: 1 tenant, 1 admin user, 1 member user, 1 project
await seedTestDatabase();
```

The test seeder is intentionally minimal. Individual tests add the specific data they need using factories.

## Data Builders

For complex object graphs, use builders that chain factory calls:

```typescript
const scenario = await new TestScenarioBuilder()
  .withTenant({ name: 'Acme Corp', plan: 'enterprise' })
  .withUsers(5)
  .withProjects(3)
  .withTasksPerProject(20)
  .build();

// Access: scenario.tenant, scenario.users[0], scenario.projects[1].tasks[5]
```

Builders handle foreign key relationships and ensure referential integrity.

## Best Practices

- **Override only what matters**: Use factory defaults for fields not relevant to the test. Override only the fields being tested.
- **Avoid shared state**: Each test should create its own data. Never rely on data from another test.
- **Keep factories simple**: Factories should produce valid, minimal objects. Use builders for complex scenarios.
- **Clean up**: The `createTestContext().reset()` helper truncates all tables between tests.

## See Also

- [Unit Tests](unit-tests.md) — using factories in unit tests
- [Integration Tests](integration-tests.md) — database seeding for integration tests
- [Mocking](mocking.md) — when to use test data vs. mocks

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: factory library, faker version, or test data patterns change -->
