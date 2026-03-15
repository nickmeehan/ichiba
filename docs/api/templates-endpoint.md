# Templates Endpoint

The Templates API manages reusable project and task templates. Templates standardize project setup and can include predefined tasks, labels, boards, and custom field configurations.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/templates` | List templates in the workspace |
| POST | `/v1/templates` | Create a template |
| GET | `/v1/templates/{id}` | Get template details |
| PATCH | `/v1/templates/{id}` | Update a template |
| DELETE | `/v1/templates/{id}` | Delete a template |
| POST | `/v1/templates/{id}/apply` | Apply a template to create a project |
| GET | `/v1/templates/marketplace` | Browse shared templates |
| POST | `/v1/templates/{id}/publish` | Publish to marketplace |

## Creating a Template

```json
POST /v1/templates
{
  "name": "Client Onboarding",
  "description": "Standard onboarding process for new clients",
  "type": "project",
  "content": {
    "tasks": [
      { "name": "Kickoff meeting with {{client_name}}", "assignee_variable": "account_manager" },
      { "name": "Configure workspace", "relative_due_days": 3 },
      { "name": "Initial data import", "relative_due_days": 5 },
      { "name": "Training session", "relative_due_days": 10 }
    ],
    "labels": ["Onboarding", "Client"],
    "board_columns": ["To Do", "In Progress", "Waiting on Client", "Done"]
  }
}
```

## Template Variables

Templates support variables that are filled in when the template is applied:

```json
{
  "variables": [
    { "key": "client_name", "type": "string", "required": true, "label": "Client Name" },
    { "key": "account_manager", "type": "user", "required": true, "label": "Account Manager" },
    { "key": "start_date", "type": "date", "required": false, "label": "Start Date", "default": "today" }
  ]
}
```

## Applying a Template

```json
POST /v1/templates/tmpl_onboarding/apply
{
  "project_name": "Onboarding - Acme Corp",
  "variables": {
    "client_name": "Acme Corp",
    "account_manager": "user_05",
    "start_date": "2026-04-01"
  }
}
```

Due dates are calculated relative to the `start_date`. Task names and descriptions have variables substituted.

## Task Templates

Standalone task templates create individual tasks (not full projects):

```json
POST /v1/templates
{
  "name": "Bug Report Template",
  "type": "task",
  "content": {
    "description": "## Steps to Reproduce\n\n## Expected Behavior\n\n## Actual Behavior\n\n## Screenshots",
    "labels": ["Bug"],
    "priority": 3
  }
}
```

## Template Marketplace

Publish templates for other workspaces to use:

```json
POST /v1/templates/tmpl_onboarding/publish
{
  "visibility": "public",
  "category": "client_management",
  "tags": ["onboarding", "client", "professional_services"]
}
```

Browse community templates:

```
GET /v1/templates/marketplace?category=engineering&sort=-installs
```

## See Also

- [Projects Endpoint](projects-endpoint.md) — creating projects from templates
- [Tasks Endpoint](tasks-endpoint.md) — task template application
- [Custom Fields Endpoint](custom-fields-endpoint.md) — custom fields in templates
- [Automations Endpoint](automations-endpoint.md) — automation templates

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: template variable types, marketplace publishing, or application behavior changes -->
