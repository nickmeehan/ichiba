# Search Endpoint

The Search API provides full-text search across all workspace content including tasks, comments, projects, and attachments. It supports faceted search, suggestions, and saved searches.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/search` | Execute a search query |
| GET | `/v1/search/suggest` | Get search suggestions |
| GET | `/v1/search/saved` | List saved searches |
| POST | `/v1/search/saved` | Save a search |
| DELETE | `/v1/search/saved/{id}` | Delete a saved search |

## Full-Text Search

```json
POST /v1/search
{
  "query": "authentication login bug",
  "types": ["task", "comment"],
  "project_ids": ["proj_01"],
  "page_size": 20
}
```

Response:

```json
{
  "data": {
    "results": [
      {
        "type": "task",
        "id": "task_42",
        "title": "Fix authentication bug on login page",
        "snippet": "Users report intermittent <em>login</em> failures when using <em>authentication</em>...",
        "score": 0.95,
        "project": { "id": "proj_01", "name": "Web App" }
      }
    ],
    "total_count": 15,
    "facets": { ... }
  }
}
```

Search results include highlighted snippets with `<em>` tags around matching terms.

## Faceted Search

Facets provide aggregated counts for filtering:

```json
{
  "data": {
    "facets": {
      "type": [
        { "value": "task", "count": 12 },
        { "value": "comment", "count": 3 }
      ],
      "status": [
        { "value": "open", "count": 5 },
        { "value": "in_progress", "count": 7 }
      ],
      "assignee": [
        { "value": "user_05", "display": "Jane Chen", "count": 8 }
      ]
    }
  }
}
```

## Search Suggestions

Typeahead suggestions for search input:

```
GET /v1/search/suggest?q=auth&types=task
```

Returns up to 10 suggestions with titles and resource types.

## Searchable Content

| Resource | Indexed Fields |
|----------|---------------|
| Tasks | name, description, custom field values |
| Comments | body text |
| Projects | name, description |
| Attachments | filename, description |
| Labels | name |

## Saved Searches

Save frequently used queries:

```json
POST /v1/search/saved
{
  "name": "My Open Bugs",
  "query": "bug",
  "filters": { "types": ["task"], "status": "open", "assignee_id": "user_05" }
}
```

Saved searches appear in the search UI and can be shared with the team.

## Search Operators

| Operator | Example | Description |
|----------|---------|-------------|
| `""` | `"exact phrase"` | Exact phrase match |
| `OR` | `bug OR defect` | Match either term |
| `-` | `login -password` | Exclude term |
| `type:` | `type:comment` | Filter by resource type |
| `project:` | `project:proj_01` | Filter by project |

## See Also

- [Filtering](filtering.md) — structured query filtering
- [Tasks Endpoint](tasks-endpoint.md) — task data in search results
- [Pagination](pagination.md) — paginating search results
- [Custom Fields Endpoint](custom-fields-endpoint.md) — searchable custom fields

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: indexed fields, search operators, or facet behavior changes -->
