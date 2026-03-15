# Rollback Procedures

This guide covers how to revert a failed production deployment, including automated triggers, manual steps, and database rollback considerations.

## Automated Rollback Triggers

The deployment pipeline automatically initiates a rollback when:

- Health checks fail for 3+ consecutive minutes after traffic switch.
- Error rate exceeds 5% within the first 10 minutes post-deploy.
- P99 latency exceeds 5 seconds for 5+ consecutive minutes.

Automated rollbacks switch traffic back to the previous blue-green environment. No manual intervention is required, but the on-call engineer is paged to investigate.

## Manual Rollback Steps

If automated rollback does not trigger but you observe degraded behavior:

1. **Announce** in `#nimbus-incidents`: "Initiating manual rollback of deploy <SHA>."
2. **Switch traffic** back to the previous environment:
   ```bash
   pnpm ops:rollback --env production
   ```
3. **Verify** health checks pass on the rolled-back environment.
4. **Monitor** error rates and latency for 15 minutes.
5. **Update** `#nimbus-deploys` with rollback confirmation and link to investigation ticket.

The `ops:rollback` script handles ALB target group switching and ECS service updates.

## Database Rollback

Database rollbacks are more complex because schema changes may not be backward-compatible:

### Schema-Compatible Changes

If the migration only added nullable columns or new tables (no breaking changes), the previous application version can run against the new schema safely. No database rollback is needed.

### Breaking Schema Changes

If the migration renamed or removed columns:

1. Run the reverse migration script (prepared during the migration planning phase).
2. If no reverse migration exists, restore from the pre-deploy database snapshot.
3. Point-in-time recovery is available with 1-minute granularity via AWS RDS.

**Warning**: Restoring a database snapshot will lose all data written after the snapshot. Coordinate with the incident lead before proceeding.

## Cache Invalidation

After a rollback, clear caches to prevent stale data:

```bash
# Flush Redis cache
pnpm ops:cache-flush --env production --prefix nimbus:cache:

# Invalidate CDN cache
pnpm ops:cdn-invalidate --env production --path "/*"
```

Do not flush the Redis job queue (`nimbus:bull:*`) unless background jobs are also affected.

## Communication

After a rollback:

1. Update the status page if customers were affected.
2. Post a summary in `#nimbus-incidents` with the timeline and root cause hypothesis.
3. Create a Linear ticket for the root cause investigation.
4. If this was a P0/P1, schedule a post-incident review within 5 business days.

## See Also

- [Production Deployment](production.md) — the forward deployment process
- [Blue-Green Deployment](blue-green.md) — how environment switching works
- [Incident Response](../incident-response.md) — full incident management process

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: rollback automation, database backup strategy, or cache infrastructure changes -->
