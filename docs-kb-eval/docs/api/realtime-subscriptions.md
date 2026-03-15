# Realtime Subscriptions

Nimbus supports realtime event streaming via WebSocket connections. Clients can subscribe to changes on specific resources and receive push updates as they happen.

## WebSocket Endpoint

```
wss://api.nimbus.io/v1/ws
```

Authentication is performed during the WebSocket handshake via the `Authorization` query parameter or the `Sec-WebSocket-Protocol` header carrying the Bearer token.

## Connection Protocol

The WebSocket connection uses a JSON-based message protocol:

```json
// Client sends:
{ "type": "subscribe", "channel": "task.task_42", "id": "sub_001" }

// Server acknowledges:
{ "type": "subscribe_ack", "id": "sub_001", "channel": "task.task_42" }

// Server pushes events:
{ "type": "event", "channel": "task.task_42", "event": "task.updated", "data": { ... } }
```

## Subscription Management

Clients can manage subscriptions dynamically:

```json
// Subscribe to a channel
{ "type": "subscribe", "channel": "project.proj_01.tasks", "id": "sub_002" }

// Unsubscribe from a channel
{ "type": "unsubscribe", "id": "sub_002" }

// List active subscriptions
{ "type": "list_subscriptions" }
```

Maximum subscriptions per connection: 50. Exceeding this returns an error message on the WebSocket.

## Available Channels

| Channel Pattern | Events |
|----------------|--------|
| `task.{id}` | `task.updated`, `task.deleted`, `task.commented` |
| `project.{id}` | `project.updated`, `project.archived` |
| `project.{id}.tasks` | `task.created`, `task.updated`, `task.deleted` |
| `sprint.{id}` | `sprint.started`, `sprint.completed`, `sprint.updated` |
| `user.{id}.notifications` | `notification.created` |
| `board.{id}` | `board.card_moved`, `board.column_updated` |

## Event Streaming

Events are delivered in order per channel. Each event includes a sequence number for gap detection:

```json
{
  "type": "event",
  "channel": "task.task_42",
  "seq": 1547,
  "event": "task.updated",
  "data": { "status": "in_progress" },
  "timestamp": "2026-03-15T10:30:00Z"
}
```

## Reconnection Handling

If the connection drops, clients should reconnect with the last received `seq` number to receive missed events:

```json
{ "type": "subscribe", "channel": "task.task_42", "id": "sub_001", "since_seq": 1547 }
```

Missed events are available for up to 30 minutes after they occur. After that window, clients must do a full data refresh.

## Heartbeats

The server sends `ping` frames every 30 seconds. Clients must respond with `pong` within 10 seconds or the connection is terminated.

## See Also

- [GraphQL](graphql.md) — GraphQL subscriptions alternative
- [Notifications Endpoint](notifications-endpoint.md) — notification event details
- [Authentication](authentication.md) — WebSocket authentication
- [Boards Endpoint](boards-endpoint.md) — board event channels

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: WebSocket protocol, available channels, or reconnection behavior changes -->
