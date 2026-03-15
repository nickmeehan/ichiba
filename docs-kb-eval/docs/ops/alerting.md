# Alerting

Nimbus uses Prometheus for metrics collection, Grafana for dashboarding, and PagerDuty for alert routing and escalation. Alerts are designed to be actionable: every alert must have a corresponding runbook, and the system is regularly tuned to prevent alert fatigue.

## PagerDuty Integration

All production alerts route through PagerDuty. The integration is configured in `infrastructure/terraform/pagerduty.tf`:

- **Service**: `nimbus-production` -- the primary PagerDuty service for all production alerts
- **Integration key**: Stored in AWS Secrets Manager, referenced by Grafana alert rules
- **Webhook**: PagerDuty sends incident updates to the #ops-incidents Slack channel via webhook

Alerts from staging and development environments go to Slack only (never PagerDuty).

## Alert Severity Levels

| Severity | Response Time | PagerDuty Behavior | Examples |
|----------|-------------|-------------------|----------|
| **P1 - Critical** | 15 minutes | Pages on-call immediately, escalates after 15 min | Service down, data loss risk, security breach |
| **P2 - High** | 30 minutes | Pages on-call, escalates after 30 min | Degraded performance (>2x latency), error rate >5% |
| **P3 - Medium** | 4 hours | Slack notification, no page | Elevated error rate (1-5%), disk usage >80% |
| **P4 - Low** | Next business day | Slack notification only | Certificate expiring in 30 days, non-critical job failure |

## Alert Routing Rules

Alerts are routed based on labels applied in Prometheus alert rules:

```yaml
# Example Prometheus alert rule
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
  for: 5m
  labels:
    severity: p2
    team: backend
  annotations:
    summary: "Error rate above 5% for {{ $labels.service }}"
    runbook: "https://runbooks.nimbus.internal/high-error-rate"
```

Routing by team:
- **backend**: API errors, database issues, queue backlogs
- **frontend**: CDN errors, client-side error spikes, Core Web Vital regressions
- **data**: ETL failures, ClickHouse issues, replication lag
- **security**: Authentication anomalies, rate limit breaches, WAF blocks

## Alert Fatigue Prevention

To keep alerts meaningful:

1. **Minimum `for` duration**: All alerts require at least a 2-minute `for` clause to avoid firing on transient spikes.
2. **Grouping**: Prometheus groups related alerts by `alertname` and `service` to avoid a flood of individual alerts.
3. **Inhibition**: If a P1 "service down" alert fires, lower-severity alerts for the same service are suppressed.
4. **Weekly review**: The on-call engineer reviews all alerts from the past week. Alerts that fired but required no action are candidates for tuning or removal.
5. **Alert budget**: Each team is limited to 10 alerts per service. Adding a new alert requires justification and a runbook.

## Escalation Chains

| Stage | Delay | Action |
|-------|-------|--------|
| 1 | 0 min | Page primary on-call engineer |
| 2 | 15 min (P1) / 30 min (P2) | Page secondary on-call engineer |
| 3 | 30 min (P1) / 1 hour (P2) | Page engineering manager |
| 4 | 1 hour (P1) | Page VP of Engineering |

P3 and P4 alerts do not escalate; they are handled during business hours.

## Key Alerts

| Alert | Condition | Severity | Runbook |
|-------|-----------|----------|---------|
| `ServiceDown` | Health check fails for 2 min | P1 | [service-down](runbooks.md) |
| `HighErrorRate` | 5xx rate > 5% for 5 min | P2 | [high-error-rate](runbooks.md) |
| `HighLatency` | p99 latency > 2s for 10 min | P2 | [high-latency](runbooks.md) |
| `DiskSpaceHigh` | Disk usage > 85% | P3 | [disk-full](runbooks.md) |
| `ConnectionPoolExhausted` | Available connections < 5 | P2 | [connection-pool](runbooks.md) |
| `CertificateExpiring` | SSL cert expires in < 14 days | P4 | [cert-renewal](runbooks.md) |

## See Also

- [Runbooks](runbooks.md) for alert response procedures
- [On-Call](on-call.md) for who receives alerts and when
- [SLAs](sla.md) for how alert response ties to uptime commitments

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: PagerDuty configuration changes or new alert categories are added -->
