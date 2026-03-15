# Time Tracking Endpoint

The Time Tracking API manages time entries, timers, and time reports. Time can be logged against tasks for billing, reporting, and project estimation.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/tasks/{task_id}/time-entries` | List time entries for a task |
| POST | `/v1/tasks/{task_id}/time-entries` | Log a time entry |
| GET | `/v1/time-entries/{id}` | Get a time entry |
| PATCH | `/v1/time-entries/{id}` | Update a time entry |
| DELETE | `/v1/time-entries/{id}` | Delete a time entry |
| POST | `/v1/time-entries/timer/start` | Start a timer |
| POST | `/v1/time-entries/timer/stop` | Stop the running timer |
| GET | `/v1/time-entries/timer/current` | Get the currently running timer |

## Logging Time

```json
POST /v1/tasks/task_42/time-entries
{
  "duration_minutes": 90,
  "date": "2026-03-15",
  "description": "Implemented login form validation",
  "billable": true
}
```

## Timer Start/Stop

Start a live timer tied to a task:

```json
POST /v1/time-entries/timer/start
{
  "task_id": "task_42",
  "description": "Working on API integration"
}
```

Stop the timer and save the entry:

```json
POST /v1/time-entries/timer/stop
```

Only one timer can run at a time per user. Starting a new timer stops the current one.

## Time Reports

Generate time reports across projects and users:

```
GET /v1/time-entries?filter[date.gte]=2026-03-01&filter[date.lte]=2026-03-31&group_by=user
```

Group by options: `user`, `project`, `task`, `date`, `label`.

```json
{
  "data": {
    "groups": [
      { "user_id": "user_05", "display_name": "Jane Chen", "total_minutes": 2400, "billable_minutes": 1800 },
      { "user_id": "user_08", "display_name": "Tom Wu", "total_minutes": 1920, "billable_minutes": 1600 }
    ],
    "total_minutes": 4320,
    "total_billable_minutes": 3400
  }
}
```

## Billable Hours

Time entries can be marked as billable or non-billable. Billable hours are used in invoice generation and client billing reports. The default billable status is configurable per project.

## Rounding

Time entries can be configured to round to the nearest increment:

| Setting | Behavior |
|---------|----------|
| `none` | Exact minutes logged |
| `15min` | Rounds up to nearest 15 minutes |
| `30min` | Rounds up to nearest 30 minutes |
| `1hour` | Rounds up to nearest hour |

Rounding is configured per workspace in admin settings.

## Approval Workflow

Enterprise plans support time entry approval. Managers review and approve/reject entries before they appear in billing reports:

```
POST /v1/time-entries/time_001/approve
POST /v1/time-entries/time_001/reject
```

## See Also

- [Tasks Endpoint](tasks-endpoint.md) — tasks that time is logged against
- [Reports Endpoint](reports-endpoint.md) — time-based reports
- [Billing Endpoint](billing-endpoint.md) — billable hours in billing
- [Projects Endpoint](projects-endpoint.md) — project time tracking settings

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: timer behavior, rounding rules, or approval workflow changes -->
