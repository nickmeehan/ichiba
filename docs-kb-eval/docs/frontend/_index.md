# Frontend Documentation

The Nimbus frontend is a React 18 single-page application served via Next.js. It provides the primary interface for project managers, team members, and stakeholders across all tenant organizations. The frontend communicates with backend services through a GraphQL gateway and WebSocket connections for real-time updates.

## Guides

- **[Component Library](component-library.md)**
  Use when building new UI elements or extending existing ones. Covers the Radix UI-based design system, atomic design methodology, and Storybook documentation practices.

- **[State Management](state-management.md)**
  Use when deciding where and how to store application state. Explains the separation between Zustand global stores, React Query server state, URL-driven state, and local component state.

- **[Routing](routing.md)**
  Use when adding new pages, restructuring navigation, or implementing deep links. Covers React Router v6 conventions, lazy loading, route guards, and breadcrumb generation.

- **[Forms](forms.md)**
  Use when building user input flows such as task creation, project settings, or onboarding wizards. Covers React Hook Form integration, Zod validation, and multi-step form patterns.

- **[Accessibility](accessibility.md)**
  Use when ensuring features meet WCAG 2.1 AA requirements. Covers ARIA patterns, keyboard navigation, screen reader testing workflows, and color contrast guidelines.

- **[Internationalization](i18n.md)**
  Use when adding translatable strings, supporting new locales, or formatting dates and numbers. Covers the react-i18next setup, translation workflow, and RTL support.

- **[Theming](theming.md)**
  Use when working with visual appearance, dark/light mode, or tenant-specific branding. Covers CSS variable architecture, design tokens, and the theme provider API.

- **[Performance](performance.md)**
  Use when diagnosing slow renders, large bundle sizes, or scroll jank. Covers code splitting, image optimization, virtual scrolling, and React.memo best practices.

- **[Server-Side Rendering](ssr.md)**
  Use when working on pages that require SEO or fast initial loads. Covers Next.js SSR vs SSG decisions, data fetching strategies, and hydration patterns.

- **[Error Boundaries](error-boundaries.md)**
  Use when handling runtime errors gracefully in the UI. Covers the error boundary hierarchy, fallback components, Sentry integration, and recovery strategies.

- **[Data Fetching](data-fetching.md)**
  Use when loading data from the API, implementing pagination, or optimizing cache behavior. Covers React Query patterns, query key conventions, and optimistic updates.

- **[WebSockets](websockets.md)**
  Use when implementing real-time features such as live task updates, presence indicators, or collaborative editing. Covers Socket.io client setup, reconnection logic, and event handling.

## See Also

- [Data Documentation](../data/_index.md)
- [Ops Documentation](../ops/_index.md)

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: new frontend guide is added or navigation structure changes -->
