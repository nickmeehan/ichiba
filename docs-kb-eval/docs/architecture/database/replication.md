# Database Replication

Nimbus uses PostgreSQL streaming replication to maintain read replicas for analytics queries and to provide a failover target for high availability. This document covers the replication topology, connection routing, and failover procedures.

## Replication Topology

The production database runs a single primary instance and two read replicas:

```
Primary (us-east-1a)
  |
  +-- Replica 1 (us-east-1b) - Analytics queries
  |
  +-- Replica 2 (us-east-1c) - Read scaling and failover standby
```

Replication is asynchronous with a typical lag of under 100 milliseconds. For the rare cases where a read must reflect the absolute latest write (e.g., reading a task immediately after creating it), the query is routed to the primary.

## Streaming Replication Setup

Replication is configured using PostgreSQL's built-in streaming replication:

1. The primary has `wal_level = replica` and `max_wal_senders = 10` in `postgresql.conf`.
2. Replicas connect using a dedicated replication user with the `REPLICATION` privilege.
3. WAL segments are streamed continuously. If a replica falls behind, it catches up by replaying buffered WAL.

WAL archiving to S3 is also enabled for point-in-time recovery, which serves as a backup mechanism independent of the replicas.

## Connection Routing

The Nimbus backend uses a connection manager that routes queries based on their type:

| Query Type          | Target   | Example                              |
|--------------------|----------|--------------------------------------|
| INSERT/UPDATE/DELETE| Primary  | Creating or modifying a task         |
| SELECT (default)   | Replica  | Fetching a task list                 |
| SELECT (read-after-write) | Primary | Reading a resource just created |
| Analytics queries  | Replica 1| Dashboard and report queries         |

The read-after-write routing uses a session-level flag set by the service layer after a write operation. The flag expires after 5 seconds, after which reads resume using replicas.

## Failover

If the primary becomes unavailable:

1. The health check system detects the failure within 30 seconds.
2. Replica 2 is promoted to primary using `pg_promote()`.
3. DNS is updated to point the primary endpoint to the new primary.
4. The application reconnects automatically through the connection pool's retry logic.
5. The old primary is rebuilt as a new replica once it recovers.

Failover is tested quarterly using a chaos engineering exercise that simulates primary failure during business hours.

## Monitoring

Replication lag is monitored via `pg_stat_replication` on the primary and reported as a Prometheus gauge. An alert fires if any replica falls more than 5 seconds behind.

## See Also

- [Backups](./backups.md) - WAL archiving for point-in-time recovery
- [Sharding](./sharding.md) - Future scaling beyond replication
- [Monitoring](../infrastructure/monitoring.md) - Replication lag dashboards

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Replication topology changes or failover procedures are updated -->
