# Database Migrations

Nimbus uses Knex.js for database migrations. Migrations are stored in the `tools/migrations/` directory and run as part of the deployment pipeline. This document covers conventions, zero-downtime practices, and rollback procedures.

## Naming Convention

Migration files follow a timestamp-based naming pattern:

```
YYYYMMDDHHMMSS_descriptive_name.ts
```

Examples:
- `20260301120000_create_tasks_table.ts`
- `20260305093000_add_due_date_to_tasks.ts`
- `20260310141500_create_audit_logs_table.ts`

The timestamp prefix ensures migrations run in chronological order regardless of branch merge order.

## Creating a Migration

```bash
pnpm run db:migrate:make add_priority_to_tasks
```

This generates a new migration file with `up` and `down` methods:

```typescript
export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable('tasks', (table) => {
    table.string('priority', 10).defaultTo('medium');
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable('tasks', (table) => {
    table.dropColumn('priority');
  });
}
```

## Zero-Downtime Migrations

Because the application runs on multiple pods with rolling deployments, migrations must be backward-compatible with the currently running application version. This means:

1. **Adding a column**: Add with a default value or as nullable. The old code ignores the new column.
2. **Removing a column**: First deploy code that stops reading the column, then remove it in a subsequent migration.
3. **Renaming a column**: Create the new column, backfill data, deploy code using the new column, then drop the old column.
4. **Adding a NOT NULL constraint**: Add the column as nullable, backfill, then add the constraint in a separate migration.

Never drop a column or add a NOT NULL constraint in the same deployment as the code that depends on the change.

## Running Migrations

```bash
# Run pending migrations
pnpm run db:migrate

# Roll back the last batch
pnpm run db:migrate:rollback

# Check migration status
pnpm run db:migrate:status
```

In production, migrations run automatically during the deployment pipeline before the new application version is rolled out.

## Seed Data

Development seed data is managed separately from migrations:

```bash
pnpm run db:seed
```

Seeds create a default workspace, admin user, sample projects, and tasks for local development. Seeds are idempotent and can be run multiple times without creating duplicates.

## Rollback Procedures

If a migration causes issues in production:

1. Deploy the previous application version (code rollback).
2. Run `pnpm run db:migrate:rollback` to reverse the last migration batch.
3. Investigate and fix the migration before re-deploying.

Rollbacks are only safe if the `down` method accurately reverses the `up` method. Every migration must have a tested `down` implementation.

## See Also

- [Schema](./schema.md) - Current database table definitions
- [Queries](./queries.md) - Query patterns used with the schema
- [Backups](./backups.md) - Point-in-time recovery as a rollback alternative

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Migration tooling changes or new zero-downtime patterns are adopted -->
