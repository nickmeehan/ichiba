# Ops Documentation

Nimbus runs on AWS across two regions (us-east-1 and eu-west-1) with Kubernetes orchestration. The ops team manages alerting, incident response, capacity planning, and disaster recovery for a platform serving hundreds of tenants with a 99.9% uptime SLA.

## Guides

- **[Alerting](alerting.md)**
  Use when configuring new alerts, adjusting severity levels, or investigating alert fatigue. Covers PagerDuty integration, routing rules, and escalation chains.

- **[Runbooks](runbooks.md)**
  Use when responding to an operational incident or automating remediation for common failure modes. Covers runbook format, common scenarios, and automated remediation scripts.

- **[SLAs](sla.md)**
  Use when reviewing uptime commitments, defining error budgets, or preparing SLA reports for customers. Covers uptime targets, response time thresholds, and credit policy.

- **[Capacity Planning](capacity-planning.md)**
  Use when forecasting infrastructure needs, setting scaling thresholds, or planning load tests. Covers growth projections, resource scaling triggers, and budget planning.

- **[Cost Optimization](cost-optimization.md)**
  Use when reviewing infrastructure spend, rightsizing instances, or implementing savings strategies. Covers reserved instances, spot usage, storage tiering, and CDN costs.

- **[Disaster Recovery](disaster-recovery.md)**
  Use when reviewing DR readiness, running failover drills, or updating the cross-region setup. Covers RTO/RPO targets, failover procedures, and communication plans.

- **[On-Call](on-call.md)**
  Use when joining the on-call rotation, handing off to the next engineer, or reviewing on-call policies. Covers rotation schedule, responsibilities, and tooling setup.

- **[Postmortems](postmortems.md)**
  Use when writing or reviewing an incident postmortem. Covers the blameless template, timeline format, root cause analysis, and action item tracking.

## See Also

- [Frontend Documentation](../frontend/_index.md)
- [Data Documentation](../data/_index.md)

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: new ops guide is added or infrastructure architecture changes -->
