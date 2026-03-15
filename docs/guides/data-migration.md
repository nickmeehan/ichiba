# Data Migration

This guide covers how to safely migrate, transform, and backfill data in the Nimbus multi-tenant platform without downtime or data loss.

## Migration Playbook

Every data migration follows this process:

1. **Plan**: Document the migration in an ADR (Architecture Decision Record) with schema changes, data transformations, and rollback strategy.
2. **Script**: Write the migration in `packages/db/prisma/migrations/` for schema changes, or in `scripts/migrations/` for data backfills.
3. **Test**: Run the migration against a copy of production data in the staging environment.
4. **Review**: Get approval from the tech lead and DevOps lead.
5. **Execute**: Run during the designated migration window (see below).
6. **Validate**: Run validation scripts to confirm data integrity.
7. **Clean up**: Remove temporary columns, tables, or backfill scripts after the migration stabilizes.

## Tenant Data Migration

Multi-tenant migrations require extra care to avoid cross-tenant data contamination:

- Always include a `WHERE tenant_id = ?` clause in update and delete statements.
- Process tenants in batches of 10, with a configurable delay between batches.
- Log each tenant's migration status to the `migration_runs` table for auditability.

```typescript
for (const tenant of tenants) {
  await migrateTenant(tenant.id, { batchSize: 500, delayMs: 200 });
  await logMigrationRun(migrationId, tenant.id, 'completed');
}
```

## Zero-Downtime Data Changes

For schema changes that touch live tables, use the expand-contract pattern:

1. **Expand**: Add the new column (nullable) or new table. Deploy code that writes to both old and new locations.
2. **Migrate**: Backfill existing data from the old location to the new one.
3. **Contract**: Switch reads to the new location. Remove writes to the old location. Drop the old column after a stabilization period.

Never rename or remove a column in a single deployment. The API server runs multiple versions during rolling deploys, so both old and new code must work with the current schema.

## Validation Scripts

Every migration must have a corresponding validation script in `scripts/migrations/validate/`:

```bash
# Run validation after migration
pnpm migration:validate 20260315_add_task_dependencies

# Output:
# ✓ All tasks.dependency_ids reference valid task IDs
# ✓ No orphaned dependency records
# ✓ Tenant isolation verified (0 cross-tenant references)
# ✓ Row counts match pre-migration snapshot
```

## Rollback Procedures

Prisma migrations are forward-only by default. For rollback:

1. **Schema rollback**: Create a new migration that reverses the schema change (`pnpm db:migrate:create rollback_<name>`).
2. **Data rollback**: Restore from the pre-migration snapshot taken automatically by the migration runner.
3. **Emergency rollback**: If the migration causes an outage, restore the database from the most recent point-in-time backup (RPO: 1 minute).

Always test rollback in staging before running the migration in production.

## See Also

- [Database Conventions](../conventions/database-conventions.md) — naming and schema standards
- [Production Deployment](deployment/production.md) — deployment windows for migrations
- [Incident Response](incident-response.md) — escalation if a migration causes issues

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: migration tooling, Prisma version, or backup strategy changes -->
