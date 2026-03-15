# React Patterns

This guide covers the React component patterns and conventions used in the Nimbus frontend (`apps/web` and `packages/ui`).

## Function Components Only

All React components are function components. Class components are not used in the Nimbus codebase.

```typescript
// Good
export function TaskCard({ task }: TaskCardProps) {
  return <div>{task.title}</div>;
}

// Not used
class TaskCard extends React.Component<TaskCardProps> { ... }
```

Use named exports, not default exports. This ensures consistent import names and better refactoring support.

## Custom Hooks

Extract reusable stateful logic into custom hooks. Hooks live in the `hooks/` directory within each feature:

```typescript
// features/tasks/hooks/use-tasks.ts
export function useTasks(projectId: string) {
  return useQuery({
    queryKey: ['tasks', projectId],
    queryFn: () => api.getTasks(projectId),
    staleTime: 30_000,
  });
}

// features/tasks/hooks/use-create-task.ts
export function useCreateTask() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: api.createTask,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['tasks'] }),
  });
}
```

## Compound Components

For complex UI components with shared state, use the compound component pattern:

```typescript
// packages/ui/src/components/Tabs/Tabs.tsx
const TabsContext = createContext<TabsContextValue | null>(null);

export function Tabs({ children, defaultValue }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultValue);
  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div role="tablist">{children}</div>
    </TabsContext.Provider>
  );
}

Tabs.Tab = function Tab({ value, children }: TabProps) {
  const { activeTab, setActiveTab } = useContext(TabsContext)!;
  return (
    <button role="tab" aria-selected={activeTab === value} onClick={() => setActiveTab(value)}>
      {children}
    </button>
  );
};

// Usage
<Tabs defaultValue="details">
  <Tabs.Tab value="details">Details</Tabs.Tab>
  <Tabs.Tab value="comments">Comments</Tabs.Tab>
</Tabs>
```

## Render Props

Use render props when a component needs to delegate rendering to the consumer:

```typescript
<DataTable
  data={tasks}
  columns={columns}
  renderRow={(task) => <TaskRow key={task.id} task={task} />}
  renderEmpty={() => <EmptyState message="No tasks found" />}
/>
```

Prefer render props over component props (`renderRow` vs. `RowComponent`) for explicit typing.

## Context Usage

Use React Context sparingly. It is appropriate for:

- **Theme**: Light/dark mode.
- **Auth**: Current user and tenant.
- **Tenant context**: Current tenant ID and plan.
- **Feature flags**: Flag evaluation results.

Do not use context for server state (API data). Use React Query instead.

## React Query

All server state is managed by [React Query](https://tanstack.com/query) (TanStack Query):

- **Queries** (`useQuery`): For reading data. Configure `staleTime` and `gcTime` appropriately.
- **Mutations** (`useMutation`): For creating, updating, and deleting data. Invalidate related queries on success.
- **Prefetching**: Use `queryClient.prefetchQuery` on hover or route transition for instant page loads.

Never store API data in `useState` or `useReducer`. Let React Query manage the cache.

## See Also

- [TypeScript Style](typescript-style.md) — typing components and hooks
- [File Structure](file-structure.md) — component directory organization
- [Visual Regression](../testing/visual-regression.md) — Storybook and Chromatic

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: React version, React Query version, or component patterns change -->
