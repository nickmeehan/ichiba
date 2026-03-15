# Labels Endpoint

The Labels API manages labels for categorizing tasks and other resources. Labels support custom colors, grouping, and bulk assignment.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/labels` | List labels in the workspace |
| POST | `/v1/labels` | Create a label |
| GET | `/v1/labels/{id}` | Get label details |
| PATCH | `/v1/labels/{id}` | Update a label |
| DELETE | `/v1/labels/{id}` | Delete a label |
| POST | `/v1/tasks/{task_id}/labels` | Apply a label to a task |
| DELETE | `/v1/tasks/{task_id}/labels/{label_id}` | Remove a label from a task |
| POST | `/v1/labels/bulk-assign` | Bulk assign labels to tasks |

## Creating a Label

```json
POST /v1/labels
{
  "name": "Bug",
  "color": "#e74c3c",
  "group": "Type",
  "description": "Something that is not working correctly"
}
```

## Color Management

Labels require a hex color code. Nimbus provides a default palette, but any valid hex color is accepted. Colors must meet WCAG AA contrast requirements against white backgrounds. Labels with insufficient contrast receive a warning in the response.

Default palette colors: `#e74c3c` (red), `#3498db` (blue), `#2ecc71` (green), `#f39c12` (orange), `#9b59b6` (purple), `#1abc9c` (teal), `#e67e22` (dark orange), `#95a5a6` (gray).

## Label Groups

Labels can be organized into groups for structured categorization:

| Group | Labels |
|-------|--------|
| Type | Bug, Feature, Enhancement, Chore |
| Priority | Critical, High, Medium, Low |
| Status | Blocked, Needs Review, Ready |

Groups are created implicitly by setting the `group` field. List labels filtered by group:

```
GET /v1/labels?filter[group]=Type
```

## Bulk Labeling

Apply or remove labels across multiple tasks:

```json
POST /v1/labels/bulk-assign
{
  "label_id": "label_bug",
  "task_ids": ["task_01", "task_02", "task_03"],
  "action": "add"
}
```

Actions: `add` or `remove`. Maximum 100 tasks per bulk operation.

## Label Constraints

Some projects enforce label constraints (e.g., exactly one label from the "Priority" group). These constraints are configured in project settings and validated on task creation/update.

## Filtering by Labels

Tasks can be filtered by label:

```
GET /v1/tasks?filter[label_ids.in]=label_bug,label_critical
```

## See Also

- [Tasks Endpoint](tasks-endpoint.md) — applying labels to tasks
- [Projects Endpoint](projects-endpoint.md) — project-level label constraints
- [Filtering](filtering.md) — filtering tasks by labels
- [Boards Endpoint](boards-endpoint.md) — label-based board views

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: color validation rules, group behavior, or bulk labeling limits change -->
