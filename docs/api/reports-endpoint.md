# Reports Endpoint

The Reports API generates project analytics, team performance metrics, and custom reports. Reports can be generated on-demand or scheduled for recurring delivery.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/reports` | List saved reports |
| POST | `/v1/reports/generate` | Generate a report |
| GET | `/v1/reports/{id}` | Get report details and results |
| DELETE | `/v1/reports/{id}` | Delete a saved report |
| POST | `/v1/reports/{id}/schedule` | Schedule recurring generation |
| GET | `/v1/reports/templates` | List report templates |

## Generating a Report

```json
POST /v1/reports/generate
{
  "template": "project_summary",
  "parameters": {
    "project_id": "proj_01",
    "date_range": { "from": "2026-01-01", "to": "2026-03-31" },
    "group_by": "month"
  },
  "format": "json"
}
```

Report generation is asynchronous. The response includes a report ID and status:

```json
{
  "data": {
    "id": "report_001",
    "status": "generating",
    "estimated_completion": "2026-03-15T10:31:00Z"
  }
}
```

Poll the report endpoint or use a WebSocket subscription for completion notification.

## Report Templates

Built-in templates include:

| Template | Description |
|----------|-------------|
| `project_summary` | Task counts, completion rate, velocity |
| `team_workload` | Tasks per team member, hours logged |
| `sprint_retrospective` | Sprint goals vs actuals, carried-over items |
| `time_breakdown` | Time entries by project, user, or label |
| `burndown` | Burndown chart data for a sprint or milestone |
| `cycle_time` | Average time from creation to completion |
| `label_distribution` | Task counts per label or label group |

## Custom Reports

Build custom reports with data aggregation:

```json
POST /v1/reports/generate
{
  "custom": true,
  "data_source": "tasks",
  "filters": { "project_id": "proj_01", "status.neq": "archived" },
  "metrics": ["count", "avg_cycle_time", "sum_effort_points"],
  "dimensions": ["assignee", "label"],
  "format": "csv"
}
```

## Scheduled Reports

Schedule reports for recurring generation and email delivery:

```json
POST /v1/reports/report_001/schedule
{
  "frequency": "weekly",
  "day": "monday",
  "time": "09:00",
  "timezone": "America/New_York",
  "recipients": ["user_05", "user_12"]
}
```

## Data Aggregation

Reports support these aggregation functions: `count`, `sum`, `avg`, `min`, `max`, `median`, `percentile_90`.

Dimensions for grouping: `assignee`, `project`, `label`, `status`, `priority`, `sprint`, `date`, `week`, `month`.

## See Also

- [Dashboards Endpoint](dashboards-endpoint.md) — visual report displays
- [Sprints Endpoint](sprints-endpoint.md) — sprint data for reports
- [Time Tracking Endpoint](time-tracking-endpoint.md) — time data source
- [Exports Endpoint](exports-endpoint.md) — exporting report data
- [Content Negotiation](content-negotiation.md) — report output formats

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: report templates, aggregation functions, or scheduling options change -->
