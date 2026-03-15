# Blue-Green Deployment

Nimbus uses blue-green deployment to achieve zero-downtime production releases. This guide explains how the two environments work and how traffic is switched between them.

## Environment Switching

Nimbus maintains two identical production environments:

| Environment | Color | Purpose |
|------------|-------|---------|
| Production A | Blue or Green | Currently serving live traffic |
| Production B | Green or Blue | Receives the new deployment |

The "active" color is tracked in AWS Parameter Store at `/nimbus/production/active-color`. The deployment pipeline always deploys to the **inactive** environment.

## Traffic Routing

Traffic routing is managed by an AWS Application Load Balancer (ALB) with two target groups:

1. `nimbus-prod-blue` — ECS services in the blue environment
2. `nimbus-prod-green` — ECS services in the green environment

The ALB listener rule forwards 100% of traffic to the active target group. During a switch, the listener rule is updated atomically to point to the new target group. There is no period of split traffic (unlike canary deploys).

## Health Verification

Before switching traffic, the deployment pipeline verifies the new environment:

1. **Container health**: All ECS tasks are in `RUNNING` state with passing health checks.
2. **Application health**: `GET /health` returns 200 on all service instances.
3. **Dependency health**: Database connections, Redis connectivity, and S3 access confirmed.
4. **Warm-up**: A batch of synthetic requests is sent to prime caches and JIT compilation.

The switch only proceeds if all checks pass. If any check fails after 5 minutes, the deployment is aborted and the inactive environment is left in its failed state for investigation.

## Database Compatibility

Both environments connect to the **same database**. This means schema migrations must be backward-compatible:

- New columns must be nullable or have defaults.
- Column renames require the expand-contract pattern (add new, migrate data, remove old across separate deploys).
- Table drops must happen in a follow-up deploy after all code references are removed.

See [Data Migration](../data-migration.md) for the full expand-contract workflow.

## Cutover Checklist

Before approving the traffic switch:

- [ ] New environment health checks all passing
- [ ] Application version confirmed via `GET /version` endpoint
- [ ] Database migration status verified (`pnpm db:migrate:status`)
- [ ] Feature flags configured correctly for the new version
- [ ] Monitoring dashboards open and baseline metrics noted
- [ ] On-call engineer confirmed available for the next 2 hours

## See Also

- [Canary Deployment](canary.md) — gradual traffic shifting for high-risk changes
- [Rollback](rollback.md) — switching back to the previous environment
- [Production Deployment](production.md) — end-to-end deployment process

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: ALB configuration, ECS setup, or blue-green switching mechanism changes -->
