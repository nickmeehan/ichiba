# Canary Deployment

For high-risk changes, Nimbus supports canary deployment where a small percentage of traffic is routed to the new version before a full rollout.

## Traffic Splitting

Canary deployments use AWS ALB weighted target groups to split traffic:

| Phase | Canary traffic | Duration | Criteria to advance |
|-------|---------------|----------|-------------------|
| Phase 1 | 5% | 15 minutes | Error rate < 0.5%, p99 < 1s |
| Phase 2 | 25% | 30 minutes | Error rate < 0.5%, p99 < 1.5s |
| Phase 3 | 50% | 30 minutes | Error rate < 0.5%, p99 < 2s |
| Phase 4 | 100% | - | Full rollout complete |

Traffic splitting is managed by the `canary-controller` service running in the ECS cluster.

## Canary Metrics

The canary controller monitors these metrics (via Datadog) to determine promotion readiness:

- **Error rate**: Percentage of 5xx responses from canary instances vs. baseline.
- **Latency**: p50, p95, and p99 latency compared to baseline instances.
- **Saturation**: CPU and memory utilization on canary instances.
- **Business metrics**: Task creation rate, API call volume (should not drop significantly).

Metrics are compared using a rolling 5-minute window. The canary is considered healthy if all metrics are within thresholds for the full phase duration.

## Promotion Criteria

A canary is promoted to the next phase automatically when:

1. All health checks pass consistently.
2. Error rate delta between canary and baseline is < 0.1 percentage points.
3. Latency p99 delta is < 200ms.
4. No alerts have fired for the canary environment.

Manual override is available for the deploy engineer:

```bash
# Force promote to next phase
pnpm ops:canary promote --env production

# Skip directly to 100%
pnpm ops:canary promote --env production --full
```

## Automatic Rollback Thresholds

The canary is rolled back automatically if:

- Error rate exceeds 2% on canary instances (absolute, not delta).
- P99 latency exceeds 5 seconds on canary instances.
- Any canary instance fails health checks for 2+ minutes.
- Memory usage exceeds 90% on any canary instance.

On rollback, all traffic returns to the baseline environment and the deploy engineer is notified via PagerDuty.

## When to Use Canary

Use canary deployment for:

- Database schema migrations that could affect query performance.
- Changes to authentication or authorization logic.
- Major refactors of high-traffic API endpoints.
- Infrastructure-level changes (Node.js version upgrades, dependency bumps).

For routine feature development, standard blue-green deployment is sufficient.

## See Also

- [Blue-Green Deployment](blue-green.md) — standard deployment strategy
- [Feature Flags](../feature-flags.md) — application-level gradual rollout
- [Production Deployment](production.md) — overall deployment process

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: canary controller configuration, promotion thresholds, or ALB setup changes -->
