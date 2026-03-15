# Frontend Performance

Nimbus targets a Lighthouse performance score of 90+ on all key pages. We monitor bundle size, runtime performance, and Core Web Vitals continuously. Performance budgets are enforced in CI, and regressions block merges.

## Bundle Size Monitoring

The CI pipeline runs `size-limit` on every pull request, comparing the bundle size against the `main` branch. Budgets are defined in `.size-limit.js`:

| Chunk | Budget | Current |
|-------|--------|---------|
| Initial JS | 150 KB gzipped | 132 KB |
| Initial CSS | 30 KB gzipped | 24 KB |
| Largest route chunk | 50 KB gzipped | 41 KB |
| Total (all routes) | 800 KB gzipped | 687 KB |

If a PR exceeds any budget by more than 5%, it is flagged for review. Use `pnpm analyze` to run `@next/bundle-analyzer` and inspect what is contributing to the size.

## Code Splitting

Routes are split using `React.lazy()` (see [Routing](routing.md)). Beyond route-level splitting, heavy libraries are loaded on demand:

- **Chart.js**: Loaded only on dashboard and reporting pages
- **Monaco Editor**: Loaded only in the template editor
- **PDF generation**: Loaded only when the user exports a report
- **Markdown renderer**: Loaded only in task description views

Use dynamic `import()` for any dependency over 20 KB that is not needed on initial render.

## Image Optimization

All images served through Nimbus use the following pipeline:

1. User uploads are processed by the backend into multiple sizes (thumbnail, medium, large, original)
2. Images are served via Cloudfront CDN with `Accept` header-based format negotiation (WebP, AVIF, fallback to JPEG)
3. The `<NimbusImage>` component handles lazy loading, blur placeholder, and responsive `srcSet`
4. Avatar images use a 48x48 thumbnail by default and only load the full image on profile pages

## Virtual Scrolling

Lists with more than 100 items use `@tanstack/react-virtual` for virtualized rendering. This applies to:

- Task lists in list view (projects may have thousands of tasks)
- Activity feeds
- User directory for large tenants
- Notification history

The `VirtualList` component wraps TanStack Virtual and provides consistent scroll behavior, keyboard navigation, and loading indicators for infinite scroll.

## React.memo and Render Optimization

Guidelines for preventing unnecessary re-renders:

- **Memoize expensive components**: Wrap components that receive complex props with `React.memo`. Provide a custom comparison function when props include objects or arrays.
- **Use `useMemo` for derived data**: Computed values like filtered lists or aggregated counts should be memoized.
- **Use `useCallback` for handlers passed to memoized children**: Prevents child re-renders caused by new function references.
- **Avoid inline objects and arrays in JSX**: `style={{ color: "red" }}` creates a new object every render. Extract to a constant or use CSS classes.

The React DevTools Profiler is the primary tool for diagnosing render performance issues. Run `pnpm dev:profile` to start the app with profiling enabled.

## Core Web Vitals

We track LCP, FID, and CLS using `web-vitals` library, reporting to our analytics backend. Targets:

- **LCP** (Largest Contentful Paint): < 2.5 seconds
- **FID** (First Input Delay): < 100 milliseconds
- **CLS** (Cumulative Layout Shift): < 0.1

## See Also

- [Routing](routing.md) for route-level code splitting and lazy loading
- [Data Fetching](data-fetching.md) for prefetching strategies that improve perceived performance
- [SSR](ssr.md) for server-side rendering impact on initial load

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: performance budgets are adjusted or new optimization techniques are adopted -->
