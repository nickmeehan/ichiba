# Unit Testing

Unit tests verify individual functions, hooks, and components in isolation. They form the base of the testing pyramid and should be fast, focused, and deterministic.

## Jest Configuration

Nimbus uses Jest with the following configuration in `jest.config.ts`:

```typescript
export default {
  preset: 'ts-jest',
  testEnvironment: 'node', // 'jsdom' for React components
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.test.ts', '**/*.test.tsx'],
  moduleNameMapper: {
    '^@nimbus/(.*)$': '<rootDir>/../packages/$1/src',
  },
  setupFilesAfterSetup: ['<rootDir>/test/setup.ts'],
};
```

Each app (`api`, `web`, `worker`) has its own Jest config that extends the base.

## Test File Naming

Test files are colocated with the source files they test:

```
src/
├── services/
│   ├── task.service.ts
│   └── task.service.test.ts     # Unit tests
├── components/
│   ├── TaskCard.tsx
│   └── TaskCard.test.tsx         # Component tests
└── utils/
    ├── date.ts
    └── date.test.ts              # Utility tests
```

## Assertion Patterns

Use descriptive test names that explain the expected behavior:

```typescript
describe('TaskService.calculateDueDate', () => {
  it('returns the due date adjusted for business days', () => {
    const result = calculateDueDate(new Date('2026-03-15'), 5);
    expect(result).toEqual(new Date('2026-03-22'));
  });

  it('throws InvalidInputError when days is negative', () => {
    expect(() => calculateDueDate(new Date(), -1)).toThrow(InvalidInputError);
  });

  it('skips weekends when calculating business days', () => {
    // Friday + 1 business day = Monday
    const friday = new Date('2026-03-13');
    expect(calculateDueDate(friday, 1)).toEqual(new Date('2026-03-16'));
  });
});
```

Prefer `toEqual` for value comparisons, `toThrow` for error cases, and `toHaveBeenCalledWith` for verifying mock interactions.

## Coverage Thresholds

Minimum coverage thresholds are enforced in CI:

| Metric | Threshold |
|--------|-----------|
| Statements | 80% |
| Branches | 75% |
| Functions | 80% |
| Lines | 80% |

Coverage is measured per-package. New packages must meet thresholds from the first PR. Run `pnpm test:unit --coverage` to check locally.

## Snapshot Testing Policy

Snapshot tests are allowed only for:

- **Serialized output**: API response shapes, error message formats.
- **Small component renders**: Simple, stable components without dynamic content.

Snapshot tests are **not allowed** for:
- Large component trees (fragile, noisy diffs).
- Anything with timestamps, random IDs, or locale-dependent output.

When updating snapshots, review each change carefully. Never run `jest -u` without inspecting the diff.

## See Also

- [Mocking](mocking.md) — mock patterns for unit tests
- [Test Data](test-data.md) — creating test fixtures
- [CI Test Config](ci-test-config.md) — unit test execution in CI

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Jest version, coverage thresholds, or testing patterns change -->
