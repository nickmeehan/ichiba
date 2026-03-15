# System Design

Nimbus is structured as a TypeScript monorepo with distinct packages for the frontend, backend API, background workers, and WebSocket server. This document describes how these components fit together and where each responsibility lives.

## Component Overview

```
                 ┌──────────────┐
                 │   CDN/Edge   │
                 └──────┬───────┘
                        │
            ┌───────────┴───────────┐
            │    Load Balancer      │
            └───┬───────────────┬───┘
                │               │
     ┌──────────▼──┐    ┌──────▼────────┐
     │  Frontend   │    │  API Gateway  │
     │  (React)    │    │  (Express)    │
     └─────────────┘    └──┬────────┬───┘
                           │        │
                ┌──────────▼┐  ┌────▼──────────┐
                │  Workers  │  │  WebSocket    │
                │  (BullMQ) │  │  Server       │
                └─────┬─────┘  └───────┬───────┘
                      │                │
              ┌───────▼────────────────▼───────┐
              │           Redis                │
              └───────┬────────────────────────┘
                      │
              ┌───────▼──────────┐
              │   PostgreSQL     │
              └──────────────────┘
```

## Backend Services

The Express API server is the central backend process. It exposes REST endpoints, runs middleware for authentication and tenant context, and delegates business logic to service classes. Request validation uses Zod schemas defined in the shared package.

### Background Workers

Long-running or deferrable tasks execute in a separate worker process powered by BullMQ. Examples include sending notification emails, generating PDF exports, processing file uploads through the virus scanner, and computing analytics rollups. Workers share the same codebase but are deployed as a separate Kubernetes deployment with independent scaling.

### WebSocket Server

Real-time updates are delivered through a dedicated WebSocket server. When a domain event occurs (e.g., a task is moved to a new column), the API publishes a message to a Redis channel. The WebSocket server subscribes to these channels and pushes updates to connected clients who are members of the affected workspace.

## Frontend SPA

The frontend is a React single-page application bundled with Vite. It communicates with the backend exclusively through REST API calls and a WebSocket connection. Routing uses React Router v6 with lazy-loaded route components to keep initial bundle size under 200 KB gzipped.

## Shared Package

The `shared` package contains TypeScript type definitions, Zod validation schemas, constant enumerations, and utility functions used by both frontend and backend. This ensures type safety across the network boundary and prevents definition drift.

## Infrastructure Layer

All cloud resources are defined in Terraform modules. The application runs on a Kubernetes cluster with separate namespaces for staging and production. Secrets are managed through AWS Secrets Manager and injected as environment variables at pod startup.

## Scaling Strategy

- **API server**: Horizontal pod autoscaler based on CPU and request latency.
- **Workers**: Scaled by queue depth using a custom KEDA scaler.
- **WebSocket server**: Scaled by active connection count, with sticky sessions via Redis adapter.
- **PostgreSQL**: Vertical scaling with read replicas for analytics queries.

## See Also

- [Data Flow](./data-flow.md) - How requests traverse the system
- [Multi-Tenancy](./multi-tenancy.md) - Tenant isolation in the shared architecture
- [Kubernetes](./infrastructure/kubernetes.md) - Deployment configuration

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New backend services are introduced or the deployment topology changes -->
