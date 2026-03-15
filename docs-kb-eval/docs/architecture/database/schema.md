# Database Schema

The Nimbus database uses PostgreSQL 15 with a shared multi-tenant schema. All tenant-scoped tables include a `tenant_id` column and standard audit columns. This document describes the core tables and their relationships.

## Core Tables

### workspaces
The top-level tenant table. Each workspace represents one customer account.

| Column        | Type        | Notes                          |
|--------------|-------------|--------------------------------|
| id           | UUID        | Primary key                    |
| name         | VARCHAR(100)| Workspace display name         |
| slug         | VARCHAR(50) | URL-safe identifier, unique    |
| plan         | VARCHAR(20) | Subscription tier              |
| settings     | JSONB       | Workspace-level configuration  |
| created_at   | TIMESTAMPTZ | Record creation time           |
| updated_at   | TIMESTAMPTZ | Last modification time         |

### users
Platform-wide user accounts. A user can belong to multiple workspaces.

| Column        | Type        | Notes                          |
|--------------|-------------|--------------------------------|
| id           | UUID        | Primary key                    |
| email        | VARCHAR(255)| Unique across the platform     |
| password_hash| VARCHAR(255)| Bcrypt hash, nullable for SSO  |
| first_name   | VARCHAR(100)| From profile or SSO            |
| last_name    | VARCHAR(100)| From profile or SSO            |
| avatar_url   | TEXT        | Profile image URL              |
| created_at   | TIMESTAMPTZ | Record creation time           |

### workspace_members
Junction table linking users to workspaces with their role.

| Column        | Type        | Notes                          |
|--------------|-------------|--------------------------------|
| tenant_id    | UUID        | FK to workspaces               |
| user_id      | UUID        | FK to users                    |
| role         | VARCHAR(20) | owner, admin, member, guest    |
| joined_at    | TIMESTAMPTZ | When the user joined           |

### projects
Projects within a workspace.

| Column        | Type        | Notes                          |
|--------------|-------------|--------------------------------|
| id           | UUID        | Primary key                    |
| tenant_id    | UUID        | FK to workspaces               |
| name         | VARCHAR(100)| Project display name           |
| key          | VARCHAR(10) | Short prefix for task IDs      |
| description  | TEXT        | Markdown description           |
| created_at   | TIMESTAMPTZ | Record creation time           |
| updated_at   | TIMESTAMPTZ | Last modification time         |

### tasks
The core work item table.

| Column        | Type        | Notes                          |
|--------------|-------------|--------------------------------|
| id           | UUID        | Primary key                    |
| tenant_id    | UUID        | FK to workspaces               |
| project_id   | UUID        | FK to projects                 |
| title        | VARCHAR(200)| Task title                     |
| description  | TEXT        | Markdown body                  |
| status       | VARCHAR(30) | Current board column           |
| priority     | VARCHAR(10) | low, medium, high, urgent      |
| assignee_id  | UUID        | FK to users, nullable          |
| story_points | INTEGER     | Estimation, nullable           |
| due_date     | DATE        | Deadline, nullable             |
| sprint_id    | UUID        | FK to sprints, nullable        |
| epic_id      | UUID        | FK to epics, nullable          |
| position     | INTEGER     | Sort order within status column|
| created_at   | TIMESTAMPTZ | Record creation time           |
| updated_at   | TIMESTAMPTZ | Last modification time         |

### comments
Comments on tasks.

| Column        | Type        | Notes                          |
|--------------|-------------|--------------------------------|
| id           | UUID        | Primary key                    |
| tenant_id    | UUID        | FK to workspaces               |
| task_id      | UUID        | FK to tasks                    |
| author_id    | UUID        | FK to users                    |
| body         | TEXT        | Markdown content               |
| created_at   | TIMESTAMPTZ | Record creation time           |
| updated_at   | TIMESTAMPTZ | Last edit time                 |

## Audit Columns

All tenant-scoped tables include `created_at` and `updated_at` columns managed by database triggers. The `updated_at` trigger fires on every UPDATE and sets the column to `NOW()`.

## Tenant Isolation

Every table except `users` and `workspaces` includes a `tenant_id` column with a foreign key to `workspaces.id`. Row-level security policies ensure queries can only access rows matching the session's tenant context.

## See Also

- [Migrations](./migrations.md) - How schema changes are applied
- [Indexing](./indexing.md) - Indexes defined on these tables
- [Multi-Tenancy](../multi-tenancy.md) - RLS policy implementation

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Core tables are added or column definitions change -->
