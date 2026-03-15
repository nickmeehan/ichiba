# Server-Side Rendering

Nimbus uses Next.js 14 with the App Router for server-side rendering. SSR is used selectively based on page requirements: marketing pages and shared project views are server-rendered for SEO, while the authenticated dashboard uses client-side rendering with streaming for faster interactions.

## SSR vs SSG Decisions

| Page Type | Strategy | Reason |
|-----------|----------|--------|
| Marketing/landing pages | Static Generation (SSG) | Content rarely changes; needs fast loads and SEO |
| Blog posts | ISR (revalidate: 3600) | Updated infrequently; SEO important |
| Public project views | SSR | Content is dynamic per project; needs SEO for shared links |
| Login / signup | SSR | Needs fast initial load; minimal dynamic content |
| Authenticated dashboard | CSR with streaming | Highly interactive; personalized; no SEO needed |
| Admin panel | CSR | Internal only; no SEO requirement |

## Data Fetching Strategies

### Server Components

Server components fetch data directly using `async/await` without client-side state management:

```tsx
// app/projects/[projectId]/page.tsx
export default async function ProjectPage({ params }: { params: { projectId: string } }) {
  const project = await fetchProject(params.projectId);
  const tasks = await fetchTasks(params.projectId, { limit: 50 });

  return (
    <ProjectLayout project={project}>
      <TaskList initialTasks={tasks} />
    </ProjectLayout>
  );
}
```

Server components handle data fetching for the initial render. Interactive components receive initial data as props and use React Query for subsequent updates.

### Streaming with Suspense

Heavy data loads use `Suspense` boundaries to stream content progressively:

```tsx
export default async function DashboardPage() {
  return (
    <div>
      <DashboardHeader />
      <Suspense fallback={<ProjectListSkeleton />}>
        <ProjectList />
      </Suspense>
      <Suspense fallback={<ActivitySkeleton />}>
        <RecentActivity />
      </Suspense>
    </div>
  );
}
```

This allows the shell and fast-loading sections to appear immediately while slower queries stream in.

## SEO Optimization

Pages that require SEO use the Next.js `metadata` API:

- **Dynamic metadata**: Project and task pages generate `title`, `description`, and `og:image` from the entity data.
- **Canonical URLs**: Every page sets a canonical URL to prevent duplicate content issues across tenant subdomains.
- **Structured data**: Project pages include `Organization` and `Project` JSON-LD schemas.
- **Sitemap**: Generated dynamically at `/sitemap.xml` for public project pages.
- **hreflang**: Multi-language pages include `hreflang` alternate links for all supported locales.

## Hydration

To avoid hydration mismatches:

- Never access `window`, `localStorage`, or browser APIs in server components
- Use the `useIsClient` hook to conditionally render browser-dependent content
- Date formatting uses the server's locale during SSR and the client's locale after hydration (differences are reconciled with `suppressHydrationWarning` on date elements)

## See Also

- [Performance](performance.md) for how SSR impacts Core Web Vitals
- [I18n](i18n.md) for server-side locale detection and hreflang tags
- [Data Fetching](data-fetching.md) for the interplay between server components and React Query

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Next.js is upgraded or rendering strategy changes -->
