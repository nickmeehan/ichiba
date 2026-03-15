# Scheduler Service

The scheduler service manages background jobs and recurring tasks using BullMQ, a Redis-backed job queue for Node.js. It handles both one-off deferred work and cron-scheduled recurring operations.

## Architecture

The scheduler runs as a dedicated worker process separate from the API server. It connects to the same Redis instance used for caching and events, but uses a dedicated key prefix (`bull:`) to isolate queue data.

Jobs are organized into named queues based on their purpose:

| Queue               | Purpose                                    | Concurrency |
|---------------------|--------------------------------------------|-------------|
| `notifications`     | Email, push, and in-app delivery           | 10          |
| `search-indexer`    | Elasticsearch document indexing            | 5           |
| `file-processing`   | Virus scan, thumbnail generation           | 3           |
| `analytics`         | ClickHouse event batching                  | 2           |
| `exports`           | CSV/PDF report generation                  | 2           |
| `cleanup`           | Soft-deleted file removal, expired tokens  | 1           |

## Recurring Jobs

Recurring jobs are registered at worker startup using BullMQ's repeatable job feature:

| Job                    | Schedule       | Description                                |
|------------------------|----------------|--------------------------------------------|
| `digest-emails`        | Every hour     | Send batched notification digests           |
| `overdue-task-check`   | Every 15 min   | Flag tasks past their due date             |
| `storage-usage-calc`   | Every 5 min    | Recalculate per-workspace storage usage    |
| `expired-token-cleanup`| Daily at 3 AM  | Remove expired refresh tokens from Redis   |
| `s3-archive`           | Daily at 2 AM  | Archive old audit logs to S3               |
| `analytics-rollup`     | Hourly         | Aggregate raw analytics into summary tables|

## Job Priorities

Jobs within a queue are processed by priority (lower number = higher priority):

| Priority | Use Case                                      |
|----------|------------------------------------------------|
| 1        | User-triggered actions (export, notification)  |
| 5        | System maintenance (cleanup, archival)         |
| 10       | Bulk operations (reindexing, migration)        |

## Retry Strategy

Failed jobs are retried with exponential backoff:

- **Attempt 1**: Immediate
- **Attempt 2**: After 30 seconds
- **Attempt 3**: After 2 minutes
- **Attempt 4**: After 10 minutes

After 4 failed attempts, the job is moved to the dead letter queue. An alert is sent to the `#eng-alerts` Slack channel with the job ID, error message, and stack trace.

## Dead Letter Handling

Dead letter jobs can be inspected and replayed through the BullMQ admin dashboard (Bull Board), which is accessible at `/admin/queues` in the staging and production environments behind admin authentication. Engineers can view the failure reason, edit the job payload, and re-enqueue it.

## See Also

- [Notifications](./notifications.md) - Notification delivery jobs
- [File Storage](./file-storage.md) - File processing workers
- [Analytics](./analytics.md) - Analytics batching jobs

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New job queues are added or retry policies are adjusted -->
