# Feature Flags

Nimbus uses LaunchDarkly for feature flag management. Flags allow us to decouple deployment from release, enabling trunk-based development and gradual rollouts.

## LaunchDarkly Integration

The LaunchDarkly SDK is initialized in `packages/shared/src/flags.ts`. Both the API server and the Next.js frontend evaluate flags:

```typescript
// Server-side (API)
import { getFlag } from '@nimbus/shared/flags';
const enabled = await getFlag('project.gantt-view', { tenantId, userId });

// Client-side (React)
import { useFlag } from '@nimbus/shared/flags/react';
const enabled = useFlag('project.gantt-view');
```

In local development, when `LD_SDK_KEY` is not set, flags fall back to values in `flags.local.json` at the repo root.

## Flag Naming Conventions

Flags follow a dot-delimited naming scheme:

```
<domain>.<feature-name>
```

Examples:
- `billing.annual-plans` — enables annual billing plans
- `project.gantt-view` — enables the Gantt chart view in projects
- `debug.verbose-logging` — turns on verbose logging for a tenant

Temporary flags (for rollouts) should be prefixed with `rollout.`:
- `rollout.new-task-editor` — gradual rollout of new task editor

## Gradual Rollouts

For significant features, use percentage-based rollouts:

1. **Internal only** (0%): Flag on for `nimbus.io` tenant only.
2. **Beta** (5%): Enable for opt-in beta tenants.
3. **Gradual** (25% then 50% then 100%): Increase over 1-2 weeks, monitoring error rates and performance.
4. **GA**: Remove the flag (see cleanup below).

Monitor rollout health in the Datadog dashboard: `Nimbus > Feature Rollouts`.

## Flag Cleanup

Stale flags create tech debt. Every flag must have a cleanup ticket created at the time the flag is introduced. The lifecycle:

1. **Create flag** — open a cleanup ticket with a target date (typically 30 days after 100% rollout).
2. **Reach 100%** — start the cleanup timer.
3. **Remove flag** — delete the flag check from code, remove from LaunchDarkly, close the ticket.

Run the stale flag report weekly: `pnpm flags:stale`. Flags older than 90 days at 100% are reported to the tech lead.

## Targeting Rules

LaunchDarkly targeting supports:
- **Tenant-level**: Enable for specific tenants by `tenantId`.
- **User-level**: Enable for specific users (useful for internal testing).
- **Percentage**: Random consistent bucketing by `userId`.
- **Plan-level**: Enable for tenants on specific billing plans (`pro`, `enterprise`).

Always use `tenantId` as the primary bucketing key for multi-tenant consistency.

## See Also

- [Canary Deployment](deployment/canary.md) — using flags with canary releases
- [Local Development](local-dev.md) — local flag overrides
- [Testing with Flags](../testing/unit-tests.md) — mocking flags in tests

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: LaunchDarkly SDK version changes or flag governance policy updates -->
