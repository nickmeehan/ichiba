# Admin Endpoint

The Admin API provides workspace management, user administration, system settings, and feature toggles. Admin endpoints require the `admin:write` scope or workspace owner role.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/admin/workspace` | Get workspace details |
| PATCH | `/v1/admin/workspace` | Update workspace settings |
| GET | `/v1/admin/users` | List all workspace users |
| POST | `/v1/admin/users/invite` | Invite a user to the workspace |
| POST | `/v1/admin/users/{id}/deactivate` | Deactivate a user |
| POST | `/v1/admin/users/{id}/reactivate` | Reactivate a user |
| PATCH | `/v1/admin/users/{id}/role` | Change a user's role |
| GET | `/v1/admin/settings` | Get system settings |
| PATCH | `/v1/admin/settings` | Update system settings |
| GET | `/v1/admin/features` | List feature toggles |
| PATCH | `/v1/admin/features` | Toggle features |

## Workspace Management

```json
PATCH /v1/admin/workspace
{
  "name": "Acme Corp Engineering",
  "slug": "acme-eng",
  "logo_url": "https://cdn.nimbus.io/logos/acme.png",
  "default_timezone": "America/New_York"
}
```

## User Administration

Invite new users:

```json
POST /v1/admin/users/invite
{
  "email": "newuser@example.com",
  "role": "member",
  "teams": ["team_03"],
  "projects": ["proj_01"],
  "message": "Welcome to the team!"
}
```

Invitations expire after 7 days. Pending invitations can be resent or revoked.

### Deactivation

Deactivated users lose access immediately. Their tasks and data are preserved and can be reassigned:

```
POST /v1/admin/users/user_12/deactivate
```

Deactivation frees a seat on the subscription.

### Role Changes

```json
PATCH /v1/admin/users/user_12/role
{
  "role_id": "role_pm"
}
```

## System Settings

Configure workspace-wide behavior:

```json
PATCH /v1/admin/settings
{
  "sso_enabled": true,
  "sso_provider": "okta",
  "sso_config": { "domain": "acme.okta.com", "client_id": "..." },
  "ip_allowlist": ["203.0.113.0/24", "198.51.100.0/24"],
  "session_timeout_hours": 12,
  "password_policy": {
    "min_length": 12,
    "require_uppercase": true,
    "require_special": true,
    "max_age_days": 90
  }
}
```

## Feature Toggles

Enable or disable workspace features:

```json
PATCH /v1/admin/features
{
  "time_tracking": true,
  "custom_fields": true,
  "automations": true,
  "graphql_api": false,
  "advanced_reports": true,
  "public_api_access": true
}
```

Feature availability depends on the subscription plan. Attempting to enable a feature not included in the current plan returns a `FEATURE_NOT_AVAILABLE` error.

## Usage Dashboard

View workspace usage statistics:

```
GET /v1/admin/usage
```

Returns seat count, storage usage, API call volume, and resource counts for capacity planning and billing forecasting.

## Danger Zone

Irreversible operations require confirmation:

```json
POST /v1/admin/workspace/delete
{
  "confirmation": "DELETE acme-eng"
}
```

Workspace deletion is permanent and removes all data after a 30-day grace period.

## See Also

- [Users Endpoint](users-endpoint.md) — user profile management
- [Roles Endpoint](roles-endpoint.md) — role definitions
- [Billing Endpoint](billing-endpoint.md) — subscription management
- [Audit Endpoint](audit-endpoint.md) — admin action audit trail
- [Subscriptions Endpoint](subscriptions-endpoint.md) — plan features

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: SSO config, IP allowlist, feature toggles, or workspace deletion policy changes -->
