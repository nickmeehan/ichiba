# Data Fetching

Nimbus uses React Query (TanStack Query v5) for all client-side data fetching. React Query handles caching, background refetching, optimistic updates, and pagination. All API calls go through a centralized `apiClient` that handles authentication, tenant headers, and error normalization.

## React Query Patterns

Every data-fetching operation is wrapped in a custom hook that encapsulates the query key, fetch function, and configuration:

```tsx
export function useTasks(projectId: string, filters: TaskFilters) {
  return useQuery({
    queryKey: ["tasks", projectId, filters],
    queryFn: () => apiClient.get(`/projects/${projectId}/tasks`, { params: filters }),
    staleTime: 30_000,
  });
}
```

Custom hooks live in `src/hooks/queries/` grouped by domain (e.g., `useTasks.ts`, `useProjects.ts`, `useUsers.ts`).

## Query Key Conventions

Query keys follow a hierarchical structure to enable targeted invalidation:

```
[entity]                          // all tasks
[entity, id]                      // single task
[entity, parentId]                // tasks for a project
[entity, parentId, filters]       // tasks for a project with filters
```

Examples:
- `["projects"]` - all projects for the current tenant
- `["projects", "proj_123"]` - a single project
- `["tasks", "proj_123", { status: "open", assignee: "user_456" }]` - filtered tasks
- `["comments", "task_789"]` - comments on a task

Invalidation helpers are defined in `src/hooks/queries/invalidation.ts`:

```ts
export const invalidateTasks = (projectId: string) =>
  queryClient.invalidateQueries({ queryKey: ["tasks", projectId] });
```

## Optimistic Updates

Mutations that affect visible UI use optimistic updates to provide instant feedback:

```tsx
export function useUpdateTaskStatus() {
  return useMutation({
    mutationFn: (vars: { taskId: string; status: TaskStatus }) =>
      apiClient.patch(`/tasks/${vars.taskId}`, { status: vars.status }),
    onMutate: async (vars) => {
      await queryClient.cancelQueries({ queryKey: ["tasks"] });
      const previous = queryClient.getQueryData(["tasks", vars.taskId]);
      queryClient.setQueryData(["tasks", vars.taskId], (old: Task) => ({
        ...old,
        status: vars.status,
      }));
      return { previous };
    },
    onError: (_err, vars, context) => {
      queryClient.setQueryData(["tasks", vars.taskId], context?.previous);
      toast.error("Failed to update task status");
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
    },
  });
}
```

## Infinite Scroll

List views with large datasets use `useInfiniteQuery` for cursor-based pagination:

```tsx
export function useTasksInfinite(projectId: string) {
  return useInfiniteQuery({
    queryKey: ["tasks", projectId, "infinite"],
    queryFn: ({ pageParam }) =>
      apiClient.get(`/projects/${projectId}/tasks`, { params: { cursor: pageParam, limit: 25 } }),
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    initialPageParam: undefined,
  });
}
```

The `InfiniteList` component observes a sentinel element via `IntersectionObserver` and calls `fetchNextPage` when it enters the viewport.

## Prefetching

Nimbus prefetches data for routes the user is likely to navigate to:

- **Hover prefetch**: When hovering over a project link, the project detail and its tasks are prefetched.
- **Route prefetch**: The `usePrefetchRoute` hook prefetches data for visible navigation items.
- **Parallel prefetch**: Dashboard pages prefetch multiple independent queries in parallel using `Promise.all`.

```tsx
const prefetchProject = (projectId: string) => {
  queryClient.prefetchQuery({
    queryKey: ["projects", projectId],
    queryFn: () => apiClient.get(`/projects/${projectId}`),
    staleTime: 60_000,
  });
};
```

## See Also

- [State Management](state-management.md) for when to use React Query vs other state solutions
- [WebSockets](websockets.md) for real-time cache invalidation via socket events
- [SSR](ssr.md) for server-side data fetching and hydration

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: TanStack Query is upgraded or API client patterns change -->
