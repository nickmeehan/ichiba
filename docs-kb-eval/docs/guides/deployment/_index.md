# Deployment Guides

Guides for deploying Nimbus to staging and production environments, including CI/CD pipeline configuration, rollback procedures, and advanced deployment strategies.

## Available Guides

| Guide | When to use it |
|-------|---------------|
| [CI/CD Pipeline](ci-cd.md) | You need to understand or modify the GitHub Actions build and deploy pipeline. |
| [Staging](staging.md) | You need to deploy to staging, run QA, or troubleshoot staging-specific issues. |
| [Production](production.md) | You are deploying to production and need to follow the deployment checklist. |
| [Rollback](rollback.md) | A deployment went wrong and you need to revert to the previous version quickly. |
| [Blue-Green](blue-green.md) | You need to understand or manage the blue-green environment switching process. |
| [Canary](canary.md) | You are rolling out a risky change incrementally using canary deployment. |

## Deployment Overview

Nimbus follows a continuous deployment model:

1. Code merges to `main` trigger the CI/CD pipeline.
2. Successful builds auto-deploy to **staging**.
3. After QA sign-off, a manual promotion deploys to **production** using blue-green switching.
4. High-risk changes use **canary deployment** with gradual traffic shifting.

## See Also

- [Incident Response](../incident-response.md) — handling deployment failures
- [Feature Flags](../feature-flags.md) — decoupling deploy from release
- [CI Test Config](../../testing/ci-test-config.md) — test pipeline configuration

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: deployment strategy or infrastructure changes -->
