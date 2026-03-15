# Pagination

Nimbus uses cursor-based pagination for all list endpoints. This approach provides stable pagination even when records are added or removed between requests.

## Cursor-Based Pagination

List endpoints accept `after` and `before` cursor parameters. Cursors are opaque base64-encoded strings that reference a specific position in the result set.

```
GET /v1/projects?first=20&after=eyJpZCI6InByb2pfMDUwIn0=
```

The response includes pagination metadata:

```json
{
  "data": [...],
  "meta": {
    "pagination": {
      "has_next_page": true,
      "has_previous_page": true,
      "start_cursor": "eyJpZCI6InByb2pfMDUxIn0=",
      "end_cursor": "eyJpZCI6InByb2pfMDcwIn0=",
      "total_count": 342
    }
  }
}
```

## Page Size Limits

The `first` parameter controls page size. Defaults and limits vary by resource:

| Resource | Default | Maximum |
|----------|---------|---------|
| Projects | 20 | 100 |
| Tasks | 50 | 200 |
| Comments | 25 | 100 |
| Audit Events | 50 | 500 |
| Search Results | 20 | 50 |

Requesting a page size above the maximum silently clamps to the maximum.

## Sort Parameters

Pagination respects the `sort` parameter. When sorting is applied, cursors encode both the sort field value and the record ID for stable ordering. Changing the sort parameter invalidates existing cursors.

```
GET /v1/tasks?first=50&sort=-created_at&after=eyJjcmVhdGVkX2F0Ijoi...
```

## Total Count Header

For performance, `total_count` is included by default on small result sets (under 10,000 records). For larger sets, request it explicitly with `include_total=true`. This adds a count query which may be slow on very large collections.

The total count is also available via the `X-Total-Count` response header.

## Backward Pagination

Use `last` and `before` to paginate backward from the end of a result set:

```
GET /v1/tasks?last=20&before=eyJpZCI6InRhc2tfMTAwIn0=
```

Do not combine `first`/`after` with `last`/`before` in the same request.

## See Also

- [REST Overview](rest-overview.md) — response envelope format
- [Filtering](filtering.md) — filter parameters work with pagination
- [Sorting](sorting.md) — sort parameter details
- [Search Endpoint](search-endpoint.md) — search-specific pagination

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: pagination defaults, max page sizes, or cursor format changes -->
