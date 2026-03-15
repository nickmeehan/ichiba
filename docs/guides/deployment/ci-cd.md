# CI/CD Pipeline

Nimbus uses GitHub Actions for continuous integration and deployment. This guide covers the pipeline stages, configuration, and troubleshooting.

## GitHub Actions Workflows

The pipeline is defined in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Every PR | Lint, type-check, test, build |
| `deploy-staging.yml` | Merge to `main` | Deploy to staging environment |
| `deploy-production.yml` | Manual dispatch | Deploy to production |
| `nightly.yml` | Cron (2 AM ET) | Full E2E suite, dependency audit |

## Build Steps

The CI workflow runs these steps in order:

1. **Install**: `pnpm install --frozen-lockfile` (cached via `actions/cache`)
2. **Lint**: `pnpm lint` (ESLint across all packages)
3. **Type-check**: `pnpm typecheck` (TypeScript strict mode)
4. **Unit tests**: `pnpm test:unit` (Jest, parallelized across 4 shards)
5. **Integration tests**: `pnpm test:integration` (requires test database)
6. **Build**: `pnpm build` (Turbo build with remote caching)
7. **E2E tests**: `pnpm test:e2e` (Playwright, 3 browser targets)

## Test Stages

Tests run in parallel where possible:

```
lint ──────────┐
typecheck ─────┤
unit-tests ────┼── build ── e2e-tests ── deploy
integration ───┘
```

Unit tests are sharded across 4 runners using `jest --shard`. E2E tests run on Chromium, Firefox, and WebKit in parallel.

## Artifact Publishing

On successful build, the pipeline:

1. Builds Docker images for `api`, `web`, and `worker`.
2. Tags images with the Git SHA and `latest`.
3. Pushes to AWS ECR: `123456789.dkr.ecr.us-east-1.amazonaws.com/nimbus-<app>`.

## Deployment Triggers

- **Staging**: Automatic on merge to `main`.
- **Production**: Manual trigger via GitHub Actions UI or `/deploy production` in Slack (via Slackbot integration).
- **Hotfix**: The `deploy-production.yml` workflow accepts a `ref` parameter for deploying specific commits.

## Troubleshooting

Common CI failures:

- **Flaky E2E tests**: Re-run the workflow. If a test fails 3+ times in a week, file a bug with the `flaky-test` label.
- **Cache miss**: Turbo remote cache occasionally misses. A full rebuild takes ~8 minutes.
- **Docker build OOM**: Increase the runner memory in the workflow file (`runs-on: ubuntu-latest-8core`).

## See Also

- [Staging](staging.md) — staging environment details
- [Production Deployment](production.md) — production deploy checklist
- [CI Test Config](../../testing/ci-test-config.md) — test splitting and reporting

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: GitHub Actions workflows, build tools, or CI infrastructure changes -->
