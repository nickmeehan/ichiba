# Notification Service

The notification service delivers messages to users across multiple channels: in-app notifications, email, and push notifications. It reacts to domain events and respects per-user delivery preferences.

## Channels

| Channel  | Provider   | Use Case                                      |
|----------|-----------|------------------------------------------------|
| In-App   | WebSocket  | Real-time banner and notification center       |
| Email    | SendGrid   | Task assignments, mentions, digest summaries   |
| Push     | FCM        | Mobile alerts for high-priority notifications  |

## Event-Driven Delivery

Notifications are triggered by domain events. The notification handler maps each event type to a notification template and determines the recipients:

| Event             | Recipients              | Channels          |
|-------------------|------------------------|--------------------|
| `task.assigned`   | Assignee               | In-app, email, push|
| `comment.added`   | Task watchers          | In-app, email      |
| `member.invited`  | Invited user           | Email              |
| `sprint.started`  | Project members        | In-app             |
| `task.due_soon`   | Assignee               | In-app, email, push|

## User Preferences

Each user can configure notification preferences at the workspace level:

- **Per event type**: Enable or disable notifications for specific events.
- **Per channel**: Choose which channels receive each notification type.
- **Quiet hours**: Suppress push and email during specified hours (in-app still delivered).
- **Frequency**: Immediate delivery or batched digest.

Preferences are stored in the `notification_preferences` table and cached in Redis for fast lookup during event processing.

## Batching and Digest

To avoid notification fatigue, the service supports batching. When a user has digest mode enabled, notifications are queued and aggregated into a single email sent at a configured interval (hourly or daily). The digest groups notifications by project and summarizes counts:

> **Nimbus Daily Digest - Acme Workspace**
> - Project Alpha: 3 new comments, 2 tasks assigned to you
> - Project Beta: 1 sprint completed, 5 tasks moved to Done

## Templates

Email and push notification content is rendered from Handlebars templates stored in `packages/backend/templates/notifications/`. Each template has a subject line, plain text body, and HTML body. Template variables are populated from the event payload.

## Delivery Tracking

Every notification delivery attempt is recorded with a status (delivered, bounced, failed). Bounce handling for email uses SendGrid's event webhooks to mark invalid addresses and prevent future delivery attempts to them.

## See Also

- [Event-Driven Architecture](../event-driven.md) - How domain events trigger notifications
- [Scheduler](./scheduler.md) - Digest email scheduling
- [Email Integration](./integrations/email.md) - Inbound email processing

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New notification event types are added or delivery channels change -->
