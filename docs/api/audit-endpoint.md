# Audit Endpoint

The Audit API provides access to the workspace audit log, recording all significant actions performed by users and system processes. Audit logs are immutable and retained according to the workspace plan.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/audit/events` | List audit events |
| GET | `/v1/audit/events/{id}` | Get event details |
| POST | `/v1/audit/export` | Export audit log data |
| GET | `/v1/audit/retention` | Get retention policy |

## Querying Events

```
GET /v1/audit/events?filter[actor_id]=user_05&filter[action]=task.deleted&filter[timestamp.gte]=2026-03-01
```

Response:

```json
{
  "data": [
    {
      "id": "evt_001",
      "action": "task.deleted",
      "actor": { "id": "user_05", "type": "user", "display_name": "Jane Chen" },
      "resource": { "type": "task", "id": "task_42", "name": "Old task" },
      "timestamp": "2026-03-15T10:30:00Z",
      "ip_address": "203.0.113.42",
      "metadata": { "reason": "duplicate" }
    }
  ]
}
```

## Event Filtering

Filter events by:

| Filter | Description |
|--------|-------------|
| `actor_id` | User who performed the action |
| `actor_type` | `user`, `api_key`, `system`, `automation` |
| `action` | Specific action (e.g., `task.created`, `project.archived`) |
| `resource_type` | Type of resource affected |
| `resource_id` | Specific resource |
| `timestamp` | Date range with `gte`/`lte` operators |
| `ip_address` | IP address of the request |

## Tracked Actions

All CRUD operations on all resources are logged, plus:

- Authentication events (login, logout, token refresh)
- Permission changes (role assignment, grant/revoke)
- Admin actions (workspace settings, user deactivation)
- Billing events (plan change, payment method update)
- Export and import operations
- Automation rule executions

## Export

Export audit logs for compliance or analysis:

```json
POST /v1/audit/export
{
  "date_range": { "from": "2026-01-01", "to": "2026-03-31" },
  "format": "csv",
  "filters": { "action.starts_with": "task." }
}
```

Export is asynchronous. A download link is sent to the requesting user's email.

## Retention Policy

| Plan | Retention |
|------|-----------|
| Free | 30 days |
| Pro | 1 year |
| Enterprise | 7 years (configurable) |

Events beyond the retention window are permanently deleted.

## Immutability

Audit log entries cannot be modified or deleted by any user, including workspace owners. This ensures audit trail integrity for compliance requirements.

## See Also

- [Permissions Endpoint](permissions-endpoint.md) — permission change events
- [Admin Endpoint](admin-endpoint.md) — admin action logging
- [Authentication](authentication.md) — auth event logging
- [Exports Endpoint](exports-endpoint.md) — audit data export

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: tracked actions, retention periods, or export format changes -->
