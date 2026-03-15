# Monitoring

Nimbus uses Prometheus for metrics collection, Grafana for visualization, and PagerDuty for alert routing. This document covers the metrics taxonomy, dashboard organization, and alerting rules.

## Metrics Collection

Application metrics are exposed via a `/metrics` endpoint on each pod using the `prom-client` library. Prometheus scrapes these endpoints every 15 seconds. Infrastructure metrics (node CPU, memory, disk) are collected by the Prometheus Node Exporter.

## Custom Application Metrics

### Request Metrics

| Metric                               | Type      | Labels                          |
|-------------------------------------|-----------|----------------------------------|
| `http_request_duration_seconds`     | Histogram | method, route, status_code       |
| `http_requests_total`               | Counter   | method, route, status_code       |
| `http_request_size_bytes`           | Histogram | method, route                    |

### Business Metrics

| Metric                               | Type      | Labels                          |
|-------------------------------------|-----------|----------------------------------|
| `tasks_created_total`               | Counter   | tenant_id                        |
| `tasks_completed_total`             | Counter   | tenant_id                        |
| `active_websocket_connections`      | Gauge     | -                                |
| `active_workspaces`                 | Gauge     | plan                             |

### Queue Metrics

| Metric                               | Type      | Labels                          |
|-------------------------------------|-----------|----------------------------------|
| `bullmq_queue_depth`               | Gauge     | queue_name                       |
| `bullmq_job_duration_seconds`       | Histogram | queue_name, job_name             |
| `bullmq_failed_jobs_total`         | Counter   | queue_name, job_name             |

### Cache Metrics

| Metric                               | Type      | Labels                          |
|-------------------------------------|-----------|----------------------------------|
| `cache_hit_total`                   | Counter   | entity_type                      |
| `cache_miss_total`                  | Counter   | entity_type                      |

## Grafana Dashboards

Dashboards are organized by concern:

| Dashboard              | Key Panels                                          |
|-----------------------|------------------------------------------------------|
| API Overview          | Request rate, error rate, p50/p95/p99 latency        |
| Database              | Query latency, connection pool usage, replication lag |
| Redis                 | Memory usage, hit rate, connected clients            |
| Queue Health          | Queue depth, processing rate, failed jobs            |
| WebSocket             | Active connections, message throughput                |
| Tenant Activity       | Active workspaces, request distribution by tenant    |
| Infrastructure        | Node CPU, memory, disk, pod restarts                 |

Dashboards are version-controlled as JSON in the `infrastructure/grafana/` directory and deployed via Grafana provisioning.

## Alerting Rules

Alerts are defined as Prometheus alerting rules and routed through Alertmanager to PagerDuty or Slack:

| Alert                           | Condition                                | Severity | Channel     |
|--------------------------------|------------------------------------------|----------|-------------|
| High Error Rate                | 5xx rate > 5% for 5 minutes             | Critical | PagerDuty   |
| High Latency                  | p99 latency > 2s for 5 minutes           | Warning  | Slack       |
| Database Connection Exhaustion | Pool usage > 90% for 5 minutes           | Critical | PagerDuty   |
| Replication Lag                | Lag > 5 seconds for 5 minutes            | Warning  | Slack       |
| Queue Backlog                  | Queue depth > 1000 for 10 minutes        | Warning  | Slack       |
| Pod Crash Loop                 | Pod restarted > 3 times in 15 minutes    | Critical | PagerDuty   |
| Disk Usage                    | Node disk usage > 85%                     | Warning  | Slack       |
| Certificate Expiry            | TLS cert expires in < 14 days            | Warning  | Slack       |

## Alert Routing

- **Critical**: Paged to on-call engineer via PagerDuty. Requires acknowledgment within 15 minutes.
- **Warning**: Posted to `#eng-alerts` Slack channel. Reviewed during business hours.
- **Info**: Logged but not actively alerted. Visible on dashboards.

## See Also

- [Kubernetes](./kubernetes.md) - Pod metrics and health checks
- [Error Handling](../error-handling.md) - Error rate metric sources
- [Caching](../caching.md) - Cache hit rate monitoring

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New metrics are added or alerting thresholds are adjusted -->
