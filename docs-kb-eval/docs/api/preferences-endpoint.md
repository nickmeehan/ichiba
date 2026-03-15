# Preferences Endpoint

The Preferences API manages user-level and workspace-level settings including UI customization, notification channels, locale configuration, and default behaviors.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/preferences/user` | Get user preferences |
| PATCH | `/v1/preferences/user` | Update user preferences |
| GET | `/v1/preferences/workspace` | Get workspace preferences |
| PATCH | `/v1/preferences/workspace` | Update workspace preferences (admin only) |
| POST | `/v1/preferences/user/reset` | Reset user preferences to defaults |

## User Preferences

```json
{
  "data": {
    "theme": "dark",
    "language": "en-US",
    "timezone": "America/Los_Angeles",
    "date_format": "YYYY-MM-DD",
    "time_format": "24h",
    "first_day_of_week": "monday",
    "default_project_view": "board",
    "task_density": "comfortable",
    "sidebar_collapsed": false,
    "keyboard_shortcuts_enabled": true
  }
}
```

## Updating User Preferences

```json
PATCH /v1/preferences/user
{
  "theme": "light",
  "timezone": "Europe/London",
  "date_format": "DD/MM/YYYY"
}
```

Partial updates are supported — only include the fields you want to change.

## Workspace Preferences

Workspace-level settings affect all users and are managed by admins:

```json
{
  "data": {
    "default_task_statuses": ["open", "in_progress", "in_review", "done"],
    "require_task_due_dates": false,
    "default_sprint_length_weeks": 2,
    "time_tracking_enabled": true,
    "time_rounding": "15min",
    "default_billable": true,
    "file_upload_max_mb": 100,
    "allowed_file_types": ["image/*", "application/pdf", "text/*"],
    "workspace_locale": "en-US",
    "fiscal_year_start_month": 1
  }
}
```

## Notification Settings

Notification preferences are managed via the Notifications endpoint but also accessible here for convenience:

```json
PATCH /v1/preferences/user
{
  "notifications": {
    "email_digest": "daily",
    "quiet_hours": { "start": "22:00", "end": "08:00", "timezone": "America/Los_Angeles" },
    "desktop_notifications": true
  }
}
```

## UI Customization

Users can customize their workspace appearance:

| Setting | Options |
|---------|---------|
| `theme` | `light`, `dark`, `system` |
| `task_density` | `compact`, `comfortable`, `spacious` |
| `default_project_view` | `board`, `list`, `timeline`, `calendar` |
| `sidebar_items` | Array of visible sidebar sections |

## Reset to Defaults

Reset all user preferences to workspace defaults:

```
POST /v1/preferences/user/reset
```

Individual sections can be reset:

```json
POST /v1/preferences/user/reset
{
  "sections": ["theme", "notifications"]
}
```

## See Also

- [Notifications Endpoint](notifications-endpoint.md) — detailed notification preferences
- [Users Endpoint](users-endpoint.md) — user profile settings
- [Admin Endpoint](admin-endpoint.md) — workspace administration
- [Projects Endpoint](projects-endpoint.md) — project-level settings

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: preference options, workspace defaults, or UI customization settings change -->
