# Analytics Service

The analytics service provides workspace-level insights, project metrics, and custom reporting for Nimbus. It uses ClickHouse as the analytics data store, optimized for fast aggregation queries over large time-series datasets.

## Data Pipeline

Analytics events flow from the application into ClickHouse through a lightweight pipeline:

1. Domain events (e.g., `task.completed`, `sprint.started`) are captured by the analytics event handler.
2. The handler extracts metric-relevant fields and writes them to a BullMQ queue.
3. A worker batches events and inserts them into ClickHouse in bulk every 10 seconds.

This batching approach reduces write overhead on ClickHouse while keeping data latency under 30 seconds for most metrics.

## Core Metrics

### Burndown Charts
Tracks remaining work (story points or task count) over the course of a sprint. The ideal burndown line is calculated from the sprint's start date, end date, and total committed points.

### Velocity Tracking
Records the number of story points completed per sprint. Displays a rolling average over the last 6 sprints to help teams estimate future capacity.

### Cycle Time
Measures the elapsed time from when a task enters "In Progress" to when it reaches "Done." Displayed as a histogram with median, P75, and P95 breakdowns.

### Throughput
Counts the number of tasks completed per day, week, or month. Filterable by project, assignee, and task type.

## Workspace Dashboards

Each workspace has a default analytics dashboard with pre-built widgets. Workspace admins can customize the dashboard by adding, removing, or rearranging widgets. Available widget types:

- Sprint burndown chart
- Velocity trend line
- Cycle time distribution
- Task completion by assignee
- Status distribution pie chart
- Overdue tasks count

## Custom Report Builder

Pro and Enterprise users can build custom reports using a drag-and-drop interface. Reports support:

- **Dimensions**: project, sprint, assignee, status, priority, custom fields
- **Measures**: count, sum of story points, average cycle time, min/max dates
- **Filters**: date range, project, assignee, labels
- **Visualizations**: bar chart, line chart, table, pie chart

Custom reports can be saved, shared with workspace members, and scheduled for email delivery.

## Data Export

Analytics data can be exported in CSV or JSON format. Exports are generated as background jobs and delivered via a download link sent to the requesting user's email. Export scope is always limited to the current workspace.

## See Also

- [Event-Driven Architecture](../event-driven.md) - Analytics event capture
- [ClickHouse / Database](../database/_index.md) - ClickHouse is separate from the primary PostgreSQL database
- [Billing](./billing.md) - Feature gating for custom reports

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New metric types are added or the ClickHouse schema changes -->
