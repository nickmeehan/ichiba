# Postmortems

Nimbus conducts blameless postmortems for all P1 incidents and any P2 incident lasting longer than 30 minutes. Postmortems focus on understanding what happened, why it happened, and how to prevent it from happening again. They are never about assigning blame to individuals.

## Blameless Postmortem Template

All postmortems are written in the `postmortems/` directory following this template:

```markdown
# Incident: [Short descriptive title]
**Date**: YYYY-MM-DD
**Duration**: X hours Y minutes
**Severity**: P1/P2
**Author**: [Name of postmortem author]
**Participants**: [Names of people involved in response and review]

## Summary
[2-3 sentence description of what happened and the impact]

## Impact
- **Users affected**: [number or percentage]
- **Tenants affected**: [list or count]
- **Data loss**: [yes/no, details if yes]
- **SLA impact**: [minutes of downtime counted against SLA]
- **Revenue impact**: [estimated, if applicable]

## Timeline
[Detailed timeline -- see format below]

## Root Cause
[Technical explanation of the underlying cause]

## Contributing Factors
[Other factors that allowed the root cause to become an incident]

## What Went Well
[Things that worked during incident response]

## What Could Be Improved
[Areas where response or prevention could be better]

## Action Items
[Table of follow-up tasks -- see format below]

## Lessons Learned
[Key takeaways for the team]
```

## Timeline Format

Timelines use UTC timestamps and include detection, response, and resolution events:

```
14:23 UTC - Monitoring detects error rate spike (5xx > 5%) on API pods
14:25 UTC - PagerDuty pages primary on-call (Alice)
14:27 UTC - Alice acknowledges, begins investigation
14:30 UTC - Alice identifies database connection pool exhaustion via Grafana
14:32 UTC - Alice posts initial update to #ops-incidents
14:35 UTC - Alice restarts PgBouncer, connections recover
14:38 UTC - Error rate returns to baseline
14:40 UTC - Alice monitors for 10 minutes, confirms stability
14:50 UTC - Incident resolved, PagerDuty incident closed
```

Include what information was available at each decision point. Avoid hindsight bias -- document what the responder knew at the time, not what we know now.

## Root Cause Analysis

Use the "Five Whys" technique to dig past symptoms to the underlying cause:

1. **Why** did the API return 500 errors? -- Database connections were exhausted.
2. **Why** were connections exhausted? -- A new query was holding connections open for 30+ seconds.
3. **Why** was the query so slow? -- It was scanning a table with 2M rows without an index.
4. **Why** was there no index? -- The migration that added the query did not include an index.
5. **Why** was the missing index not caught? -- The CI pipeline does not run query performance tests against production-sized data.

The root cause in this example is: "No query performance testing in CI for production-scale data."

## Action Items Tracking

Every postmortem produces action items tracked in Linear:

| Action Item | Owner | Priority | Due Date | Status |
|-------------|-------|----------|----------|--------|
| Add index to `tasks` table for `tenant_id, status` | Bob | P1 | 2026-03-18 | Done |
| Add query performance tests to CI | Carol | P2 | 2026-03-31 | In Progress |
| Set connection timeout to 10s in PgBouncer | Alice | P1 | 2026-03-16 | Done |
| Document connection pool sizing in runbook | Dave | P3 | 2026-04-05 | Open |

Action items are reviewed in the weekly engineering meeting until all items are closed. Items older than 30 days without progress are escalated to the engineering manager.

## Sharing

Postmortems are shared with the entire engineering team:

1. **Postmortem review meeting**: Held within 48 hours of incident resolution. All engineers are invited (attendance optional but encouraged). The author walks through the timeline and root cause.
2. **Written document**: Published to the `postmortems/` directory and announced in #engineering Slack channel.
3. **Monthly digest**: A summary of all incidents and their action items is included in the monthly engineering newsletter.
4. **External communication**: For customer-impacting P1 incidents, Customer Success drafts a customer-facing summary (reviewed by the postmortem author) and sends it to affected tenants.

## Postmortem Culture

- **No blame**: Focus on systems and processes, not individuals. Use phrases like "the deployment process allowed..." not "Alice forgot to..."
- **Psychological safety**: Anyone can call out issues without fear of retribution
- **Celebrate good catches**: Acknowledge when monitoring, testing, or quick response prevented a worse outcome
- **Follow through**: Action items are not suggestions; they are commitments with owners and deadlines

## See Also

- [Alerting](alerting.md) for how incidents are detected and routed
- [Runbooks](runbooks.md) for incident response procedures
- [On-Call](on-call.md) for who responds to incidents
- [SLAs](sla.md) for measuring incident impact against uptime commitments

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: postmortem process changes or template is updated -->
