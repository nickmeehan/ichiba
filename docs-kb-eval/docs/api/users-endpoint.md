# Users Endpoint

The Users API manages user profiles, avatar uploads, preference settings, and workspace membership. User accounts exist at the platform level and can belong to multiple workspaces.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/users/me` | Get the authenticated user's profile |
| PATCH | `/v1/users/me` | Update the authenticated user's profile |
| GET | `/v1/users` | List users in the workspace |
| GET | `/v1/users/{id}` | Get a user's profile |
| POST | `/v1/users/me/avatar` | Upload an avatar image |
| DELETE | `/v1/users/me/avatar` | Remove the avatar |
| GET | `/v1/users/{id}/workspaces` | List workspaces the user belongs to |

## User Profile

The user profile includes display information and workspace-level settings:

```json
{
  "data": {
    "id": "user_05",
    "email": "jane@example.com",
    "display_name": "Jane Chen",
    "avatar_url": "https://cdn.nimbus.io/avatars/user_05.jpg",
    "timezone": "America/Los_Angeles",
    "locale": "en-US",
    "role": "member",
    "status": "active",
    "last_active_at": "2026-03-15T09:45:00Z"
  }
}
```

## Updating Profile

```json
PATCH /v1/users/me
{
  "display_name": "Jane Chen-Park",
  "timezone": "America/New_York",
  "locale": "en-US"
}
```

Only the authenticated user can update their own profile. Workspace admins can update other users' roles via the admin endpoint.

## Avatar Upload

Avatars are uploaded as multipart form data:

```
POST /v1/users/me/avatar
Content-Type: multipart/form-data

file=@headshot.jpg
```

Accepted formats: JPEG, PNG, WebP. Maximum size: 5 MB. Images are automatically resized to 256x256 pixels and served via CDN.

## Workspace Membership

Users can belong to multiple workspaces. The membership object includes the user's role and join date within each workspace:

```json
{
  "data": [
    {
      "workspace_id": "ws_01",
      "workspace_name": "Acme Corp",
      "role": "admin",
      "joined_at": "2025-06-01T00:00:00Z"
    }
  ]
}
```

## User Search

List users with filtering by name, email, role, or status:

```
GET /v1/users?filter[role]=admin&filter[status]=active&filter[display_name.contains]=chen
```

## Deactivation

Deactivated users cannot log in but their data (tasks, comments) is preserved. Only workspace admins can deactivate users via the admin endpoint.

## See Also

- [Teams Endpoint](teams-endpoint.md) — team membership
- [Roles Endpoint](roles-endpoint.md) — user roles and permissions
- [Preferences Endpoint](preferences-endpoint.md) — user preference settings
- [Admin Endpoint](admin-endpoint.md) — user administration
- [Authentication](authentication.md) — user auth flows

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: profile fields, avatar handling, or workspace membership behavior changes -->
