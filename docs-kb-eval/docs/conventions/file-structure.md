# File Structure

Nimbus uses a feature-based directory layout within each app, with shared cross-cutting concerns in a `shared/` package. This guide explains the conventions.

## Monorepo Layout

```
nimbus/
├── apps/
│   ├── web/                # Next.js frontend
│   ├── api/                # Express API server
│   └── worker/             # Background job processor
├── packages/
│   ├── db/                 # Prisma schema + migrations
│   ├── shared/             # Shared types, schemas, utils
│   ├── ui/                 # Design system (Storybook)
│   └── test-utils/         # Test factories and helpers
├── infra/                  # Terraform modules
├── scripts/                # Developer tooling
└── tests/
    ├── e2e/                # Playwright E2E tests
    ├── load/               # k6 load tests
    └── fixtures/           # Shared test fixtures
```

## Feature-Based Layout (API)

Within `apps/api/src/`, code is organized by feature domain:

```
apps/api/src/
├── features/
│   ├── tasks/
│   │   ├── task.controller.ts
│   │   ├── task.service.ts
│   │   ├── task.service.test.ts
│   │   ├── task.routes.ts
│   │   └── task.types.ts
│   ├── projects/
│   │   ├── project.controller.ts
│   │   ├── project.service.ts
│   │   └── ...
│   └── billing/
│       └── ...
├── middleware/
│   ├── auth.ts
│   ├── csrf.ts
│   ├── error-handler.ts
│   └── tenant-context.ts
├── lib/
│   ├── prisma.ts
│   ├── redis.ts
│   └── logger.ts
└── server.ts
```

## Feature-Based Layout (Web)

Within `apps/web/src/`, React code is organized by route and feature:

```
apps/web/src/
├── app/                    # Next.js App Router pages
│   ├── (auth)/
│   │   ├── login/
│   │   └── signup/
│   ├── (dashboard)/
│   │   ├── projects/
│   │   └── settings/
│   └── layout.tsx
├── features/
│   ├── tasks/
│   │   ├── components/
│   │   ├── hooks/
│   │   └── api/
│   └── projects/
│       └── ...
├── shared/
│   ├── components/         # App-level shared components
│   ├── hooks/              # App-level shared hooks
│   └── lib/                # Utilities
└── providers/              # React context providers
```

## Shared Package (`packages/shared/`)

Cross-cutting concerns that are used by multiple apps live in the shared package:

```
packages/shared/src/
├── schemas/                # Zod schemas (shared between API and web)
├── types/                  # TypeScript type definitions
├── constants/              # Shared constants
├── utils/                  # Pure utility functions
└── flags/                  # Feature flag helpers
```

## Barrel Exports

Each feature directory has an `index.ts` that re-exports its public API:

```typescript
// features/tasks/index.ts
export { TaskService } from './task.service';
export { taskRoutes } from './task.routes';
export type { Task, CreateTaskInput } from './task.types';
```

Import from the barrel, not from internal files:

```typescript
// Good
import { TaskService } from '../features/tasks';

// Bad
import { TaskService } from '../features/tasks/task.service';
```

## See Also

- [Naming Conventions](naming.md) — file and directory naming rules
- [React Patterns](react-patterns.md) — component organization
- [Onboarding](../guides/onboarding.md) — codebase tour for new developers

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: monorepo structure, package boundaries, or directory conventions change -->
