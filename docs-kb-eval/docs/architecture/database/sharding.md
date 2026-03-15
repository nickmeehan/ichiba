# Sharding Strategy

Nimbus currently operates on a single PostgreSQL database with read replicas. This document describes the planned sharding strategy for when the single-database architecture reaches its scaling limits. The design is documented now to inform current schema decisions and prevent future migration pain.

## When to Shard

The decision to implement sharding will be triggered by one or more of these conditions:

- Write throughput exceeds what a single primary can handle (estimated at ~10,000 writes/second).
- Total database size exceeds 2 TB, making backups and maintenance windows impractical.
- A single large tenant's data volume causes performance degradation for other tenants.

Current projections estimate this threshold will be reached at approximately 5,000 active workspaces or 500,000 total users.

## Shard Key Selection

The shard key is `tenant_id`. This choice is driven by:

1. **Query isolation**: Every application query is already scoped to a single tenant, so queries never need to span shards.
2. **Data locality**: All data for a workspace lives on the same shard, avoiding distributed joins.
3. **Even distribution**: UUIDs distribute uniformly across shards.

## Shard Topology

The planned topology uses a routing layer that maps each `tenant_id` to a shard:

```
Application
    |
    v
Shard Router (maps tenant_id -> shard)
    |
    +-- Shard 1 (tenants A-M)
    |      +-- Primary
    |      +-- Replica
    |
    +-- Shard 2 (tenants N-Z)
           +-- Primary
           +-- Replica
```

The shard mapping is stored in a lightweight metadata database that the router consults on connection establishment. The mapping is cached in memory with a TTL.

## Cross-Shard Queries

Because the shard key is `tenant_id` and all queries are tenant-scoped, cross-shard queries should be unnecessary for the application. The exceptions are:

- **Platform-wide admin queries**: Support tools that query across tenants will use a scatter-gather pattern, querying all shards in parallel and merging results.
- **Analytics**: ClickHouse handles analytics independently and is not affected by PostgreSQL sharding.

## Migration Path

The migration from a single database to sharded databases will follow this plan:

1. **Prepare**: Ensure all queries use the repository layer and are tenant-scoped. Audit for any queries that bypass tenant filtering.
2. **Split**: Use logical replication to copy tenant data to the target shard without downtime.
3. **Cutover**: Update the shard mapping for the migrated tenants and switch traffic. Verify data integrity.
4. **Cleanup**: Remove migrated data from the source database after a grace period.

Tenants will be migrated in batches, starting with the largest tenants to relieve pressure on the original database.

## Current Preparations

Even though sharding is not yet implemented, the following practices ensure a smooth future migration:

- All queries go through the repository layer with automatic tenant scoping.
- No cross-tenant joins exist in the codebase.
- Foreign keys reference only tables within the same tenant scope.
- The `tenant_id` column exists on every tenant-scoped table.

## See Also

- [Multi-Tenancy](../multi-tenancy.md) - Current tenant isolation implementation
- [Replication](./replication.md) - Current scaling strategy with read replicas
- [Schema](./schema.md) - Tenant_id column placement

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Sharding implementation begins or scaling thresholds change -->
