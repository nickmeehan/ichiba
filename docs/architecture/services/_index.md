# Services

This section documents the backend services that power the Nimbus platform. Each service encapsulates a distinct area of functionality and is implemented as a module within the monorepo backend package.

## Contents

### [Auth](./auth.md)
When you need to understand how users authenticate, how JWT tokens are issued and validated, or how RBAC permissions are checked.

### [Billing](./billing.md)
When you are working with subscription tiers, Stripe integration, usage-based pricing, or need to understand how payment webhooks are processed.

### [Notifications](./notifications.md)
When you need to send notifications to users, configure delivery channels, or understand how notification batching and digest emails work.

### [File Storage](./file-storage.md)
When you are implementing file uploads or downloads, need to understand presigned URLs, or are working with storage quotas and virus scanning.

### [Search](./search.md)
When you are adding a new searchable entity, troubleshooting search relevance, or need to understand the Elasticsearch indexing pipeline.

### [Analytics](./analytics.md)
When you are building dashboards, working with burndown charts, or need to understand how analytics data flows into ClickHouse.

### [Audit Log](./audit-log.md)
When you need to add audit trail entries for a new operation, query historical changes, or understand the retention and export policies.

### [Scheduler](./scheduler.md)
When you are creating background jobs, setting up recurring tasks, or debugging job failures and retry behavior.

### [Integrations](./integrations/_index.md)
When you need to work with third-party services like Slack, GitHub, Jira, or configure SSO providers and outbound webhooks.

### [Rate Limiting](./rate-limiting.md)
When you need to adjust rate limits for an endpoint, understand how per-tenant throttling works, or debug 429 responses.

## See Also

- [System Design](../system-design.md) - How services fit into the overall architecture
- [Event-Driven Architecture](../event-driven.md) - How services communicate via events
- [Data Flow](../data-flow.md) - Request path through service layers

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New services are added or existing services are significantly restructured -->
