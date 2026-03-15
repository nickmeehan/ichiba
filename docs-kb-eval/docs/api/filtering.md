# Query Filtering

Nimbus list endpoints support a flexible filtering syntax that lets clients narrow results by field values, operators, and nested relationships.

## Filter Syntax

Filters are passed as query parameters using bracket notation:

```
GET /v1/tasks?filter[status]=in_progress&filter[priority]=high
```

Multiple filters are combined with AND logic by default. Use the `filter_logic` parameter for OR:

```
GET /v1/tasks?filter[status]=in_progress&filter[priority]=high&filter_logic=or
```

## Supported Operators

Operators are appended to the field name with a dot separator:

| Operator | Example | Description |
|----------|---------|-------------|
| `eq` | `filter[status.eq]=done` | Equals (default) |
| `neq` | `filter[status.neq]=done` | Not equals |
| `gt` | `filter[priority.gt]=3` | Greater than |
| `gte` | `filter[priority.gte]=3` | Greater than or equal |
| `lt` | `filter[due_date.lt]=2026-04-01` | Less than |
| `lte` | `filter[due_date.lte]=2026-04-01` | Less than or equal |
| `in` | `filter[status.in]=open,in_progress` | In list |
| `nin` | `filter[status.nin]=done,archived` | Not in list |
| `contains` | `filter[name.contains]=launch` | Substring match |
| `starts_with` | `filter[name.starts_with]=Q1` | Prefix match |
| `is_null` | `filter[assignee.is_null]=true` | Null check |

## Nested Field Filtering

Filter on nested relationships using dot notation for the field path:

```
GET /v1/tasks?filter[project.name.contains]=marketing&filter[assignee.team.id]=team_05
```

Nested filters perform joins internally. Deep nesting (more than 3 levels) is not supported and returns a `FILTER_DEPTH_EXCEEDED` error.

## Date Range Filters

Date fields support ISO 8601 values with optional time components:

```
GET /v1/tasks?filter[created_at.gte]=2026-01-01T00:00:00Z&filter[created_at.lt]=2026-04-01T00:00:00Z
```

Relative date shortcuts are also available: `today`, `this_week`, `this_month`, `last_7_days`, `last_30_days`.

## Custom Field Filtering

Custom fields are filterable via the `cf_` prefix:

```
GET /v1/tasks?filter[cf_department]=engineering
```

Only custom fields marked as `filterable: true` in their definition support filtering.

## See Also

- [Pagination](pagination.md) — filters work with paginated results
- [Sorting](sorting.md) — combine filters with sort parameters
- [Search Endpoint](search-endpoint.md) — full-text search alternative
- [Custom Fields Endpoint](custom-fields-endpoint.md) — custom field definitions

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: filter operators, nested depth limits, or custom field filter behavior changes -->
