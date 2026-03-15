# ETL Pipelines

Nimbus runs ETL (Extract, Transform, Load) pipelines to synchronize operational data from PostgreSQL into ClickHouse for analytics, generate periodic reports, and feed machine learning models. Pipelines are orchestrated by Temporal workflows and monitored via Grafana dashboards.

## Architecture

```
PostgreSQL (source) --> Temporal Worker (transform) --> ClickHouse (destination)
                                                    --> S3 (archival)
```

Pipelines run as Temporal workflows, which provide durable execution, automatic retries, and visibility into pipeline state. Each pipeline is defined as a workflow with multiple activity functions for extraction, transformation, and loading.

## Data Warehouse Sync

The primary pipeline syncs operational data to ClickHouse for reporting:

| Source Table | Target Table | Sync Frequency | Method |
|-------------|-------------|----------------|--------|
| `tasks` | `analytics.tasks` | Every 5 minutes | CDC (Change Data Capture) |
| `projects` | `analytics.projects` | Every 15 minutes | CDC |
| `events` | `analytics.events` | Every 1 minute | Append-only tail |
| `users` | `analytics.users` | Every 1 hour | Full snapshot |
| `time_entries` | `analytics.time_entries` | Every 5 minutes | CDC |

CDC is implemented using PostgreSQL logical replication slots. The pipeline reads from the replication slot, transforms rows to match the ClickHouse schema, and inserts in batches of 10,000 rows.

## Transformation Jobs

Common transformations applied during ETL:

- **Tenant enrichment**: Joins tenant metadata (plan tier, industry, region) onto operational data for segmented analytics.
- **Time bucketing**: Pre-aggregates event counts into hourly and daily buckets for dashboard queries.
- **PII masking**: Strips or hashes personal data before loading into the analytics warehouse (email addresses are hashed, names are removed).
- **Currency normalization**: Converts billing amounts to USD using daily exchange rates for cross-tenant revenue reporting.

Transformations are implemented as pure functions in `packages/etl/src/transforms/` and are unit-tested with fixture data.

## Scheduling

| Pipeline | Schedule | Timeout | Retry Policy |
|----------|----------|---------|-------------|
| Task sync | Every 5 minutes | 10 minutes | 3 retries, exponential backoff |
| Event sync | Every 1 minute | 5 minutes | 5 retries, exponential backoff |
| Daily aggregation | 02:00 UTC daily | 2 hours | 2 retries |
| Monthly report | 1st of month, 04:00 UTC | 4 hours | 2 retries |
| User sync | Every 1 hour | 30 minutes | 3 retries |

Schedules are defined in Temporal and can be paused or adjusted without code changes via the Temporal UI.

## Error Handling

Pipeline failures are handled at multiple levels:

1. **Row-level**: Malformed rows are written to a dead-letter table (`etl_dead_letters`) with the error message. The pipeline continues processing remaining rows.
2. **Batch-level**: If a batch insert fails, the entire batch is retried up to 3 times before being written to dead letters.
3. **Pipeline-level**: If the pipeline fails entirely (e.g., database connection lost), Temporal retries the workflow according to the retry policy.
4. **Alerting**: Failed pipelines trigger a PagerDuty alert if not resolved within 15 minutes. See [Alerting](../ops/alerting.md).

## Data Quality Checks

After each pipeline run, quality checks validate:

- Row counts match between source and destination (within 1% tolerance)
- No null values in required columns
- Referential integrity between fact and dimension tables
- Timestamp monotonicity (no events with timestamps before the last processed event)

Quality check failures log warnings and trigger a Slack notification to the #data-engineering channel.

## See Also

- [Reporting](reporting.md) for ClickHouse query patterns that consume ETL output
- [Event Sourcing](event-sourcing.md) for the event stream that feeds analytics pipelines
- [GDPR](gdpr.md) for PII handling requirements in ETL pipelines

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: new data sources are added to ETL or pipeline orchestration changes -->
