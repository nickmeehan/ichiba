# Milestones Endpoint

The Milestones API manages milestone definitions, progress tracking, and task linkage. Milestones represent key dates or deliverables within a project.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/projects/{project_id}/milestones` | List milestones |
| POST | `/v1/projects/{project_id}/milestones` | Create a milestone |
| GET | `/v1/milestones/{id}` | Get milestone details |
| PATCH | `/v1/milestones/{id}` | Update a milestone |
| DELETE | `/v1/milestones/{id}` | Delete a milestone |
| GET | `/v1/milestones/{id}/tasks` | List tasks linked to the milestone |

## Creating a Milestone

```json
POST /v1/projects/proj_01/milestones
{
  "name": "Beta Release",
  "description": "Feature-complete beta available to testers",
  "due_date": "2026-06-01",
  "status": "open"
}
```

Milestone statuses: `open`, `in_progress`, `completed`, `overdue`.

## Progress Tracking

Milestone progress is computed from linked tasks:

```json
{
  "data": {
    "id": "ms_01",
    "name": "Beta Release",
    "total_tasks": 24,
    "completed_tasks": 18,
    "progress_percentage": 75,
    "open_blockers": 1,
    "estimated_completion": "2026-05-28"
  }
}
```

The `estimated_completion` is calculated from the average task completion velocity.

## Due Dates

Milestones with due dates trigger notifications at configurable intervals (7 days, 3 days, 1 day before due). Overdue milestones are flagged automatically and their status transitions to `overdue`.

## Linking Tasks

Link existing tasks to a milestone:

```json
PATCH /v1/tasks/task_42
{
  "milestone_id": "ms_01"
}
```

Tasks can belong to one milestone at a time. Changing a task's milestone removes it from the previous one.

## Milestone Burndown

Get burndown data for a milestone:

```
GET /v1/milestones/ms_01/burndown
```

Returns daily data points showing remaining tasks over time, ideal for chart rendering.

## Milestone Comparison

Compare progress across milestones in a project:

```
GET /v1/projects/proj_01/milestones?include=progress&sort=-progress_percentage
```

## See Also

- [Tasks Endpoint](tasks-endpoint.md) — linking tasks to milestones
- [Sprints Endpoint](sprints-endpoint.md) — sprint vs milestone planning
- [Projects Endpoint](projects-endpoint.md) — project-level milestones
- [Reports Endpoint](reports-endpoint.md) — milestone progress reports
- [Notifications Endpoint](notifications-endpoint.md) — milestone due date alerts

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: progress calculation, burndown data format, or due date notification behavior changes -->
