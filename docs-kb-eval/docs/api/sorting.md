# Sort Parameters

Nimbus list endpoints support flexible sorting via the `sort` query parameter. Sorting can be applied to multiple fields and combined with filtering and pagination.

## Basic Sorting

Pass one or more field names in the `sort` parameter. Prefix with `-` for descending order:

```
GET /v1/tasks?sort=-priority,created_at
```

This sorts by priority descending, then by creation date ascending as a tiebreaker.

## Multi-Field Sorting

Up to 3 sort fields can be specified in a single request. Fields are applied in order of precedence (left to right):

```
GET /v1/tasks?sort=-status,priority,-updated_at
```

Exceeding 3 sort fields returns a `SORT_FIELDS_EXCEEDED` error.

## Sort Direction

| Prefix | Direction |
|--------|-----------|
| (none) | Ascending (A-Z, 0-9, oldest first) |
| `-` | Descending (Z-A, 9-0, newest first) |

## Default Sort Orders

Each resource has a default sort order used when no `sort` parameter is specified:

| Resource | Default Sort |
|----------|-------------|
| Projects | `name` (ascending) |
| Tasks | `-priority, created_at` |
| Comments | `created_at` (ascending) |
| Sprints | `-start_date` |
| Audit Events | `-timestamp` |
| Notifications | `-created_at` |

## Null Handling

Null values in sort fields are sorted last in ascending order and first in descending order. This behavior can be overridden per-request:

```
GET /v1/tasks?sort=-due_date&null_position=last
```

Valid `null_position` values are `first` and `last`.

## Sortable Fields

Not all fields are sortable. Attempting to sort by a non-sortable field returns a `FIELD_NOT_SORTABLE` error. Sortable fields are documented on each resource endpoint page and can be discovered via the OpenAPI spec.

Custom fields marked as `sortable: true` in their definition can also be used:

```
GET /v1/tasks?sort=cf_department,-cf_effort_estimate
```

## Sort Stability

Nimbus guarantees stable sort ordering. When multiple records share the same sort key values, the `id` field is used as a final tiebreaker to ensure consistent pagination.

## See Also

- [Pagination](pagination.md) — sorting affects cursor-based pagination
- [Filtering](filtering.md) — combine sorting with filters
- [Custom Fields Endpoint](custom-fields-endpoint.md) — sortable custom fields
- [REST Overview](rest-overview.md) — general query parameter conventions

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: default sort orders, max sort fields, or null handling behavior changes -->
