# SLAs

Nimbus commits to service level agreements (SLAs) for all paid plans. SLAs define uptime targets, response time guarantees, and error rate thresholds. These commitments are backed by service level credits and measured by independent monitoring.

## Uptime Targets

| Plan | Uptime SLA | Allowed Downtime (monthly) | Allowed Downtime (annual) |
|------|-----------|---------------------------|--------------------------|
| Starter | 99.5% | 3h 39m | 1d 19h 49m |
| Business | 99.9% | 43m 49s | 8h 45m 56s |
| Enterprise | 99.95% | 21m 54s | 4h 22m 58s |

Uptime is measured as the percentage of time the API returns successful health check responses from three external monitoring locations (US East, EU West, AP Southeast). Scheduled maintenance windows (announced 72 hours in advance) are excluded from calculations.

## Response Time Targets

API response time SLAs measured at the load balancer:

| Metric | Starter | Business | Enterprise |
|--------|---------|----------|------------|
| p50 latency | < 200ms | < 150ms | < 100ms |
| p95 latency | < 1s | < 500ms | < 300ms |
| p99 latency | < 3s | < 2s | < 1s |

These targets apply to standard CRUD operations. Reporting queries, file uploads, and export operations have separate, longer thresholds documented in each endpoint's API specification.

## Error Rate Thresholds

The platform-wide error rate (5xx responses as a percentage of total requests) must remain below:

- **Starter**: < 1.0%
- **Business**: < 0.5%
- **Enterprise**: < 0.1%

Error rates are calculated over 5-minute rolling windows. A sustained breach (more than 15 minutes) counts as a service degradation incident.

## SLA Reporting

SLA compliance is reported to tenants through:

1. **Status page**: `https://status.nimbus.io` shows real-time and historical uptime, updated every 60 seconds by Datadog Synthetics.
2. **Monthly SLA report**: Automatically generated on the 1st of each month and emailed to tenant admins on Business and Enterprise plans. Includes uptime percentage, incident summary, and latency percentile charts.
3. **API endpoint**: `GET /api/v1/admin/sla-report` returns SLA metrics for the current and previous billing periods (Enterprise plan only).

## SLA Credit Policy

When Nimbus fails to meet the uptime SLA, affected tenants receive service credits:

| Uptime Achieved | Credit (% of monthly bill) |
|----------------|---------------------------|
| 99.0% - 99.9% | 10% |
| 95.0% - 99.0% | 25% |
| 90.0% - 95.0% | 50% |
| Below 90.0% | 100% |

Credits are applied automatically to the next billing cycle. They do not apply to incidents caused by:
- Customer-initiated actions (e.g., misconfigured webhooks causing load)
- Force majeure events
- Scheduled maintenance within announced windows
- Third-party service outages outside Nimbus's control

Tenants must report SLA breaches within 30 days to receive credits. Enterprise tenants have a dedicated support channel for SLA inquiries.

## Error Budget

The engineering team uses error budgets derived from SLA targets to balance reliability and velocity:

- **99.9% SLA = 43 minutes of allowed downtime per month**
- If more than 50% of the error budget is consumed by the 15th of the month, a reliability review is triggered
- If the error budget is fully consumed, feature releases are frozen until the next month (only reliability fixes ship)

## See Also

- [Alerting](alerting.md) for how SLA breaches trigger alerts
- [Disaster Recovery](disaster-recovery.md) for RTO/RPO targets that support SLA commitments
- [Postmortems](postmortems.md) for documenting SLA-impacting incidents

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: SLA terms are renegotiated or new plan tiers are introduced -->
