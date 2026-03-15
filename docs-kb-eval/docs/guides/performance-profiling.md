# Performance Profiling

This guide covers techniques for identifying and resolving performance bottlenecks across the Nimbus stack, including Node.js, React, and PostgreSQL.

## Node.js Profiling

### CPU Profiling

Use the built-in Node.js inspector for CPU profiling:

```bash
# Start the API server with inspector
node --inspect apps/api/dist/server.js

# Or in development
NODE_OPTIONS='--inspect' pnpm dev:api
```

Open `chrome://inspect` in Chrome, connect to the process, and use the Performance tab to record a CPU profile. Look for hot functions spending disproportionate time.

### Flame Graphs

For production profiling, use Datadog Continuous Profiler (already enabled). Navigate to APM > Profiles and filter by `service:nimbus-api`. Flame graphs reveal which functions consume the most wall-clock time.

## React Profiling

Use React DevTools Profiler to identify rendering bottlenecks:

1. Open React DevTools and switch to the **Profiler** tab.
2. Click Record, interact with the slow UI, and stop recording.
3. Look for components with high render counts or long render times.

Common fixes:
- Wrap expensive computations in `useMemo`.
- Use `React.memo` for components receiving stable props.
- Move data fetching to React Query with appropriate `staleTime` to avoid redundant requests.
- Check that list items have stable `key` props (not array indices).

## Database Query Analysis

### Slow Query Log

Enable the slow query log in development:

```sql
ALTER SYSTEM SET log_min_duration_statement = 100; -- Log queries > 100ms
SELECT pg_reload_conf();
```

### EXPLAIN ANALYZE

For specific queries, use `EXPLAIN ANALYZE` to understand the query plan:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT t.*, p.name AS project_name
FROM tasks t
JOIN projects p ON p.id = t.project_id
WHERE t.tenant_id = 'tenant-123'
  AND t.status = 'active'
ORDER BY t.created_at DESC
LIMIT 50;
```

Look for sequential scans on large tables, missing indexes, and high buffer reads.

## Memory Leak Detection

Symptoms of a memory leak: RSS grows steadily over hours, eventually triggering OOM kills.

```bash
# Generate a heap snapshot
kill -USR2 <pid>  # If using heapdump module

# Or via inspector
node --inspect apps/api/dist/server.js
# Connect via chrome://inspect > Memory > Take heap snapshot
```

Compare two snapshots taken 10 minutes apart. Sort by "Allocated Size" delta to find growing objects. Common culprits: event listener leaks, unclosed streams, and growing caches without eviction.

## Load Testing

Nimbus uses [k6](https://k6.io/) for load testing. Scripts are in `tests/load/`:

```bash
# Run a load test against local
k6 run tests/load/api-tasks.js --env BASE_URL=http://localhost:4000

# Run against staging
k6 run tests/load/api-tasks.js --env BASE_URL=https://staging-api.nimbus.io
```

Performance baselines are documented in `tests/load/baselines.json`. A test fails if p95 latency exceeds the baseline by more than 20%.

## See Also

- [Load Tests](../testing/load-tests.md) — k6 test scripts and configuration
- [Debugging](debugging.md) — general debugging techniques
- [Database Conventions](../conventions/database-conventions.md) — indexing guidelines

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: profiling tools, Datadog configuration, or performance baselines change -->
