# Project Overview

Nimbus is a multi-tenant project management platform designed for engineering teams that need customizable workflows, real-time collaboration, and deep integrations with developer tools. The system is built as a monorepo with clear separation between frontend, backend, and shared packages.

## Technology Stack

| Layer        | Technology              | Purpose                              |
|-------------|-------------------------|---------------------------------------|
| Frontend    | React 18 + TypeScript   | Single-page application               |
| Backend     | Node.js + Express       | REST API and WebSocket server          |
| Database    | PostgreSQL 15           | Primary data store                     |
| Cache       | Redis 7                 | Caching, pub/sub, job queues           |
| Search      | Elasticsearch 8         | Full-text search across entities       |
| Analytics   | ClickHouse              | Time-series analytics and reporting    |
| Storage     | S3-compatible (MinIO)   | File attachments and media             |
| CI/CD       | GitHub Actions           | Build, test, and deploy pipelines     |

## Monorepo Structure

```
nimbus/
  packages/
    frontend/       # React SPA (Vite, TailwindCSS)
    backend/        # Express API server
    shared/         # TypeScript types, validation schemas, constants
    workers/        # Background job processors (BullMQ)
    websocket/      # WebSocket server for real-time updates
  infrastructure/
    terraform/      # Cloud resource definitions
    kubernetes/     # Deployment manifests
  tools/
    scripts/        # Build and deployment scripts
    migrations/     # Knex.js database migrations
```

## Multi-Tenancy Model

Nimbus uses a shared-database multi-tenant architecture. Every row in tenant-scoped tables includes a `tenant_id` column, and a middleware layer injects the current tenant context into every database query. Row-level security policies in PostgreSQL act as a safety net to prevent cross-tenant data leakage even if application-level checks are bypassed.

## Backend Architecture

The backend follows a layered pattern:

1. **Routes** define Express endpoints and attach middleware.
2. **Controllers** parse and validate incoming requests.
3. **Services** contain business logic and orchestrate domain operations.
4. **Repositories** encapsulate database access using Knex.js query builder.

Cross-cutting concerns like authentication, rate limiting, and tenant context are handled by middleware that runs before the controller layer.

## Frontend Architecture

The frontend is a React SPA bootstrapped with Vite. State management uses Zustand for client state and TanStack Query for server state. The component library is built on Radix UI primitives styled with TailwindCSS. Real-time updates arrive via a persistent WebSocket connection managed by a custom hook.

## Key Design Decisions

- **Monorepo over microservices**: Reduces deployment complexity while the team is small. Service extraction is planned when team size exceeds 20 engineers.
- **Shared database over database-per-tenant**: Simpler operations at current scale. Sharding is designed but not yet implemented.
- **Event-driven side effects**: Domain events decouple core operations from notifications, audit logging, and integrations.

## See Also

- [Getting Started](./getting-started.md) - Local development setup
- [System Design](./architecture/system-design.md) - Detailed architecture diagrams
- [Multi-Tenancy](./architecture/multi-tenancy.md) - Tenant isolation implementation

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Major architectural decisions change or new infrastructure components are adopted -->
