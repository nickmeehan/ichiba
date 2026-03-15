# Incident Response

This guide defines how Nimbus engineers respond to production incidents, from initial detection through resolution and post-incident review.

## Severity Levels

| Level | Definition | Examples | Response time |
|-------|-----------|----------|---------------|
| **P0** | Service is down or data is at risk | Full outage, data corruption, security breach | Immediate (< 15 min) |
| **P1** | Major feature is broken for all tenants | Login broken, task creation failing, billing errors | < 30 min |
| **P2** | Feature degraded or broken for some tenants | Slow page loads, intermittent errors, single tenant issue | < 2 hours |
| **P3** | Minor issue with workaround available | UI glitch, non-critical background job failures | Next business day |

## Escalation Paths

### P0/P1 Escalation

1. The on-call engineer is paged via PagerDuty (rotation schedule in PagerDuty).
2. On-call engineer acknowledges and creates an incident channel: `#inc-YYYY-MM-DD-short-name`.
3. If not resolved within 30 minutes, escalate to the engineering manager.
4. If not resolved within 1 hour, escalate to the VP of Engineering.
5. For security incidents, immediately involve the security lead regardless of progress.

### P2/P3 Escalation

1. File a bug ticket in Linear with severity label.
2. Notify `#nimbus-incidents` in Slack.
3. Assign to the relevant team based on the affected area.

## Communication Templates

### Internal (Slack `#nimbus-incidents`)

```
:rotating_light: **P[0-3] Incident**: [Brief description]
**Impact**: [Who is affected and how]
**Status**: Investigating / Identified / Mitigating / Resolved
**Incident Lead**: @[name]
**Channel**: #inc-YYYY-MM-DD-[name]
```

### External (Status Page)

```
Title: [Feature] is experiencing [degraded performance / an outage]
Body: We are aware of an issue affecting [description]. Our team is
actively investigating. We will provide updates every 30 minutes.
```

Update the status page at [status.nimbus.io](https://status.nimbus.io) via the Statuspage dashboard.

## Post-Incident Review

Every P0 and P1 incident requires a post-incident review (PIR) within 5 business days:

1. **Timeline**: Minute-by-minute reconstruction of events.
2. **Root cause**: Technical root cause using the "5 Whys" technique.
3. **Impact**: Number of affected tenants, duration, and financial impact.
4. **Action items**: Concrete follow-up tickets to prevent recurrence.

PIR documents are stored in `docs/incidents/` and reviewed in the weekly architecture meeting. The goal is learning, not blame.

## Status Page Updates

- **P0**: Update every 15 minutes until resolved.
- **P1**: Update every 30 minutes until resolved.
- **P2/P3**: Update at start and resolution.

After resolution, post a final update summarizing the incident and linking to the PIR.

## See Also

- [Rollback Procedures](deployment/rollback.md) — rolling back a bad deploy
- [Debugging](debugging.md) — tracing issues in production
- [Logging Conventions](../conventions/logging.md) — finding relevant logs during incidents

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: on-call rotation, escalation policy, or status page tooling changes -->
