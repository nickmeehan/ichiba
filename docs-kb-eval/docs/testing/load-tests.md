# Load Testing

Load tests verify that Nimbus performs acceptably under expected and peak traffic. We use k6 for scripting and executing load tests.

## k6 Scripts

Load test scripts are in `tests/load/`:

```
tests/load/
├── api-tasks.js          # Task CRUD operations
├── api-projects.js       # Project listing and search
├── api-auth.js           # Login and token refresh
├── dashboard-flow.js     # Full dashboard user journey
└── baselines.json        # Performance baselines
```

Example k6 script:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Ramp up
    { duration: '5m', target: 50 },   // Steady state
    { duration: '2m', target: 200 },  // Peak load
    { duration: '5m', target: 200 },  // Sustained peak
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};
```

## Traffic Patterns

Load tests simulate realistic traffic patterns based on production analytics:

| Endpoint | % of traffic | Avg requests/sec (normal) | Avg requests/sec (peak) |
|----------|-------------|--------------------------|------------------------|
| GET /tasks | 35% | 175 | 700 |
| GET /projects | 20% | 100 | 400 |
| POST /tasks | 15% | 75 | 300 |
| GET /dashboard | 10% | 50 | 200 |
| Other | 20% | 100 | 400 |

Peak traffic is 4x normal and typically occurs Monday mornings 9-10 AM ET.

## Performance Baselines

Baselines are recorded in `tests/load/baselines.json` and updated quarterly:

```json
{
  "GET /api/v1/tasks": { "p50": 45, "p95": 120, "p99": 250 },
  "POST /api/v1/tasks": { "p50": 65, "p95": 180, "p99": 350 },
  "GET /api/v1/projects": { "p50": 35, "p95": 100, "p99": 200 }
}
```

A load test fails if any endpoint exceeds its p95 baseline by more than 20%.

## Load Test Environments

| Environment | When to use | URL |
|------------|-------------|-----|
| Local | During development | `http://localhost:4000` |
| Staging | Pre-release validation | `https://staging-api.nimbus.io` |
| Load-test | Dedicated load testing | `https://loadtest-api.nimbus.io` |

Never run load tests against production. The dedicated load-test environment mirrors production infrastructure but uses isolated data.

## Result Analysis

After a load test run, k6 outputs a summary. For detailed analysis:

```bash
# Run with JSON output for Grafana import
k6 run --out json=results.json tests/load/api-tasks.js

# Or stream to Datadog
K6_DATADOG_AGENT_ADDR=localhost:8125 k6 run tests/load/api-tasks.js
```

Key metrics to review:
- **http_req_duration**: p50, p95, p99 latency.
- **http_req_failed**: Error rate (should be < 1%).
- **vus**: Concurrent virtual users (verify ramp-up worked).
- **iterations**: Total completed requests.

## See Also

- [Performance Profiling](../guides/performance-profiling.md) — diagnosing bottlenecks found in load tests
- [CI Test Config](ci-test-config.md) — running load tests in CI
- [Production Deployment](../guides/deployment/production.md) — load testing before major releases

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: k6 version, performance baselines, or load test infrastructure changes -->
