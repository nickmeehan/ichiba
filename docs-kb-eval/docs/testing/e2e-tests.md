# E2E Testing

End-to-end tests verify complete user workflows through a real browser. Nimbus uses Playwright for E2E testing across Chromium, Firefox, and WebKit.

## Playwright Setup

Playwright is configured in `playwright.config.ts`:

```typescript
export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 4 : 1,
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
  webServer: {
    command: 'pnpm dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

Run E2E tests locally: `pnpm test:e2e`. Run a specific test: `pnpm test:e2e tests/e2e/task-creation.spec.ts`.

## Page Objects

E2E tests use the Page Object pattern to encapsulate page interactions:

```typescript
// tests/e2e/pages/TaskListPage.ts
export class TaskListPage {
  constructor(private page: Page) {}

  async goto(projectId: string) {
    await this.page.goto(`/projects/${projectId}/tasks`);
  }

  async createTask(title: string) {
    await this.page.getByRole('button', { name: 'New Task' }).click();
    await this.page.getByLabel('Title').fill(title);
    await this.page.getByRole('button', { name: 'Create' }).click();
  }

  async getTaskCount() {
    return this.page.getByTestId('task-row').count();
  }
}
```

Page objects live in `tests/e2e/pages/` and are imported into test files.

## Test Selectors

Use this priority order for selecting elements:

1. **`getByRole`**: Preferred. Tests what users and screen readers see.
2. **`getByLabel`**: For form inputs.
3. **`getByText`**: For visible text content.
4. **`getByTestId`**: Last resort. Add `data-testid` attributes only when semantic selectors are not feasible.

Never use CSS selectors or XPath in E2E tests. They are brittle and break on refactors.

## CI Configuration

E2E tests run in CI after the build step:

- Browsers are installed via `npx playwright install --with-deps` in the CI workflow.
- Tests run with 4 parallel workers and 2 retries for flaky test tolerance.
- On failure, Playwright generates traces and screenshots in `test-results/`.
- Traces are uploaded as CI artifacts and viewable at `trace.playwright.dev`.

## Screenshot Comparison

Playwright visual comparison is used for critical UI flows:

```typescript
await expect(page).toHaveScreenshot('dashboard-loaded.png', {
  maxDiffPixelRatio: 0.01,
});
```

Screenshot baselines are stored in `tests/e2e/__screenshots__/` and committed to the repo. Update baselines with `pnpm test:e2e --update-snapshots`.

## See Also

- [Visual Regression](visual-regression.md) — component-level visual testing
- [CI Test Config](ci-test-config.md) — E2E test parallelization in CI
- [Test Data](test-data.md) — seeding data for E2E tests

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Playwright version, browser targets, or CI E2E configuration changes -->
