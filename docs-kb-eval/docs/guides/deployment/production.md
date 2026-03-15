# Production Deployment

This guide covers the process for deploying Nimbus to production, including the pre-deployment checklist, deployment windows, and post-deployment verification.

## Deployment Checklist

Before initiating a production deployment:

- [ ] All CI checks are green on the release commit.
- [ ] Staging QA sign-off is complete.
- [ ] Database migrations (if any) have been tested in staging.
- [ ] Feature flags are configured for any partially-rolled-out features.
- [ ] The `#nimbus-deploys` channel has been notified with the release scope.
- [ ] At least one engineer is available to monitor for the next 2 hours.

## Deployment Windows

| Day | Window (ET) | Notes |
|-----|------------|-------|
| Monday-Thursday | 10 AM - 3 PM | Standard deployment window |
| Friday | 10 AM - 12 PM | Reduced window; no risky deploys |
| Weekends/Holidays | Emergency only | Requires VP Engineering approval |

Avoid deploying during peak usage hours (8-10 AM ET) or within 2 hours of the end of business day.

## Deployment Process

1. **Trigger**: Run the `deploy-production` workflow from GitHub Actions, selecting the staging-verified commit SHA.
2. **Blue-green switch**: The new version deploys to the inactive environment. See [Blue-Green Deployment](blue-green.md).
3. **Health checks**: Automated health checks verify all services are responding.
4. **Traffic switch**: Load balancer switches traffic to the new environment.
5. **Smoke tests**: Automated smoke test suite runs against production.

## Health Checks

Each service exposes a health endpoint:

| Service | Endpoint | Checks |
|---------|----------|--------|
| API | `GET /health` | Database connectivity, Redis connectivity, S3 access |
| Web | `GET /api/health` | API reachability, auth service |
| Worker | BullMQ dashboard | Queue processing, job completion rate |

A deployment is rolled back automatically if health checks fail for more than 3 consecutive minutes.

## Smoke Tests

Post-deployment smoke tests verify critical user paths:

1. User login and session creation
2. Project listing and task creation
3. File upload and download
4. Webhook delivery (Stripe test event)
5. Background job processing (email send)

Results are posted to `#nimbus-deploys`.

## Monitoring During Deploy

During and after deployment, monitor these Datadog dashboards:

- **Nimbus > Production Overview**: Error rate, latency p50/p95/p99, request volume.
- **Nimbus > Infrastructure**: CPU, memory, pod restarts, database connections.
- **Nimbus > Business Metrics**: Sign-ups, task creation rate, API usage by tenant.

Stay vigilant for 2 hours post-deploy. If error rate exceeds 1% or p99 latency exceeds 2 seconds, initiate [rollback](rollback.md).

## See Also

- [Rollback](rollback.md) — reverting a bad production deploy
- [Blue-Green Deployment](blue-green.md) — environment switching details
- [Incident Response](../incident-response.md) — escalation if deploy causes an incident

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: deployment process, health check endpoints, or monitoring dashboards change -->
