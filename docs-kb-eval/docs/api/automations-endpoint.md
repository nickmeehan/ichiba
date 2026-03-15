# Automations Endpoint

The Automations API manages workflow automation rules that execute actions in response to triggers and conditions. Automations reduce manual work by automatically updating tasks, sending notifications, and performing routine operations.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/automations` | List automation rules |
| POST | `/v1/automations` | Create an automation rule |
| GET | `/v1/automations/{id}` | Get rule details |
| PATCH | `/v1/automations/{id}` | Update a rule |
| DELETE | `/v1/automations/{id}` | Delete a rule |
| POST | `/v1/automations/{id}/enable` | Enable a rule |
| POST | `/v1/automations/{id}/disable` | Disable a rule |
| GET | `/v1/automations/{id}/logs` | View execution logs |

## Creating a Rule

```json
POST /v1/automations
{
  "name": "Auto-assign bug reports to QA",
  "project_id": "proj_01",
  "trigger": {
    "event": "task.created",
    "conditions": [
      { "field": "label_ids", "operator": "contains", "value": "label_bug" }
    ]
  },
  "actions": [
    { "type": "assign", "user_id": "user_qa_lead" },
    { "type": "set_field", "field": "priority", "value": 4 },
    { "type": "add_label", "label_id": "label_needs_triage" }
  ]
}
```

## Triggers

| Trigger Event | Description |
|--------------|-------------|
| `task.created` | New task created |
| `task.updated` | Task field changed |
| `task.status_changed` | Task status transitioned |
| `task.assigned` | Task assignee changed |
| `task.due_date_approaching` | Due date within N days |
| `task.overdue` | Task past due date |
| `comment.created` | New comment on a task |
| `sprint.started` | Sprint activated |
| `sprint.completed` | Sprint finished |
| `webhook.received` | Inbound webhook event |
| `schedule` | Cron-based schedule |

## Conditions

Conditions filter when the trigger should fire:

```json
{
  "conditions": [
    { "field": "status", "operator": "eq", "value": "done" },
    { "field": "priority", "operator": "gte", "value": 3 },
    { "field": "assignee.team_id", "operator": "eq", "value": "team_frontend" }
  ],
  "condition_logic": "all"
}
```

`condition_logic`: `all` (AND) or `any` (OR).

## Actions

| Action Type | Description |
|-------------|-------------|
| `assign` | Assign task to a user |
| `set_field` | Set a field value |
| `add_label` | Add a label |
| `remove_label` | Remove a label |
| `transition` | Change task status |
| `create_subtask` | Create a subtask |
| `send_notification` | Send a custom notification |
| `move_to_column` | Move card on a board |
| `set_due_date` | Set or adjust due date |
| `webhook` | Call an external URL |

## Execution Logs

View the history of rule executions:

```
GET /v1/automations/auto_01/logs?filter[status]=failed
```

```json
{
  "data": [
    {
      "id": "exec_001",
      "automation_id": "auto_01",
      "trigger_event": "task.created",
      "trigger_resource": "task_55",
      "status": "failed",
      "error": "User user_qa_lead not found",
      "executed_at": "2026-03-15T10:30:00Z"
    }
  ]
}
```

## Plan Limits

| Plan | Max Rules | Executions/Month |
|------|-----------|-----------------|
| Free | 5 | 100 |
| Pro | 25 | 5,000 |
| Enterprise | Unlimited | Unlimited |

## See Also

- [Tasks Endpoint](tasks-endpoint.md) — task events that trigger automations
- [Columns Endpoint](columns-endpoint.md) — column-level automation
- [Webhooks Inbound](webhooks-inbound.md) — webhook-triggered automations
- [Notifications Endpoint](notifications-endpoint.md) — notification actions
- [Audit Endpoint](audit-endpoint.md) — automation actions in audit log

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: trigger events, action types, or plan limits change -->
