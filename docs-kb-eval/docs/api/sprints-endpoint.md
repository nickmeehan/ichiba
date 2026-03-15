# Sprints Endpoint

The Sprints API manages sprint lifecycle including planning, execution, and retrospective data. Sprints are time-boxed iterations within a project.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/projects/{project_id}/sprints` | List sprints |
| POST | `/v1/projects/{project_id}/sprints` | Create a sprint |
| GET | `/v1/sprints/{id}` | Get sprint details |
| PATCH | `/v1/sprints/{id}` | Update a sprint |
| POST | `/v1/sprints/{id}/start` | Start a sprint |
| POST | `/v1/sprints/{id}/complete` | Complete a sprint |
| GET | `/v1/sprints/{id}/tasks` | List tasks in the sprint |
| POST | `/v1/sprints/{id}/tasks` | Add tasks to the sprint |

## Creating a Sprint

```json
POST /v1/projects/proj_01/sprints
{
  "name": "Sprint 14",
  "goal": "Complete user authentication flow",
  "start_date": "2026-03-16",
  "end_date": "2026-03-30",
  "capacity_points": 40
}
```

## Sprint Lifecycle

Sprints progress through: `planning` -> `active` -> `completed`.

Only one sprint per project can be `active` at a time. Starting a new sprint when one is already active returns `SPRINT_ALREADY_ACTIVE`.

## Starting a Sprint

```json
POST /v1/sprints/sprint_14/start
{
  "move_incomplete_from": "sprint_13"
}
```

The `move_incomplete_from` parameter automatically moves unfinished tasks from the previous sprint.

## Completing a Sprint

```json
POST /v1/sprints/sprint_14/complete
{
  "incomplete_action": "move_to_backlog"
}
```

Options for `incomplete_action`: `move_to_backlog`, `move_to_next_sprint`, `keep_in_sprint`.

## Capacity Planning

Sprint capacity is measured in story points or hours. The API tracks committed vs completed capacity:

```json
{
  "data": {
    "id": "sprint_14",
    "capacity_points": 40,
    "committed_points": 38,
    "completed_points": 25,
    "remaining_points": 13
  }
}
```

## Velocity

Retrieve velocity data across past sprints:

```
GET /v1/projects/proj_01/sprints/velocity?last=6
```

Returns completed points per sprint for the last N sprints.

## Burndown Data

```
GET /v1/sprints/sprint_14/burndown
```

Returns daily data points with `remaining_points`, `ideal_remaining`, and `completed_today` for burndown chart rendering.

## See Also

- [Tasks Endpoint](tasks-endpoint.md) — tasks within sprints
- [Boards Endpoint](boards-endpoint.md) — sprint board views
- [Teams Endpoint](teams-endpoint.md) — team sprint participation
- [Reports Endpoint](reports-endpoint.md) — sprint reports
- [Milestones Endpoint](milestones-endpoint.md) — milestone vs sprint planning

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: sprint lifecycle, velocity calculation, or capacity tracking changes -->
