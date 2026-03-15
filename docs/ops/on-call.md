# On-Call

Nimbus runs a 24/7 on-call rotation staffed by backend and infrastructure engineers. The on-call engineer is the first responder for production alerts and is responsible for triage, mitigation, and escalation during their shift.

## Rotation Schedule

The on-call rotation operates on a weekly cycle, starting Monday at 09:00 UTC and ending the following Monday at 09:00 UTC:

- **Primary on-call**: Responds to all P1 and P2 alerts within the SLA response time
- **Secondary on-call**: Backup if the primary is unreachable after the escalation timeout
- **On-call manager**: Engineering manager on rotation for escalation and decision-making on P1 incidents

The rotation is managed in PagerDuty. Engineers are added to the rotation after completing the on-call onboarding checklist (see below). Each engineer is on-call approximately once every 6 weeks.

**Scheduling rules**:
- No one is on-call during their PTO (PagerDuty syncs with the team calendar)
- Engineers can swap shifts via PagerDuty with mutual agreement
- New engineers shadow for one full rotation before going on-call solo
- No one is on-call for more than 7 consecutive days

## On-Call Responsibilities

During your on-call shift:

1. **Acknowledge alerts** within 5 minutes (P1) or 15 minutes (P2)
2. **Triage**: Determine severity, impact, and affected tenants
3. **Mitigate**: Follow the relevant [runbook](runbooks.md) to restore service
4. **Communicate**: Post updates to #ops-incidents Slack channel every 15 minutes during P1/P2 incidents
5. **Document**: Create a brief incident ticket in Linear with timeline, actions taken, and follow-up items
6. **Escalate**: If you cannot resolve within the SLA or need domain expertise, escalate via PagerDuty

Outside of active incidents:
- Monitor the #ops-alerts Slack channel for P3/P4 alerts
- Review and address non-urgent alerts during business hours
- Keep your laptop and phone accessible with PagerDuty notifications enabled

## Handoff Procedure

At the start of each rotation (Monday 09:00 UTC):

1. **Outgoing engineer** posts a handoff summary in #ops-oncall:
   - Active incidents or ongoing issues
   - Recent changes (deploys, infrastructure updates) that may cause alerts
   - Any P3/P4 alerts that need follow-up
   - Known upcoming events (load tests, maintenance windows, large tenant onboarding)

2. **Incoming engineer** acknowledges the handoff and:
   - Verifies PagerDuty notifications are working (test page)
   - Reviews the past week's alert history in PagerDuty
   - Checks upcoming scheduled maintenance in the ops calendar

3. Both engineers confirm the handoff in the #ops-oncall channel

## Compensation

On-call compensation recognizes the burden of off-hours availability:

| Component | Amount |
|-----------|--------|
| Base on-call stipend | $500 per week |
| Incident response (off-hours) | $100 per incident responded to outside business hours |
| P1 extended incident (> 2 hours) | Additional $200 |
| Comp time | 1 day off for each week of on-call (flexible scheduling) |

Compensation is processed through payroll at the end of each month based on PagerDuty incident logs.

## Tooling Setup

Before your first on-call shift, complete this checklist:

- [ ] PagerDuty account configured with phone and push notifications
- [ ] PagerDuty mobile app installed and tested
- [ ] VPN access to production infrastructure verified
- [ ] `kubectl` configured for production clusters (us-east-1 and eu-west-1)
- [ ] AWS console access with read-only production role
- [ ] Grafana dashboards bookmarked (API health, database, Redis, queue depth)
- [ ] Runbook repository cloned locally
- [ ] #ops-incidents and #ops-alerts Slack channels joined with notifications on
- [ ] Test page sent and received successfully

## See Also

- [Alerting](alerting.md) for alert severity levels and escalation chains
- [Runbooks](runbooks.md) for incident response procedures
- [Postmortems](postmortems.md) for documenting incidents after resolution

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: on-call policy changes or compensation structure is updated -->
