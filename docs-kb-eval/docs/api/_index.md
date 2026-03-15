# Nimbus API Documentation

Nimbus is a multi-tenant project management platform. This index covers all API documentation — conventions, infrastructure, and resource endpoints.

## How to Use This Index

Each entry includes a situation-based description. Read the description to decide which doc is relevant to your current task.

---

## API Conventions & Infrastructure

- `rest-overview.md` — REST API design, conventions — read when understanding API structure or adding new endpoints
- `graphql.md` — GraphQL API layer — read when building or consuming GraphQL queries, mutations, or subscriptions
- `authentication.md` — API authentication and authorization — read when implementing login flows, API key usage, or debugging 401/403 errors
- `rate-limits.md` — Rate limiting and throttling — read when hitting 429 errors, planning high-volume integrations, or configuring tenant quotas
- `pagination.md` — Cursor-based pagination — read when listing resources, implementing infinite scroll, or dealing with large result sets
- `filtering.md` — Query filtering syntax — read when building search UIs, constructing filtered API calls, or adding new filterable fields
- `sorting.md` — Sort parameter conventions — read when implementing sortable tables, adding sort options, or understanding default ordering
- `versioning.md` — API version strategy — read when migrating between API versions, planning deprecations, or understanding sunset timelines
- `error-codes.md` — Error response format and catalog — read when handling API errors, adding new error types, or debugging unexpected responses
- `webhooks-inbound.md` — Inbound webhook processing — read when receiving events from external systems, validating webhook payloads, or setting up integrations
- `batch-operations.md` — Bulk create/update/delete — read when performing mass data changes, optimizing multiple API calls, or handling partial failures
- `file-uploads.md` — File upload mechanisms — read when implementing file pickers, handling large uploads, or generating presigned URLs
- `realtime-subscriptions.md` — WebSocket and realtime events — read when building live-updating UIs, subscribing to changes, or debugging connection drops
- `idempotency.md` — Idempotency key handling — read when implementing safe retries, preventing duplicate operations, or designing reliable integrations
- `cors.md` — Cross-origin resource sharing — read when debugging browser CORS errors, configuring allowed origins, or enabling cross-domain API access
- `content-negotiation.md` — Response format negotiation — read when requesting CSV/XML exports, setting Accept headers, or adding new response formats
- `deprecation-policy.md` — API deprecation and sunset process — read when planning breaking changes, responding to sunset headers, or migrating off deprecated endpoints
- `sdk-generation.md` — SDK and client library generation — read when generating typed clients, updating SDK versions, or adding a new language target
- `openapi-spec.md` — OpenAPI specification management — read when editing the API spec, generating docs, or validating schema changes

## Resource Endpoints

- `projects-endpoint.md` — Projects CRUD and settings — read when creating/managing projects, configuring project templates, or handling archive/restore
- `tasks-endpoint.md` — Tasks CRUD and workflow — read when creating/updating tasks, managing status transitions, or working with custom fields
- `subtasks-endpoint.md` — Subtask hierarchy — read when nesting tasks, managing parent-child relationships, or implementing status rollup
- `users-endpoint.md` — User profiles and membership — read when managing user accounts, uploading avatars, or querying workspace members
- `teams-endpoint.md` — Team management — read when creating teams, assigning members, or configuring team-level permissions
- `roles-endpoint.md` — Custom roles and permission sets — read when defining roles, assigning permissions, or understanding built-in role defaults
- `permissions-endpoint.md` — Permission checks and inheritance — read when verifying access rights, updating resource-level permissions, or debugging authorization
- `comments-endpoint.md` — Threaded comments — read when adding comments to tasks, implementing @mentions, or building comment UIs
- `reactions-endpoint.md` — Emoji reactions — read when adding reaction support, querying reaction counts, or toggling user reactions
- `attachments-endpoint.md` — File attachments — read when associating files with tasks/comments, generating download links, or managing metadata
- `labels-endpoint.md` — Labels and tagging — read when creating labels, assigning labels to resources, or managing label groups
- `milestones-endpoint.md` — Milestone tracking — read when planning releases, tracking milestone progress, or linking tasks to milestones
- `sprints-endpoint.md` — Sprint management — read when running sprint planning, viewing velocity/burndown, or completing sprints
- `boards-endpoint.md` — Kanban boards — read when creating boards, configuring columns, or setting WIP limits
- `columns-endpoint.md` — Board columns — read when managing column order, mapping statuses, or configuring column automation
- `time-tracking-endpoint.md` — Time entries and timers — read when logging hours, starting/stopping timers, or generating time reports
- `reports-endpoint.md` — Report generation — read when creating reports, scheduling recurring reports, or aggregating project data
- `dashboards-endpoint.md` — Dashboard management — read when building dashboards, configuring widget layouts, or sharing views
- `widgets-endpoint.md` — Dashboard widgets — read when adding widgets, binding data sources, or customizing widget display
- `search-endpoint.md` — Full-text and faceted search — read when implementing search bars, building filter UIs, or saving search queries
- `audit-endpoint.md` — Audit log access — read when reviewing change history, exporting audit data, or setting up compliance monitoring
- `billing-endpoint.md` — Billing and subscription management — read when changing plans, viewing usage data, or updating payment methods
- `invoices-endpoint.md` — Invoice management — read when listing invoices, generating PDF receipts, or processing refunds
- `subscriptions-endpoint.md` — Subscription plan details — read when upgrading/downgrading plans, managing trials, or checking feature flags
- `notifications-endpoint.md` — Notification delivery — read when listing notifications, configuring preferences, or registering push devices
- `preferences-endpoint.md` — User and workspace preferences — read when saving UI settings, configuring notification channels, or managing defaults
- `templates-endpoint.md` — Project and task templates — read when creating reusable templates, applying templates, or browsing the template marketplace
- `custom-fields-endpoint.md` — Custom field definitions — read when adding custom metadata to tasks, defining field types, or configuring validation rules
- `automations-endpoint.md` — Workflow automations — read when creating automation rules, defining triggers/actions, or reviewing execution logs
- `imports-endpoint.md` — Data import pipelines — read when importing from CSV/JSON, mapping fields, or monitoring import progress
- `exports-endpoint.md` — Data export — read when exporting project data, scheduling recurring exports, or downloading large datasets
- `admin-endpoint.md` — Workspace administration — read when managing workspace settings, administering users, or toggling feature flags

---

*This index covers 51 documentation files for the Nimbus API. Each file is self-contained but includes See Also links for cross-referencing.*

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: a new API endpoint or convention doc is added -->
