# Backup Strategy

Nimbus maintains automated database backups to protect against data loss, support disaster recovery, and enable point-in-time recovery. This document covers the backup schedule, storage, and restore procedures.

## Automated Daily Backups

Full database backups run daily at 02:00 UTC using `pg_dump` in the custom format. Backups are compressed and encrypted before being stored in S3.

| Setting           | Value                              |
|-------------------|------------------------------------|
| Schedule          | Daily at 02:00 UTC                 |
| Format            | `pg_dump --format=custom`          |
| Compression       | Built-in pg_dump compression       |
| Encryption        | AES-256 with KMS-managed key       |
| Storage           | `s3://nimbus-backups-prod/daily/`   |
| Naming            | `nimbus-YYYY-MM-DD-HHMMSS.dump`    |

Backups typically complete in under 30 minutes for the current database size.

## Point-in-Time Recovery

In addition to daily full backups, WAL (Write-Ahead Log) segments are continuously archived to S3:

| Setting           | Value                                    |
|-------------------|------------------------------------------|
| WAL archiving     | Enabled via `archive_command`            |
| Archive destination| `s3://nimbus-backups-prod/wal/`          |
| Archive interval  | Every completed WAL segment (~16 MB)     |

With the combination of daily backups and continuous WAL archiving, the database can be restored to any point in time within the retention window. Recovery time objective (RTO) is under 1 hour.

## Cross-Region Backup

For disaster recovery, backups are replicated to a secondary AWS region:

| Source Region | Destination Region | Replication Method      |
|--------------|-------------------|--------------------------|
| us-east-1    | us-west-2         | S3 Cross-Region Replication |

This ensures that backups survive a complete regional outage.

## Restore Testing

Backup restores are tested monthly using an automated process:

1. The latest daily backup is restored to a temporary PostgreSQL instance.
2. Automated checks verify table counts, row counts for key tables, and data integrity.
3. A sample of application queries is run against the restored database to confirm usability.
4. The temporary instance is torn down.
5. A report is sent to the engineering team with the restore results and timing.

If a restore test fails, it is treated as a P1 incident and investigated immediately.

## Retention Policy

| Backup Type     | Retention Period |
|----------------|-----------------|
| Daily backups  | 30 days          |
| Weekly backups | 90 days          |
| Monthly backups| 1 year           |
| WAL archives   | 7 days           |

Weekly and monthly backups are promoted from the daily backup set. Old backups are automatically deleted by an S3 lifecycle policy.

## Restore Procedure

To restore from a backup:

```bash
# Restore from a specific daily backup
./scripts/db-restore.sh --backup nimbus-2026-03-14-020000.dump

# Point-in-time recovery to a specific timestamp
./scripts/db-restore.sh --pitr "2026-03-15 10:30:00 UTC"
```

The restore script handles downloading the backup from S3, decrypting it, creating a new database, and replaying WAL segments to the target timestamp.

## See Also

- [Replication](./replication.md) - Read replicas and failover
- [Secrets Management](../infrastructure/secrets.md) - Backup encryption key management
- [Monitoring](../infrastructure/monitoring.md) - Backup success/failure alerting

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Backup schedule changes or retention policies are updated -->
