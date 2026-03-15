# Getting Started

This guide walks you through setting up the Nimbus development environment on your local machine. By the end, you will have the full stack running and be able to execute the test suite.

## Prerequisites

Before you begin, ensure the following tools are installed:

| Tool       | Version | Notes                                      |
|------------|---------|---------------------------------------------|
| Node.js    | 20 LTS  | Use `nvm install 20` if managing versions   |
| Docker     | 24+     | Docker Desktop or Docker Engine on Linux     |
| PostgreSQL | 15+     | Can run via Docker instead of a local install|
| Redis      | 7+      | Used for caching and the event bus           |
| pnpm       | 9+      | Workspace-aware package manager              |

## Clone and Install

```bash
git clone git@github.com:nimbus-pm/nimbus.git
cd nimbus
pnpm install
```

The monorepo uses pnpm workspaces. All packages (`frontend`, `backend`, `shared`) are installed in a single pass.

## Environment Variables

Copy the example environment file and fill in the required values:

```bash
cp .env.example .env
```

Key variables to configure:

| Variable             | Description                          | Example                          |
|----------------------|--------------------------------------|----------------------------------|
| `DATABASE_URL`       | PostgreSQL connection string         | `postgres://nimbus:pass@localhost:5432/nimbus_dev` |
| `REDIS_URL`          | Redis connection string              | `redis://localhost:6379`         |
| `JWT_SECRET`         | Secret for signing JWT tokens        | Any 64-character random string   |
| `TENANT_ISOLATION`   | Enable row-level tenant checks       | `true`                           |
| `S3_BUCKET`          | File storage bucket (local MinIO OK) | `nimbus-uploads-dev`             |

## Running the Application

Start the infrastructure dependencies with Docker Compose, then launch the backend and frontend:

```bash
docker compose up -d postgres redis minio
pnpm run db:migrate
pnpm run db:seed
pnpm run dev
```

The frontend is available at `http://localhost:3000` and the API at `http://localhost:4000/api`.

## Running Tests

```bash
# Unit tests
pnpm run test

# Integration tests (requires running Postgres and Redis)
pnpm run test:integration

# End-to-end tests (requires the full stack running)
pnpm run test:e2e
```

Test coverage reports are written to `coverage/` in each package directory.

## Common Issues

- **Port conflicts**: If port 3000 or 4000 is in use, set `FRONTEND_PORT` or `BACKEND_PORT` in your `.env`.
- **Migration failures**: Run `pnpm run db:reset` to drop and recreate the development database.
- **Docker memory**: Allocate at least 4 GB of RAM to Docker Desktop for reliable local runs.

## See Also

- [Project Overview](./project-overview.md) - Architecture and technology choices
- [Glossary](./glossary.md) - Domain terminology used throughout the codebase
- [Database Schema](./architecture/database/schema.md) - Table structure and relationships

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Node.js LTS version changes or Docker Compose config is modified -->
