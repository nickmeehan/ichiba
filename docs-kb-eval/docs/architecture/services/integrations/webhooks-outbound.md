# Outbound Webhooks

Outbound webhooks allow external systems to receive real-time notifications when events occur in a Nimbus workspace. Workspace admins can register webhook URLs and subscribe them to specific event types.

## Event Subscriptions

Each webhook registration includes:
- **URL**: The HTTPS endpoint that receives the payload.
- **Events**: A list of subscribed event types (e.g., `task.created`, `task.completed`).
- **Secret**: A shared secret used for payload signing.
- **Active**: A toggle to temporarily disable delivery without deleting the registration.

Available event types mirror the domain events documented in the event-driven architecture section. Common subscriptions include:

| Event Type          | Description                              |
|--------------------|------------------------------------------|
| `task.created`     | A new task was created                   |
| `task.updated`     | A task's fields were modified            |
| `task.completed`   | A task was moved to Done                 |
| `task.deleted`     | A task was deleted                       |
| `comment.added`    | A comment was added to a task            |
| `sprint.started`   | A sprint was activated                   |
| `sprint.completed` | A sprint was closed                      |
| `member.added`     | A user was added to the workspace        |

## Payload Format

Webhook payloads are JSON with a consistent envelope:

```json
{
  "event": "task.created",
  "timestamp": "2026-03-15T14:30:00Z",
  "workspace_id": "ws_def456",
  "data": {
    "task": {
      "id": "tsk_ghi789",
      "title": "Implement webhook retry logic",
      "status": "open",
      "assignee": "usr_abc123"
    }
  }
}
```

## Webhook Signing

Every webhook delivery includes an `X-Nimbus-Signature` header containing an HMAC-SHA256 signature computed over the raw request body using the webhook's shared secret:

```
X-Nimbus-Signature: sha256=a1b2c3d4e5f6...
```

Receivers should verify this signature before processing the payload to ensure authenticity. Sample verification code is provided in the Nimbus API documentation.

## Retry Strategy

Failed deliveries (non-2xx responses or network errors) are retried with exponential backoff:

| Attempt | Delay        |
|---------|-------------|
| 1       | Immediate   |
| 2       | 1 minute    |
| 3       | 5 minutes   |
| 4       | 30 minutes  |
| 5       | 2 hours     |

After 5 failed attempts, the delivery is marked as failed and no further retries are attempted for that event. If a webhook endpoint fails consistently (10 consecutive failures), the webhook is automatically disabled and the workspace admin is notified.

## Delivery Logs

Each webhook registration has a delivery log showing the last 100 delivery attempts. Each log entry includes the event type, HTTP status code, response time, and whether the delivery succeeded. Admins can use this to debug connectivity issues.

## See Also

- [Event-Driven Architecture](../../event-driven.md) - Source events for webhook delivery
- [Slack Integration](./slack.md) - Pre-built integration alternative
- [Rate Limiting](../rate-limiting.md) - Webhook endpoint rate limits

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New event types are added or the retry policy changes -->
