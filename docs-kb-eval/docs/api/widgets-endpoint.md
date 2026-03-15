# Widgets Endpoint

The Widgets API manages individual dashboard widgets including their type, data configuration, and display settings. Widgets are the visual building blocks of dashboards.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/dashboards/{dashboard_id}/widgets` | List widgets on a dashboard |
| POST | `/v1/dashboards/{dashboard_id}/widgets` | Add a widget |
| GET | `/v1/widgets/{id}` | Get widget details |
| PATCH | `/v1/widgets/{id}` | Update a widget |
| DELETE | `/v1/widgets/{id}` | Remove a widget |
| GET | `/v1/widgets/{id}/data` | Fetch widget data |

## Widget Types

| Type | Description |
|------|-------------|
| `metric` | Single number with optional trend indicator |
| `chart_bar` | Bar chart with grouping and stacking |
| `chart_line` | Line chart with multi-series support |
| `chart_pie` | Pie/donut chart for distributions |
| `task_list` | Filtered list of tasks |
| `burndown` | Sprint/milestone burndown chart |
| `velocity` | Velocity chart across sprints |
| `activity_feed` | Recent activity stream |
| `markdown` | Static markdown content block |
| `table` | Tabular data display |

## Creating a Widget

```json
POST /v1/dashboards/dash_01/widgets
{
  "type": "chart_bar",
  "title": "Tasks by Status",
  "config": {
    "data_source": "tasks",
    "filter": { "project_id": "proj_01" },
    "dimension": "status",
    "metric": "count",
    "colors": { "open": "#3498db", "done": "#2ecc71" }
  },
  "position": { "x": 0, "y": 0, "width": 6, "height": 4 }
}
```

## Widget Configuration

Each widget type has specific configuration options:

### Metric Widget
```json
{
  "type": "metric",
  "config": {
    "data_source": "tasks",
    "filter": { "status": "done", "project_id": "proj_01" },
    "metric": "count",
    "comparison_period": "previous_week",
    "format": "number"
  }
}
```

### Task List Widget
```json
{
  "type": "task_list",
  "config": {
    "filter": { "assignee_id": "user_05", "status.neq": "done" },
    "sort": "-priority",
    "max_items": 10,
    "show_fields": ["name", "priority", "due_date", "status"]
  }
}
```

## Data Binding

Widgets fetch data from the configured source at the specified refresh interval. The `/data` endpoint returns the rendered data for a widget:

```
GET /v1/widgets/wgt_01/data
```

## Refresh Intervals

| Interval | Description |
|----------|-------------|
| `30s` | High-frequency for active monitoring |
| `5m` | Standard dashboard refresh (default) |
| `15m` | Low-frequency for overview dashboards |
| `manual` | Only refresh on user action |

## See Also

- [Dashboards Endpoint](dashboards-endpoint.md) — dashboard layout
- [Reports Endpoint](reports-endpoint.md) — report-based data sources
- [Sprints Endpoint](sprints-endpoint.md) — burndown/velocity data
- [Tasks Endpoint](tasks-endpoint.md) — task list widget data

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: widget types, configuration schema, or refresh behavior changes -->
