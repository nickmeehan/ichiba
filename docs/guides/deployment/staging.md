# Staging Environment

The staging environment mirrors production as closely as possible and serves as the final validation step before production deployment.

## Staging URL

| Service | URL |
|---------|-----|
| Web app | `https://staging.nimbus.io` |
| API | `https://staging-api.nimbus.io` |
| Storybook | `https://staging-storybook.nimbus.io` |

Access requires VPN connection or allowlisted IP. All team members have staging credentials in 1Password under "Nimbus Staging".

## Data Refresh Schedule

Staging data is refreshed from a sanitized production snapshot every Sunday at 3 AM ET:

1. Production database is backed up.
2. PII is scrubbed (emails, names, phone numbers replaced with faker data).
3. Passwords are reset to `staging-password-123`.
4. Sanitized snapshot is restored to the staging database.

If you need a manual refresh, run: `pnpm ops:staging-refresh` (requires DevOps role).

## Staging-Specific Configuration

Staging uses separate instances of external services:

| Service | Staging config |
|---------|---------------|
| Stripe | Test mode (`sk_test_*` keys) |
| SendGrid | Sandbox mode (emails logged, not sent) |
| LaunchDarkly | `staging` environment |
| S3 | `nimbus-staging-uploads` bucket |
| Redis | Separate ElastiCache cluster |

Environment variables are managed in AWS Parameter Store under `/nimbus/staging/`.

## QA Process

After a staging deployment:

1. **Automated smoke tests** run automatically (Playwright suite tagged `@smoke`).
2. **Manual QA** is performed by the QA engineer for feature PRs. QA creates test cases in Linear.
3. **Product review** happens for user-facing changes. The PM verifies acceptance criteria.

## Sign-Off Requirements

Before promoting to production, staging must have:

- [ ] All automated tests passing (CI green)
- [ ] QA sign-off comment on the release ticket
- [ ] PM sign-off for user-facing changes
- [ ] No open P0/P1 bugs linked to the release

Sign-off is tracked in the `#nimbus-deploys` Slack channel using the deploy bot.

## See Also

- [Production Deployment](production.md) — promoting from staging to production
- [CI/CD Pipeline](ci-cd.md) — how code reaches staging
- [E2E Tests](../../testing/e2e-tests.md) — automated test configuration

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: staging infrastructure, data refresh process, or QA workflow changes -->
