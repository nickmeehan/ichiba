# Testing

Testing strategies, tools, and configuration for the Nimbus platform. Every feature must have appropriate test coverage before merging to `main`.

## Available Guides

| Guide | When to use it |
|-------|---------------|
| [Unit Tests](unit-tests.md) | You are writing isolated tests for functions, hooks, or components. |
| [Integration Tests](integration-tests.md) | You need to test interactions between services, APIs, and the database. |
| [E2E Tests](e2e-tests.md) | You are testing complete user workflows through the browser. |
| [API Tests](api-tests.md) | You are testing REST API endpoints with request/response validation. |
| [Load Tests](load-tests.md) | You need to verify performance under expected or peak traffic. |
| [Contract Tests](contract-tests.md) | You are changing an API and need to verify consumer compatibility. |
| [Visual Regression](visual-regression.md) | You are modifying UI components and need to catch unintended visual changes. |
| [Test Data](test-data.md) | You need to create realistic test data using factories and fixtures. |
| [Mocking](mocking.md) | You need to mock dependencies, APIs, or external services in tests. |
| [CI Test Config](ci-test-config.md) | You need to configure or troubleshoot test execution in CI. |

## Testing Pyramid

Nimbus follows the testing pyramid with emphasis on unit and integration tests:

```
      /  E2E  \          ~50 tests, slow, high confidence
     / API tests \       ~200 tests, medium speed
    / Integration  \     ~500 tests, medium speed
   /   Unit tests    \   ~2000 tests, fast, high volume
```

## Running Tests

```bash
pnpm test              # Run all tests
pnpm test:unit         # Unit tests only (Jest)
pnpm test:integration  # Integration tests (Jest + test DB)
pnpm test:e2e          # E2E tests (Playwright)
pnpm test:api          # API tests (supertest)
```

## See Also

- [CI/CD Pipeline](../guides/deployment/ci-cd.md) — test execution in CI
- [Code Review](../guides/code-review.md) — test coverage expectations during review
- [Conventions](../conventions/_index.md) — coding standards that affect test patterns

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: testing tools, test commands, or testing strategy changes -->
