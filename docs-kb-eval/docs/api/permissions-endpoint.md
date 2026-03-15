# Permissions Endpoint

The Permissions API provides fine-grained permission checks, resource-level access control, and bulk permission management. It complements the role-based system with per-resource overrides.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/permissions/check` | Check if user has a specific permission |
| GET | `/v1/permissions/effective/{user_id}` | Get effective permissions for a user |
| POST | `/v1/permissions/grants` | Grant a permission on a resource |
| DELETE | `/v1/permissions/grants/{id}` | Revoke a permission grant |
| POST | `/v1/permissions/bulk` | Bulk update permissions |

## Permission Checks

Check whether a user can perform an action on a resource:

```
GET /v1/permissions/check?user_id=user_05&action=tasks:write&resource_id=task_42
```

Response:

```json
{
  "data": {
    "allowed": true,
    "reason": "role_grant",
    "role": "project_admin",
    "project_id": "proj_01"
  }
}
```

The `reason` field explains why access was granted or denied: `role_grant`, `resource_grant`, `team_grant`, `owner`, or `denied`.

## Resource-Level Permissions

Override role-based permissions for specific resources:

```json
POST /v1/permissions/grants
{
  "user_id": "user_12",
  "resource_type": "project",
  "resource_id": "proj_secret",
  "permissions": ["projects:read", "tasks:read"]
}
```

Resource-level grants are additive to role permissions, not replacements.

## Permission Inheritance

Permissions cascade through the resource hierarchy:

1. Workspace role grants baseline permissions
2. Project-level role overrides apply within a project
3. Resource-level grants add specific permissions
4. Explicit deny rules override all grants

The effective permission is computed by evaluating all layers.

## Effective Permissions

Retrieve the full set of effective permissions for a user:

```
GET /v1/permissions/effective/user_05?project_id=proj_01
```

Returns a flat list of all granted permissions with their source.

## Bulk Permission Updates

Update multiple permission grants in a single request:

```json
POST /v1/permissions/bulk
{
  "grants": [
    { "user_id": "user_10", "resource_id": "proj_01", "permissions": ["tasks:write"] },
    { "user_id": "user_11", "resource_id": "proj_01", "permissions": ["tasks:read"] }
  ]
}
```

## Deny Rules

Explicitly deny specific permissions that would otherwise be inherited:

```json
POST /v1/permissions/grants
{
  "user_id": "user_12",
  "resource_type": "project",
  "resource_id": "proj_confidential",
  "deny": ["tasks:delete"]
}
```

Deny rules take precedence over all other grants.

## See Also

- [Roles Endpoint](roles-endpoint.md) — role-based permission sets
- [Authentication](authentication.md) — OAuth scopes
- [Teams Endpoint](teams-endpoint.md) — team-level permissions
- [Projects Endpoint](projects-endpoint.md) — project member roles
- [Audit Endpoint](audit-endpoint.md) — permission change audit trail

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: permission inheritance model, deny rules, or bulk update behavior changes -->
