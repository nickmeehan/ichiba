# Projects Endpoint

The Projects API manages project lifecycle including creation, configuration, membership, and archival. Projects are the top-level organizational unit in Nimbus.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/projects` | List projects in the workspace |
| POST | `/v1/projects` | Create a new project |
| GET | `/v1/projects/{id}` | Get project details |
| PATCH | `/v1/projects/{id}` | Update project settings |
| DELETE | `/v1/projects/{id}` | Archive a project (soft delete) |
| POST | `/v1/projects/{id}/restore` | Restore an archived project |
| GET | `/v1/projects/{id}/members` | List project members |
| POST | `/v1/projects/{id}/members` | Add a member to the project |
| DELETE | `/v1/projects/{id}/members/{user_id}` | Remove a member |

## Creating a Project

```json
POST /v1/projects
{
  "name": "Q2 Marketing Campaign",
  "description": "All tasks related to the Q2 campaign launch",
  "visibility": "private",
  "template_id": "tmpl_marketing_standard",
  "default_assignee_id": "user_05"
}
```

The `template_id` field is optional. When provided, the project is initialized with predefined tasks, labels, and board configuration from the template.

## Project Templates

Projects can be created from templates to standardize structure:

```json
POST /v1/projects
{
  "name": "Client Onboarding - Acme Corp",
  "template_id": "tmpl_onboarding",
  "template_variables": {
    "client_name": "Acme Corp",
    "account_manager": "user_12"
  }
}
```

Template variables are substituted into task names, descriptions, and assignee fields.

## Archive and Restore

Deleting a project archives it rather than permanently removing it. Archived projects are hidden from default list views but retain all data. Archived projects can be restored within 90 days. After 90 days, archived projects are permanently deleted.

```
DELETE /v1/projects/proj_42        # Archive
POST /v1/projects/proj_42/restore  # Restore
```

## Project Settings

Each project has configurable settings:

```json
PATCH /v1/projects/proj_42
{
  "settings": {
    "default_task_status": "open",
    "require_due_dates": true,
    "auto_close_stale_tasks_days": 30,
    "time_tracking_enabled": true
  }
}
```

## Member Management

Project members inherit workspace roles but can have project-specific role overrides:

```json
POST /v1/projects/proj_42/members
{
  "user_id": "user_15",
  "role": "project_admin"
}
```

## See Also

- [Tasks Endpoint](tasks-endpoint.md) — tasks within projects
- [Templates Endpoint](templates-endpoint.md) — project templates
- [Teams Endpoint](teams-endpoint.md) — team-based project access
- [Boards Endpoint](boards-endpoint.md) — project board views
- [Permissions Endpoint](permissions-endpoint.md) — project-level permissions

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: project CRUD behavior, archive policy, or member management changes -->
