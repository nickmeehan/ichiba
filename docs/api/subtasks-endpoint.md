# Subtasks Endpoint

The Subtasks API manages hierarchical task relationships. Subtasks are full task objects nested under a parent task, supporting unlimited nesting depth with configurable limits.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/tasks/{task_id}/subtasks` | List subtasks of a task |
| POST | `/v1/tasks/{task_id}/subtasks` | Create a subtask |
| PATCH | `/v1/subtasks/{id}` | Update a subtask |
| DELETE | `/v1/subtasks/{id}` | Delete a subtask |
| POST | `/v1/subtasks/{id}/reorder` | Change subtask position |

## Creating Subtasks

```json
POST /v1/tasks/task_42/subtasks
{
  "name": "Write unit tests for auth module",
  "assignee_id": "user_08",
  "priority": 2
}
```

Subtasks inherit the parent task's project and can optionally inherit the parent's labels and milestone.

## Parent-Child Relationships

Each subtask has a `parent_id` referencing its parent task. The parent task exposes a `subtask_count` and `completed_subtask_count` in its response:

```json
{
  "data": {
    "id": "task_42",
    "name": "Implement authentication",
    "subtask_count": 5,
    "completed_subtask_count": 3,
    "subtask_completion_percentage": 60
  }
}
```

## Nesting Depth

Subtasks can be nested up to 5 levels deep by default. This limit is configurable per workspace (max 10 levels). Attempting to exceed the limit returns a `SUBTASK_DEPTH_EXCEEDED` error.

```
task_42
  └─ subtask_a (level 1)
       └─ subtask_b (level 2)
            └─ subtask_c (level 3)
```

## Status Rollup

Parent tasks can optionally auto-update their status based on subtask completion:

- When all subtasks are `done`, the parent transitions to `done`
- When any subtask moves to `in_progress`, the parent transitions to `in_progress`
- Manual override is always available

This behavior is controlled by the project setting `subtask_status_rollup: true`.

## Reordering

Subtasks have a `position` field that controls display order. Reorder with:

```json
POST /v1/subtasks/subtask_b/reorder
{
  "position": 0,
  "parent_id": "task_42"
}
```

Set `parent_id` to move a subtask to a different parent in the same operation.

## Converting Tasks to Subtasks

An existing top-level task can be converted to a subtask:

```json
PATCH /v1/tasks/task_99
{
  "parent_id": "task_42"
}
```

Similarly, a subtask can be promoted to a top-level task by setting `parent_id` to `null`.

## See Also

- [Tasks Endpoint](tasks-endpoint.md) — parent task management
- [Projects Endpoint](projects-endpoint.md) — project-level settings for subtasks
- [Boards Endpoint](boards-endpoint.md) — subtask display on boards
- [Automations Endpoint](automations-endpoint.md) — automating subtask creation

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: nesting depth limits, status rollup behavior, or reorder mechanics change -->
