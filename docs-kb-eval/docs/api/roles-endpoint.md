# Roles Endpoint

The Roles API manages custom role definitions and permission sets. Roles determine what actions users can perform within a workspace or project.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/roles` | List all roles in the workspace |
| POST | `/v1/roles` | Create a custom role |
| GET | `/v1/roles/{id}` | Get role details with permissions |
| PATCH | `/v1/roles/{id}` | Update a role |
| DELETE | `/v1/roles/{id}` | Delete a custom role |
| GET | `/v1/roles/{id}/users` | List users assigned to this role |

## Built-In Roles

Every workspace includes these default roles that cannot be deleted:

| Role | Description |
|------|-------------|
| `owner` | Full access, can manage billing and delete workspace |
| `admin` | Full access except billing and workspace deletion |
| `member` | Create and manage own tasks, view all projects they belong to |
| `viewer` | Read-only access to assigned projects |
| `guest` | Limited access to specific resources shared with them |

## Custom Role Definitions

Create roles with granular permission sets:

```json
POST /v1/roles
{
  "name": "Project Manager",
  "description": "Can manage projects and team assignments",
  "permissions": [
    "projects:read",
    "projects:write",
    "projects:manage_members",
    "tasks:read",
    "tasks:write",
    "tasks:assign",
    "sprints:manage",
    "reports:read",
    "reports:create"
  ]
}
```

## Permission Sets

Permissions follow the format `resource:action`. Available resources and actions:

| Resource | Actions |
|----------|---------|
| `projects` | `read`, `write`, `delete`, `manage_members`, `manage_settings` |
| `tasks` | `read`, `write`, `delete`, `assign`, `transition` |
| `comments` | `read`, `write`, `delete_own`, `delete_any` |
| `sprints` | `read`, `manage` |
| `reports` | `read`, `create`, `schedule` |
| `admin` | `read`, `write`, `manage_users`, `manage_billing` |

## Role Assignment

Assign roles to users at workspace or project level:

```json
PATCH /v1/users/user_12
{
  "role_id": "role_pm"
}
```

Users can have different roles in different projects. Project-level role assignments override workspace-level roles for that project.

## Role Hierarchy

Roles can extend other roles using the `extends` field:

```json
POST /v1/roles
{
  "name": "Senior PM",
  "extends": "role_pm",
  "additional_permissions": ["admin:read", "reports:schedule"]
}
```

## See Also

- [Permissions Endpoint](permissions-endpoint.md) — fine-grained permission checks
- [Users Endpoint](users-endpoint.md) — user role assignment
- [Teams Endpoint](teams-endpoint.md) — team-level roles
- [Admin Endpoint](admin-endpoint.md) — workspace role administration
- [Authentication](authentication.md) — OAuth scopes vs roles

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: built-in roles, permission format, or role hierarchy behavior changes -->
