# Columns Endpoint

The Columns API manages individual board columns including ordering, status mapping, and automation rules. Columns are the building blocks of board layouts.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/boards/{board_id}/columns` | List columns in a board |
| POST | `/v1/boards/{board_id}/columns` | Add a column to a board |
| GET | `/v1/columns/{id}` | Get column details |
| PATCH | `/v1/columns/{id}` | Update a column |
| DELETE | `/v1/columns/{id}` | Remove a column from a board |
| POST | `/v1/columns/{id}/reorder` | Change column position |

## Creating a Column

```json
POST /v1/boards/board_01/columns
{
  "name": "QA Testing",
  "status_mapping": "in_review",
  "wip_limit": 4,
  "position": 2,
  "color": "#9b59b6"
}
```

The `position` field determines where the column appears (0-indexed from left).

## Column Ordering

Reorder columns by setting a new position:

```json
POST /v1/columns/col_qa/reorder
{
  "position": 3
}
```

Other columns shift automatically to accommodate the move.

## Status Mapping

Each column maps to a task status. When a task is moved into a column, its status transitions to the mapped status. Multiple columns can map to the same status for sub-workflow visualization:

```
Backlog (open) -> Design (in_progress) -> Development (in_progress) -> Review (in_review) -> Done (done)
```

## Column Automation Rules

Columns can trigger automations when cards enter or leave:

```json
PATCH /v1/columns/col_review
{
  "automations": {
    "on_enter": [
      { "action": "assign", "user_id": "user_qa_lead" },
      { "action": "add_label", "label_id": "label_needs_review" }
    ],
    "on_exit": [
      { "action": "remove_label", "label_id": "label_needs_review" }
    ]
  }
}
```

Available automation actions: `assign`, `unassign`, `add_label`, `remove_label`, `set_field`, `notify`, `create_subtask`.

## Deleting a Column

Deleting a column requires specifying where to move existing cards:

```json
DELETE /v1/columns/col_old
{
  "move_cards_to": "col_backlog"
}
```

If `move_cards_to` is not specified and the column contains cards, the request returns a `COLUMN_NOT_EMPTY` error.

## Column Statistics

Get card counts and flow metrics for a column:

```
GET /v1/columns/col_review/stats
```

Returns `card_count`, `average_time_in_column`, `throughput_per_day`, and `wip_utilization`.

## See Also

- [Boards Endpoint](boards-endpoint.md) — parent board management
- [Tasks Endpoint](tasks-endpoint.md) — task status transitions
- [Automations Endpoint](automations-endpoint.md) — advanced automation rules
- [Labels Endpoint](labels-endpoint.md) — labels used in column automations

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: column automation actions, stats fields, or status mapping behavior changes -->
