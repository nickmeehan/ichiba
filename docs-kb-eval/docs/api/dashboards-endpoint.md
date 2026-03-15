# Dashboards Endpoint

The Dashboards API manages customizable dashboards for visualizing project and workspace data. Dashboards contain configurable widgets arranged in a grid layout.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/dashboards` | List dashboards |
| POST | `/v1/dashboards` | Create a dashboard |
| GET | `/v1/dashboards/{id}` | Get dashboard with widget layout |
| PATCH | `/v1/dashboards/{id}` | Update dashboard settings |
| DELETE | `/v1/dashboards/{id}` | Delete a dashboard |
| POST | `/v1/dashboards/{id}/duplicate` | Duplicate a dashboard |
| POST | `/v1/dashboards/{id}/share` | Share a dashboard |

## Creating a Dashboard

```json
POST /v1/dashboards
{
  "name": "Q2 Overview",
  "description": "High-level metrics for Q2 projects",
  "visibility": "workspace",
  "layout": "grid"
}
```

## Widget Layout

Dashboards use a 12-column grid system. Widgets are positioned using `x`, `y`, `width`, and `height`:

```json
{
  "data": {
    "id": "dash_01",
    "name": "Q2 Overview",
    "widgets": [
      { "id": "wgt_01", "type": "metric", "x": 0, "y": 0, "width": 3, "height": 2 },
      { "id": "wgt_02", "type": "chart", "x": 3, "y": 0, "width": 6, "height": 4 },
      { "id": "wgt_03", "type": "task_list", "x": 9, "y": 0, "width": 3, "height": 4 }
    ]
  }
}
```

## Data Sources

Dashboard widgets pull data from various sources:

| Source | Description |
|--------|-------------|
| `project` | Single project metrics |
| `workspace` | Workspace-wide aggregates |
| `sprint` | Sprint-specific data |
| `team` | Team workload and performance |
| `custom_query` | Ad-hoc data query |

## Sharing

Dashboards can be shared with specific users, teams, or the entire workspace:

```json
POST /v1/dashboards/dash_01/share
{
  "share_with": [
    { "type": "user", "id": "user_12", "permission": "view" },
    { "type": "team", "id": "team_03", "permission": "edit" }
  ]
}
```

Permissions: `view` (read-only) or `edit` (can modify widgets and layout).

## Dashboard Templates

Pre-built dashboard templates are available:

- **Project Health**: burndown, velocity, blocker count, completion rate
- **Team Performance**: tasks completed per member, time logged, cycle time
- **Executive Summary**: cross-project status, milestone progress, budget utilization

Create from a template:

```json
POST /v1/dashboards
{
  "template": "project_health",
  "name": "Proj Alpha Health",
  "parameters": { "project_id": "proj_01" }
}
```

## Auto-Refresh

Dashboard data refreshes on a configurable interval (minimum 30 seconds). Real-time dashboards use WebSocket subscriptions for instant updates.

## See Also

- [Widgets Endpoint](widgets-endpoint.md) — widget configuration
- [Reports Endpoint](reports-endpoint.md) — data underlying widgets
- [Teams Endpoint](teams-endpoint.md) — team dashboard data
- [Realtime Subscriptions](realtime-subscriptions.md) — live dashboard updates

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: grid layout system, sharing model, or dashboard templates change -->
