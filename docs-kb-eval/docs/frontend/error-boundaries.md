# Error Boundaries

Nimbus uses a hierarchical error boundary system to catch runtime errors, display helpful fallback UIs, and report issues to Sentry. The goal is to contain failures to the smallest possible UI region so that a crash in one component does not take down the entire page.

## Error Boundary Hierarchy

Error boundaries are layered from broad to narrow:

1. **App-level boundary** (`AppErrorBoundary`): Catches catastrophic failures that escape all other boundaries. Renders a full-page error screen with a "Reload Application" button. This is the boundary of last resort.

2. **Route-level boundary** (`RouteErrorBoundary`): Wraps each route's content area. If a page crashes, the shell (sidebar, header) remains functional and the user can navigate away. Shows a "Something went wrong" message with a "Try Again" button that re-mounts the route.

3. **Section-level boundary** (`SectionErrorBoundary`): Wraps independent page sections (e.g., activity feed, chart widgets, comment thread). A crash in the activity feed does not affect the task detail panel.

4. **Component-level boundary** (`ComponentErrorBoundary`): Wraps individual risky components such as third-party embeds, markdown renderers, and chart visualizations. Shows a compact inline error indicator.

```tsx
<AppErrorBoundary>
  <Shell>
    <RouteErrorBoundary key={location.pathname}>
      <SectionErrorBoundary name="task-detail">
        <TaskDetail />
      </SectionErrorBoundary>
      <SectionErrorBoundary name="activity-feed">
        <ActivityFeed />
      </SectionErrorBoundary>
    </RouteErrorBoundary>
  </Shell>
</AppErrorBoundary>
```

## Fallback UIs

Each boundary level has a different fallback appropriate to its scope:

| Level | Fallback | User Actions |
|-------|----------|-------------|
| App | Full-page error with illustration | Reload page, contact support |
| Route | Error card in content area | Retry, navigate to another page |
| Section | Inline error banner | Retry section, collapse section |
| Component | Small error icon with tooltip | Hover for details, retry |

All fallbacks include an error ID (e.g., `ERR-a1b2c3`) that users can reference when contacting support. This ID maps to the Sentry event.

## Sentry Integration

When an error boundary catches an error, it reports to Sentry with:

- The error message and stack trace
- The boundary level and component name
- The current route and URL parameters
- The active tenant ID and user ID (PII-safe identifiers)
- A breadcrumb trail of recent user actions (clicks, navigations, API calls)

Sentry is configured in `src/lib/sentry.ts`. The DSN is loaded from environment variables. Source maps are uploaded during the build step for readable stack traces.

```ts
Sentry.withScope((scope) => {
  scope.setTag("boundary", "route");
  scope.setTag("component", componentName);
  scope.setContext("route", { path: location.pathname, params });
  Sentry.captureException(error);
});
```

## Recovery Strategies

Error boundaries implement several recovery strategies:

- **Retry**: The `onRetry` callback resets the boundary's error state using a key change, forcing React to re-mount the children. Limited to 3 retries to prevent infinite loops.
- **Graceful degradation**: When a non-critical section fails, the boundary renders a simplified version (e.g., a static list instead of an interactive chart).
- **State reset**: Route-level boundaries clear relevant React Query caches and Zustand state on retry to ensure the re-mount starts fresh.
- **User feedback**: A "Report this issue" link pre-fills a support form with the error ID and context.

## See Also

- [Data Fetching](data-fetching.md) for handling API errors and query error states
- [Performance](performance.md) for lazy loading error handling with Suspense
- [WebSockets](websockets.md) for connection error recovery

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Sentry SDK is upgraded or error boundary hierarchy is restructured -->
