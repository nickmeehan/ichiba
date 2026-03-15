# Custom Fields Endpoint

The Custom Fields API manages user-defined fields that extend the standard task and project data model. Custom fields are defined at the workspace level and can be applied to specific projects.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/custom-fields` | List custom field definitions |
| POST | `/v1/custom-fields` | Create a custom field |
| GET | `/v1/custom-fields/{id}` | Get field details |
| PATCH | `/v1/custom-fields/{id}` | Update a field definition |
| DELETE | `/v1/custom-fields/{id}` | Delete a custom field |
| GET | `/v1/custom-fields/{id}/options` | List options for select/multi-select fields |

## Field Types

| Type | Description | Example |
|------|-------------|---------|
| `text` | Single-line text | Department name |
| `textarea` | Multi-line text | Additional notes |
| `number` | Integer or decimal | Story points, effort estimate |
| `select` | Single choice from options | Component (Frontend, Backend, Mobile) |
| `multi_select` | Multiple choices | Affected platforms |
| `date` | Date value | Target release date |
| `checkbox` | Boolean true/false | Requires QA review |
| `url` | URL with validation | Design file link |
| `user` | User reference | Technical reviewer |
| `currency` | Monetary value with currency | Budget estimate |

## Creating a Custom Field

```json
POST /v1/custom-fields
{
  "name": "Story Points",
  "key": "cf_story_points",
  "type": "number",
  "description": "Effort estimate in story points",
  "required": false,
  "filterable": true,
  "sortable": true,
  "validation": {
    "min": 0,
    "max": 100
  },
  "applies_to": ["task"],
  "project_ids": ["proj_01", "proj_02"]
}
```

## Field Validation

Each field type supports type-specific validation rules:

- **text**: `min_length`, `max_length`, `pattern` (regex)
- **number**: `min`, `max`, `decimal_places`
- **select**: `options` array with allowed values
- **date**: `min_date`, `max_date`, `relative_to` (another date field)
- **url**: `allowed_domains`

## Workspace-Level Fields

Fields can be scoped to specific projects or made available workspace-wide:

```json
PATCH /v1/custom-fields/cf_story_points
{
  "scope": "workspace",
  "project_ids": null
}
```

Workspace-level fields appear on all tasks across all projects.

## Setting Custom Field Values

Custom field values are set on tasks via the Tasks API:

```json
PATCH /v1/tasks/task_42
{
  "custom_fields": {
    "cf_story_points": 5,
    "cf_component": "backend",
    "cf_needs_qa": true
  }
}
```

## Select Field Options

Manage options for select and multi-select fields:

```json
POST /v1/custom-fields/cf_component/options
{
  "value": "mobile",
  "color": "#9b59b6",
  "position": 3
}
```

## See Also

- [Tasks Endpoint](tasks-endpoint.md) — setting custom field values
- [Filtering](filtering.md) — filtering by custom fields
- [Sorting](sorting.md) — sorting by custom fields
- [Templates Endpoint](templates-endpoint.md) — custom fields in templates
- [Search Endpoint](search-endpoint.md) — searching custom field values

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: field types, validation rules, or scoping behavior changes -->
