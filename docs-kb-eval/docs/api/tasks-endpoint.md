# Tasks Endpoint

The Tasks API is the core of Nimbus, managing task creation, status transitions, assignments, and custom fields. Tasks belong to projects and can have subtasks, comments, attachments, and labels.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/tasks` | List tasks (filterable by project, status, assignee) |
| POST | `/v1/tasks` | Create a new task |
| GET | `/v1/tasks/{id}` | Get task details |
| PATCH | `/v1/tasks/{id}` | Update a task |
| DELETE | `/v1/tasks/{id}` | Delete a task |
| POST | `/v1/tasks/{id}/transitions` | Transition task status |

## Creating a Task

```json
POST /v1/tasks
{
  "name": "Design new landing page",
  "project_id": "proj_01",
  "assignee_id": "user_05",
  "priority": 3,
  "due_date": "2026-04-01",
  "label_ids": ["label_urgent", "label_design"],
  "custom_fields": {
    "cf_department": "marketing",
    "cf_effort_points": 5
  }
}
```

## Status Transitions

Tasks follow a configurable workflow. The default statuses are: `open`, `in_progress`, `in_review`, `done`, `archived`. Transitions are validated against the workflow rules:

```json
POST /v1/tasks/task_42/transitions
{
  "to_status": "in_review",
  "comment": "Ready for design review"
}
```

Invalid transitions return a `TASK_STATUS_INVALID_TRANSITION` error. To see allowed transitions:

```
GET /v1/tasks/task_42/transitions/available
```

## Assignee Management

Tasks support a single primary assignee and multiple watchers:

```json
PATCH /v1/tasks/task_42
{
  "assignee_id": "user_08",
  "watcher_ids": ["user_03", "user_12"]
}
```

Changing the assignee triggers a notification to both the old and new assignee.

## Due Dates and Priority

Priority is an integer from 1 (lowest) to 5 (highest). Due dates are ISO 8601 date strings. Tasks past their due date are flagged as overdue in list and board views.

## Custom Fields

Tasks support workspace-defined custom fields. Custom field values are passed in the `custom_fields` object using the field key:

```json
PATCH /v1/tasks/task_42
{
  "custom_fields": {
    "cf_story_points": 8,
    "cf_component": "backend"
  }
}
```

Custom field values are validated against the field definition (type, required, allowed values).

## Task Relationships

Tasks can be linked to other tasks with relationship types:

```json
POST /v1/tasks/task_42/relationships
{
  "related_task_id": "task_55",
  "type": "blocks"
}
```

Relationship types: `blocks`, `blocked_by`, `relates_to`, `duplicates`.

## See Also

- [Subtasks Endpoint](subtasks-endpoint.md) — nested subtasks
- [Comments Endpoint](comments-endpoint.md) — task comments
- [Labels Endpoint](labels-endpoint.md) — task labeling
- [Custom Fields Endpoint](custom-fields-endpoint.md) — field definitions
- [Time Tracking Endpoint](time-tracking-endpoint.md) — logging time on tasks

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: task CRUD, status workflow, custom field handling, or relationship types change -->
