# State Management

Nimbus separates application state into four categories, each managed by a different tool. Choosing the right state location prevents bugs, avoids unnecessary re-renders, and keeps data consistent across the application.

## State Categories

### 1. Global Client State (Zustand)

Zustand stores hold client-only state that multiple components need but does not come from the server. Examples include:

- **UI state**: sidebar open/closed, modal visibility, active tab
- **User preferences**: compact view toggle, notification mute, selected theme
- **Session state**: current tenant ID, impersonation status, feature flags

Each Zustand store lives in `src/stores/` and follows the naming convention `use<Domain>Store.ts`. Stores must be small and focused; avoid catch-all stores.

```ts
// src/stores/useLayoutStore.ts
export const useLayoutStore = create<LayoutState>((set) => ({
  sidebarOpen: true,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
}));
```

Use Zustand's `persist` middleware only for state that must survive page reloads (e.g., user preferences). Use `subscribeWithSelector` when other stores need to react to changes.

### 2. Server State (React Query)

All data fetched from the API is managed by React Query (TanStack Query v5). This includes projects, tasks, users, comments, and any other server-owned data.

Key conventions:
- Query keys follow the pattern `[entity, ...identifiers, params]` (e.g., `["tasks", projectId, { status: "open" }]`)
- Mutations use `onMutate` for optimistic updates and `onError` for rollback
- Stale time defaults to 30 seconds for most queries; real-time entities use 5 seconds
- Cache time defaults to 5 minutes

See [Data Fetching](data-fetching.md) for detailed React Query patterns.

### 3. URL State

Filters, pagination, sorting, and search terms live in the URL as query parameters. This allows users to share and bookmark filtered views. We use a custom `useUrlState` hook built on React Router's `useSearchParams`.

URL state is the source of truth for:
- Table sort column and direction (`?sort=dueDate&dir=asc`)
- Filter selections (`?status=open&assignee=user_123`)
- Pagination (`?page=2&limit=25`)
- Search queries (`?q=deploy+script`)

### 4. Local Component State

Use `useState` or `useReducer` for state that is only relevant to a single component and its direct children. Examples: form input values before submission, tooltip hover state, animation progress.

**Rule of thumb**: If unmounting the component should discard the state, it belongs in local state.

## Anti-Patterns to Avoid

- **Duplicating server state in Zustand**: Never copy API data into a Zustand store. Use React Query's cache instead.
- **Prop drilling through more than 2 levels**: Extract a Zustand store or use React context.
- **Storing derived data**: Compute derived values inline or with `useMemo`. Do not store computed data in state.
- **Global state for form values**: Form state belongs in React Hook Form, not in Zustand.

## See Also

- [Data Fetching](data-fetching.md) for React Query patterns and query key conventions
- [Routing](routing.md) for URL parameter handling
- [Forms](forms.md) for form state management with React Hook Form

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: state management libraries are upgraded or new state categories are introduced -->
