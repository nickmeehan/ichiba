# Routing

Nimbus uses React Router v6 with a file-convention-based route organization. Routes are lazy-loaded to minimize initial bundle size and are protected by role-based guards. The routing layer also generates breadcrumbs and supports deep linking into specific project views.

## Route Organization

Routes are defined in `src/routes/` and grouped by domain:

```
src/routes/
  _app.tsx              # Root layout (authenticated shell)
  _public.tsx           # Public layout (login, signup)
  dashboard/
    index.tsx           # /dashboard
    projects/
      index.tsx         # /dashboard/projects
      [projectId].tsx   # /dashboard/projects/:projectId
      [projectId]/
        board.tsx       # /dashboard/projects/:projectId/board
        timeline.tsx    # /dashboard/projects/:projectId/timeline
        settings.tsx    # /dashboard/projects/:projectId/settings
  admin/
    index.tsx           # /admin
    tenants.tsx         # /admin/tenants
    billing.tsx         # /admin/billing
```

All route components are default-exported and wrapped with `React.lazy()` in the route configuration file (`src/routes/config.tsx`).

## Lazy Loading

Every route beyond the root layout is code-split using `React.lazy` and `Suspense`. The suspense fallback renders a skeleton matching the target page layout to prevent layout shift.

```tsx
const ProjectBoard = lazy(() => import("./dashboard/projects/[projectId]/board"));

<Route
  path="projects/:projectId/board"
  element={
    <Suspense fallback={<BoardSkeleton />}>
      <ProjectBoard />
    </Suspense>
  }
/>
```

Prefetch route chunks on hover using the `usePrefetchRoute` hook for navigation links that users are likely to click.

## Route Guards

Route guards are implemented as wrapper components that check permissions before rendering children:

- **`AuthGuard`**: Redirects unauthenticated users to `/login`. Wraps `_app.tsx`.
- **`TenantGuard`**: Ensures the user belongs to the tenant in the URL. Shows a 403 page otherwise.
- **`RoleGuard`**: Checks the user's role (member, admin, owner) against the minimum required role for the route.
- **`FeatureGuard`**: Checks feature flags before rendering. Renders a "coming soon" page if the feature is disabled.

Guards compose from outside in: `AuthGuard > TenantGuard > RoleGuard > FeatureGuard > Page`.

## Breadcrumbs

Breadcrumbs are auto-generated from the route hierarchy. Each route can define a `handle` export with a `breadcrumb` function:

```tsx
export const handle = {
  breadcrumb: (params: { projectId: string }) => {
    const project = useProject(params.projectId);
    return project?.name ?? "Project";
  },
};
```

The `Breadcrumbs` component in the shell reads all matched route handles via `useMatches()` and renders the chain.

## Deep Linking

Nimbus supports deep links to specific entities. The format is `/go/:entityType/:entityId`, which resolves to the canonical URL for that entity. This is used in email notifications, Slack integrations, and API responses.

Examples:
- `/go/task/task_abc123` resolves to `/dashboard/projects/proj_456/board?task=task_abc123`
- `/go/comment/cmt_789` resolves to the parent task with the comment scrolled into view

## See Also

- [State Management](state-management.md) for URL state and query parameter handling
- [Performance](performance.md) for code splitting and lazy loading details
- [SSR](ssr.md) for server-side route handling in Next.js

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: React Router is upgraded or route structure is reorganized -->
