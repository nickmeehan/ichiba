# Cost Optimization

Nimbus infrastructure costs are reviewed monthly and optimized quarterly. The goal is to maintain cost efficiency without compromising reliability or performance. Current annual infrastructure spend is approximately $625,000 with a target of keeping cost-per-tenant below $150/month.

## Reserved Instances

Reserved instances provide significant savings for predictable baseline workloads:

| Service | Instance Type | Commitment | Savings vs On-Demand |
|---------|-------------|-----------|---------------------|
| RDS PostgreSQL | db.r6g.2xlarge | 1-year all-upfront | 42% |
| ElastiCache Redis | cache.r6g.xlarge | 1-year partial-upfront | 38% |
| EKS node group (baseline) | m6g.2xlarge x 4 | 1-year compute savings plan | 35% |

Reserved capacity covers the steady-state baseline. Peak demand above the baseline is handled by on-demand instances. Reservations are reviewed every 6 months and adjusted based on actual utilization data from AWS Cost Explorer.

## Spot Instances for Batch Jobs

Non-critical batch workloads run on EC2 Spot Instances for up to 70% savings:

| Workload | Spot Suitable | Fallback |
|----------|-------------|----------|
| ETL pipeline workers | Yes | On-demand with 2-minute interruption notice handling |
| Report generation | Yes | Queued for next available spot instance |
| Search index rebuilds | Yes | On-demand if spot unavailable for > 30 min |
| Load testing | Yes | No fallback, test is retried |
| API serving | No | N/A -- reliability requires on-demand or reserved |
| Database | No | N/A -- data integrity requires stable instances |

Spot workers use Temporal's activity heartbeat mechanism to checkpoint progress. If a spot instance is reclaimed, the activity resumes on a new instance from the last checkpoint.

## Storage Tiering

S3 storage uses lifecycle policies to move data to cheaper tiers:

| Age | Storage Class | Cost per GB/month |
|-----|-------------|------------------|
| 0-30 days | S3 Standard | $0.023 |
| 30-90 days | S3 Standard-IA | $0.0125 |
| 90-365 days | S3 Glacier Instant Retrieval | $0.004 |
| 365+ days | S3 Glacier Deep Archive | $0.00099 |

This applies to:
- User-uploaded file attachments
- Generated report PDFs
- Database backups
- ETL pipeline artifacts

Active project attachments are excluded from tiering and remain in S3 Standard regardless of age (detected via access frequency).

## CDN Optimization

CloudFront costs are optimized through:

1. **Cache hit ratio**: Target > 95%. Achieved by setting appropriate `Cache-Control` headers on static assets (1 year for hashed filenames, 5 minutes for HTML).
2. **Compression**: Brotli compression enabled for text-based assets, reducing transfer size by 20-30% compared to gzip.
3. **Image optimization**: CloudFront Functions resize and convert images to WebP/AVIF on the fly, reducing origin egress.
4. **Price class**: Using Price Class 200 (US, Europe, Asia) rather than Price Class All, saving 15% by excluding less-used edge locations.

## Monitoring Costs

- **AWS Cost Explorer**: Reviewed weekly by the on-call engineer for anomalies
- **Budget alerts**: Fire at 80%, 90%, and 100% of monthly budget per service
- **Cost allocation tags**: Every resource is tagged with `team`, `service`, and `environment` for granular cost tracking
- **Quarterly review**: Engineering and finance review trends, identify optimization opportunities, and adjust budgets

## See Also

- [Capacity Planning](capacity-planning.md) for infrastructure budget and growth projections
- [Disaster Recovery](disaster-recovery.md) for cross-region cost implications
- [ETL Pipelines](../data/etl-pipelines.md) for batch workloads that run on spot instances

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: AWS pricing changes, new services are adopted, or annual budget review occurs -->
