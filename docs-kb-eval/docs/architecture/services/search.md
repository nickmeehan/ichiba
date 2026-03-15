# Search Service

The search service provides full-text search across tasks, comments, documents, and other entities in Nimbus. It is backed by Elasticsearch and supports faceted filtering, relevance tuning, and workspace-scoped results.

## Elasticsearch Index Design

Each searchable entity type has its own Elasticsearch index:

| Index              | Source Entities        | Key Fields                              |
|-------------------|------------------------|-----------------------------------------|
| `nimbus-tasks`    | Tasks, subtasks        | title, description, custom field values |
| `nimbus-comments` | Comments               | body, author name, task reference       |
| `nimbus-docs`     | Wiki pages, documents  | title, content (markdown stripped)       |

All indexes include a `tenant_id` field, and every search query is automatically filtered by the current tenant to maintain isolation.

## Indexing Pipeline

When a searchable entity is created or updated, the corresponding domain event triggers an indexing job:

1. The search event handler receives the event (e.g., `task.created`).
2. It fetches the full entity data from PostgreSQL, including related data needed for search (assignee name, project name).
3. It upserts the document into the appropriate Elasticsearch index.

Indexing runs asynchronously via BullMQ with a dedicated `search-indexer` queue. This ensures that indexing delays do not affect API response times.

## Search API

The search endpoint accepts a query string and optional filters:

```
GET /api/search?q=login+bug&type=task&project=proj_abc&status=open
```

The query is executed as a multi-match query across the relevant fields with field boosting (title is weighted 3x over description). Results include highlighting of matched terms.

## Faceted Search

Search responses include facet counts for common filter dimensions:

- **Type**: task, comment, document
- **Project**: grouped by project
- **Status**: open, in progress, done
- **Assignee**: grouped by user

Facets are computed using Elasticsearch aggregations and returned alongside the search results.

## Reindexing Strategy

A full reindex is required when the index mapping changes (e.g., a new field is added). The reindexing process:

1. Create a new index with the updated mapping and a timestamped alias.
2. Bulk-index all documents from PostgreSQL into the new index.
3. Swap the index alias atomically to point to the new index.
4. Delete the old index after verifying the swap.

This zero-downtime approach ensures search remains available during reindexing.

## See Also

- [Event-Driven Architecture](../event-driven.md) - Event-triggered indexing
- [Scheduler](./scheduler.md) - Reindex job scheduling
- [Database Queries](../database/queries.md) - Source data for search indexing

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Elasticsearch version upgrades or new entity types become searchable -->
