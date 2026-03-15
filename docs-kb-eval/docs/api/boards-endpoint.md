# Boards Endpoint

The Boards API manages Kanban-style boards for visualizing task workflow. Each project can have multiple boards with configurable columns, WIP limits, and views.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/projects/{project_id}/boards` | List boards in a project |
| POST | `/v1/projects/{project_id}/boards` | Create a board |
| GET | `/v1/boards/{id}` | Get board details with columns and cards |
| PATCH | `/v1/boards/{id}` | Update board settings |
| DELETE | `/v1/boards/{id}` | Delete a board |
| POST | `/v1/boards/{id}/cards/move` | Move a card between columns |

## Creating a Board

```json
POST /v1/projects/proj_01/boards
{
  "name": "Development Board",
  "type": "kanban",
  "columns": [
    { "name": "Backlog", "status_mapping": "open" },
    { "name": "In Progress", "status_mapping": "in_progress", "wip_limit": 5 },
    { "name": "Review", "status_mapping": "in_review", "wip_limit": 3 },
    { "name": "Done", "status_mapping": "done" }
  ]
}
```

## Column Configuration

Each column maps to a task status and can have constraints:

```json
{
  "name": "In Progress",
  "status_mapping": "in_progress",
  "wip_limit": 5,
  "auto_assign": true,
  "color": "#3498db"
}
```

Moving a card into a column automatically transitions the task to the mapped status.

## WIP Limits

Work-in-progress limits restrict how many cards a column can hold. When a column is at capacity:

- Moving cards into the column is blocked (returns `WIP_LIMIT_REACHED`)
- Admins can override with the `force: true` parameter
- Dashboard and board views highlight over-limit columns

## Moving Cards

```json
POST /v1/boards/board_01/cards/move
{
  "task_id": "task_42",
  "to_column": "col_review",
  "position": 0
}
```

The `position` field determines ordering within the column (0 = top).

## Board Views

Boards support different view modes:

| View | Description |
|------|-------------|
| `kanban` | Standard column-based view |
| `swimlane` | Rows grouped by assignee, label, or priority |
| `timeline` | Gantt-style timeline based on due dates |

Switch views via:

```
GET /v1/boards/board_01?view=swimlane&swimlane_by=assignee
```

## Board Filters

Apply temporary filters to a board view:

```
GET /v1/boards/board_01?filter[assignee_id]=user_05&filter[label_ids.in]=label_bug
```

Filters do not modify the board configuration — they apply only to the current view.

## Default Board

Each project has a default board created automatically. The default board uses the project's status workflow for columns.

## See Also

- [Columns Endpoint](columns-endpoint.md) — detailed column management
- [Tasks Endpoint](tasks-endpoint.md) — task status transitions
- [Sprints Endpoint](sprints-endpoint.md) — sprint board views
- [Realtime Subscriptions](realtime-subscriptions.md) — live board updates
- [Filtering](filtering.md) — board filter syntax

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: board types, WIP limit behavior, or view modes change -->
