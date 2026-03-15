# Capacity Planning

Nimbus performs quarterly capacity planning to ensure infrastructure scales ahead of demand. Planning covers compute, storage, database, and network capacity across both regions, with projections based on historical growth and sales pipeline data.

## Growth Projections

Current growth metrics (updated quarterly):

| Metric | Current | 6-Month Projection | 12-Month Projection |
|--------|---------|--------------------|--------------------|
| Active tenants | 340 | 520 | 780 |
| Monthly active users | 28,000 | 45,000 | 72,000 |
| API requests/day | 12M | 20M | 35M |
| Database size (PostgreSQL) | 480 GB | 750 GB | 1.2 TB |
| Object storage (S3) | 2.1 TB | 3.5 TB | 6 TB |
| Events/day (ClickHouse) | 8M | 14M | 25M |

Projections use a combination of linear extrapolation from the past 6 months and input from the sales team on pipeline deals (particularly Enterprise tenants, which have outsized resource needs).

## Resource Scaling Thresholds

Auto-scaling is configured for compute resources. Manual scaling reviews are triggered when approaching the following thresholds:

| Resource | Scale-Up Threshold | Scale-Down Threshold | Action |
|----------|-------------------|---------------------|--------|
| API pods (CPU) | 70% avg for 5 min | 30% avg for 15 min | HPA adjusts replica count (min: 4, max: 20) |
| API pods (memory) | 80% avg for 5 min | 40% avg for 15 min | HPA adjusts replica count |
| Worker pods | Queue depth > 1000 | Queue depth < 100 | KEDA scales workers (min: 2, max: 12) |
| PostgreSQL CPU | 70% sustained | N/A | Vertical scale (requires maintenance window) |
| PostgreSQL connections | 80% of max | N/A | Increase PgBouncer pool or scale read replicas |
| Redis memory | 75% of instance size | N/A | Upgrade instance type |
| ClickHouse disk | 70% of volume | N/A | Expand volume or archive old data |

## Load Testing Cadence

Load tests run on a schedule and before major releases:

| Test Type | Frequency | Target | Tools |
|-----------|-----------|--------|-------|
| Baseline load test | Monthly | Verify steady-state performance at 2x current traffic | k6 |
| Spike test | Quarterly | Test 5x traffic burst for 10 minutes | k6 |
| Soak test | Quarterly | 48-hour run at 1.5x traffic to detect memory leaks | k6 |
| Pre-release test | Before each major release | Verify no performance regression vs. baseline | k6 |

Load tests run against a dedicated staging environment that mirrors production infrastructure at 50% scale. Results are compared against previous baselines, and regressions greater than 10% block the release.

## Infrastructure Budget

Annual infrastructure budget is reviewed quarterly:

| Category | Monthly Spend | % of Total | Notes |
|----------|-------------|-----------|-------|
| Compute (EKS) | $18,400 | 35% | Includes reserved instances |
| Database (RDS) | $12,200 | 23% | Multi-AZ, 1 primary + 2 read replicas |
| Storage (S3 + EBS) | $4,800 | 9% | Includes lifecycle policies |
| CDN (CloudFront) | $3,100 | 6% | Serving static assets and uploaded files |
| ClickHouse (self-hosted) | $5,600 | 11% | 3-node cluster per region |
| Redis (ElastiCache) | $2,900 | 6% | Cache + session store |
| Other (DNS, secrets, monitoring) | $5,200 | 10% | Datadog, PagerDuty, Route 53 |

Budget alerts fire when monthly spend exceeds 110% of the planned budget for any category.

## See Also

- [Cost Optimization](cost-optimization.md) for strategies to reduce infrastructure spend
- [SLAs](sla.md) for uptime targets that capacity must support
- [Disaster Recovery](disaster-recovery.md) for cross-region capacity requirements

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: quarterly capacity review is completed or infrastructure architecture changes -->
