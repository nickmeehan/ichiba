# Architecture

This section documents the technical architecture of the Nimbus platform. Start here when you need to understand how the system is structured, how data moves through it, or how cross-cutting concerns are handled.

## Contents

### [System Design](./system-design.md)
When you need to understand the overall system structure, component boundaries, or how the monorepo packages relate to each other.

### [Data Flow](./data-flow.md)
When you are tracing a request from the client through the backend, or you need to understand how events propagate between services.

### [Error Handling](./error-handling.md)
When you are adding new error types, debugging unexpected error responses, or need to understand how errors are logged and reported.

### [Caching](./caching.md)
When you need to cache a new entity type, troubleshoot stale data, or understand cache invalidation behavior after writes.

### [Event-Driven Architecture](./event-driven.md)
When you are adding a new domain event, implementing a side-effect handler, or debugging why an event-triggered action did not fire.

### [Multi-Tenancy](./multi-tenancy.md)
When you are writing queries that touch tenant-scoped data, adding new tables, or investigating a potential cross-tenant data leak.

### [Services](./services/_index.md)
When you need details on a specific backend service such as authentication, billing, notifications, or any of the third-party integrations.

### [Database](./database/_index.md)
When you are working with the database schema, writing migrations, optimizing queries, or managing replication and backups.

### [Infrastructure](./infrastructure/_index.md)
When you need to understand the deployment environment, Kubernetes configuration, Terraform modules, or monitoring and alerting setup.

## See Also

- [Project Overview](../project-overview.md) - High-level technology choices and design rationale
- [Getting Started](../getting-started.md) - Local development setup

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New top-level architecture sections are added or existing sections are reorganized -->
