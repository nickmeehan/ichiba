# Logging Conventions

Nimbus uses structured logging with Pino across all services. This guide covers log levels, structured fields, PII handling, and retention policies.

## Structured Logging with Pino

All log statements produce JSON objects, not plain text strings:

```typescript
import { logger } from '@nimbus/shared/logger';

// Good: structured log with context
logger.info({ taskId: task.id, userId: user.id, action: 'task.created' }, 'Task created');

// Bad: unstructured string interpolation
logger.info(`Task ${task.id} created by user ${user.id}`);
```

The first argument to Pino is always the structured fields object. The second argument is the human-readable message.

## Log Levels

| Level | When to use | Examples |
|-------|------------|---------|
| `fatal` | Process is about to crash | Unhandled exception, OOM |
| `error` | Operation failed, requires attention | Database connection lost, external API 500 |
| `warn` | Unexpected but recoverable | Deprecated API called, retry succeeded after failure |
| `info` | Normal significant events | Request completed, job processed, user logged in |
| `debug` | Development-time detail | Query parameters, cache hit/miss, intermediate state |
| `trace` | Extremely verbose | Function entry/exit, loop iterations |

Production log level is `info`. Staging is `debug`. Local development is `debug` (configurable via `LOG_LEVEL` env var).

## Correlation IDs

Every log entry must include a `correlationId` for request tracing. This is set automatically by the request context middleware:

```typescript
// Middleware sets correlationId on the logger
app.use((req, res, next) => {
  req.log = logger.child({
    correlationId: req.headers['x-correlation-id'] || generateId(),
    tenantId: req.tenantId,
  });
  next();
});

// In route handlers, use req.log
router.post('/tasks', (req, res) => {
  req.log.info({ taskId: newTask.id }, 'Task created');
});
```

Background jobs should include the `jobId` and `correlationId` from the job metadata.

## PII Redaction

Personally identifiable information must be redacted from logs. Pino's `redact` option handles this:

```typescript
const logger = pino({
  redact: {
    paths: [
      'email',
      'password',
      'req.headers.authorization',
      'req.headers.cookie',
      'user.name',
      'user.email',
      'body.creditCard',
    ],
    censor: '[REDACTED]',
  },
});
```

If you add a new field that contains PII, add it to the redaction paths in `packages/shared/src/logger.ts`.

## Log Retention

| Environment | Retention | Storage |
|------------|-----------|---------|
| Production | 90 days (hot), 1 year (cold) | Datadog + S3 archive |
| Staging | 30 days | Datadog |
| Local | Current session | stdout |

Compliance requires 1 year of audit log retention. See [Compliance](../guides/security/compliance.md) for details.

## See Also

- [Debugging](../guides/debugging.md) — using logs for debugging
- [Error Handling Patterns](error-handling-patterns.md) — logging errors
- [Incident Response](../guides/incident-response.md) — log analysis during incidents

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Pino version, log infrastructure, PII redaction paths, or retention policy changes -->
