# Disaster Recovery

Nimbus maintains a disaster recovery (DR) plan to protect against regional outages, data corruption, and catastrophic failures. The plan is tested quarterly and covers failover procedures, data recovery, and stakeholder communication.

## RTO and RPO Targets

| Tier | Services | RTO (Recovery Time) | RPO (Recovery Point) |
|------|----------|--------------------|--------------------|
| Tier 1 (Critical) | API, Auth, Database | 15 minutes | 1 minute |
| Tier 2 (Important) | WebSocket, Search, CDN | 30 minutes | 5 minutes |
| Tier 3 (Supporting) | ETL, Reporting, Email | 4 hours | 1 hour |

- **RTO**: Maximum time from disaster declaration to service restoration.
- **RPO**: Maximum acceptable data loss measured in time before the disaster.

## Cross-Region Setup

Nimbus operates in two AWS regions with active-passive configuration:

| Component | Primary (us-east-1) | Secondary (eu-west-1) | Sync Method |
|-----------|--------------------|--------------------|-------------|
| PostgreSQL | RDS Multi-AZ primary | RDS cross-region read replica | Async replication (< 1 min lag) |
| Redis | ElastiCache primary | ElastiCache Global Datastore | Async replication (< 1 sec lag) |
| S3 | Primary bucket | Cross-Region Replication | Async (< 15 min lag) |
| ClickHouse | Primary cluster | Replica cluster | Custom CDC (< 5 min lag) |
| Kubernetes | Primary EKS cluster | Standby EKS cluster | GitOps (ArgoCD syncs manifests) |
| DNS | Route 53 health-checked routing | Automatic failover | Health check interval: 10 sec |

EU tenants are served from eu-west-1 as primary, with us-east-1 as their DR region. This ensures GDPR data residency compliance.

## Failover Procedures

### Automated Failover

Route 53 health checks monitor the primary region's API endpoint every 10 seconds. If 3 consecutive checks fail:

1. Route 53 automatically redirects DNS to the secondary region
2. PagerDuty fires a P1 alert to the on-call team
3. The secondary region's read replica is promoted to primary (automated via Lambda)

### Manual Failover

For scenarios requiring human judgment (e.g., data corruption):

1. On-call engineer declares disaster via PagerDuty incident
2. Run failover playbook: `nimbus-dr failover --region eu-west-1 --reason "data corruption in us-east-1"`
3. The playbook promotes the database replica, updates service discovery, and validates connectivity
4. Engineering lead confirms data integrity in the secondary region
5. Status page is updated with incident details

### Failback

After the primary region recovers:

1. Re-establish replication from the new primary to the original primary
2. Wait for replication to catch up (verify zero lag)
3. Schedule a maintenance window for failback
4. Execute failback during low-traffic hours (typically 03:00-05:00 UTC Sunday)
5. Monitor for 2 hours before declaring failback complete

## DR Testing Schedule

| Test Type | Frequency | Duration | Scope |
|-----------|-----------|----------|-------|
| Tabletop exercise | Monthly | 1 hour | Walk through scenarios with on-call team |
| Database failover drill | Quarterly | 2 hours | Promote read replica, verify data integrity |
| Full regional failover | Semi-annually | 4 hours | Complete failover to secondary region |
| Backup restoration test | Monthly | 1 hour | Restore from backup to isolated environment |

All DR tests produce a report documenting what worked, what failed, and action items for improvement.

## Communication Plan

During a disaster:

| Audience | Channel | Update Frequency | Owner |
|----------|---------|-----------------|-------|
| Engineering team | #ops-incidents Slack | Real-time | On-call engineer |
| Executive team | Email + Slack DM | Every 30 minutes | Engineering Manager |
| Affected tenants | Status page + email | Every 30 minutes | Customer Success |
| All tenants | Status page | When resolved | Customer Success |

The status page (`status.nimbus.io`) is hosted on a separate infrastructure provider (Atlassian Statuspage) to remain available during AWS outages.

## See Also

- [SLAs](sla.md) for uptime commitments that DR supports
- [On-Call](on-call.md) for who initiates failover procedures
- [GDPR](../data/gdpr.md) for data residency considerations in cross-region failover

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: DR test is completed or cross-region architecture changes -->
