# Exports Endpoint

The Exports API generates downloadable data exports from Nimbus in multiple formats. Exports run asynchronously and support scheduling for recurring delivery.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/exports` | Create an export job |
| GET | `/v1/exports/{id}` | Get export status and download link |
| GET | `/v1/exports` | List export history |
| DELETE | `/v1/exports/{id}` | Delete an export file |
| POST | `/v1/exports/{id}/schedule` | Schedule recurring export |
| DELETE | `/v1/exports/schedules/{id}` | Cancel a scheduled export |

## Creating an Export

```json
POST /v1/exports
{
  "resource_type": "task",
  "filters": {
    "project_id": "proj_01",
    "status.neq": "archived"
  },
  "fields": ["name", "status", "priority", "assignee.display_name", "due_date", "cf_story_points"],
  "format": "csv",
  "include_subtasks": true
}
```

## Export Formats

| Format | Extension | Description |
|--------|-----------|-------------|
| `csv` | `.csv` | Comma-separated values, UTF-8 with BOM |
| `json` | `.json` | JSON array of objects |
| `xlsx` | `.xlsx` | Excel spreadsheet with formatting |
| `pdf` | `.pdf` | Formatted report (reports only) |

## Async Processing

Exports run asynchronously. The initial response returns a job ID:

```json
{
  "data": {
    "id": "export_001",
    "status": "processing",
    "estimated_completion": "2026-03-15T10:32:00Z"
  }
}
```

Poll for completion or subscribe via WebSocket:

```
GET /v1/exports/export_001
```

```json
{
  "data": {
    "id": "export_001",
    "status": "completed",
    "download_url": "https://cdn.nimbus.io/exports/export_001.csv?token=...",
    "file_size": 524288,
    "record_count": 1500,
    "expires_at": "2026-03-22T10:30:00Z"
  }
}
```

## Download Links

Download URLs are signed and valid for 7 days. After expiration, the export must be regenerated.

## Scheduled Exports

Set up recurring exports with email delivery:

```json
POST /v1/exports/export_001/schedule
{
  "frequency": "weekly",
  "day": "friday",
  "time": "17:00",
  "timezone": "America/New_York",
  "recipients": ["user_05", "manager@example.com"],
  "format": "xlsx"
}
```

## Export Limits

| Plan | Max Records | Concurrent Exports |
|------|------------|-------------------|
| Free | 1,000 | 1 |
| Pro | 50,000 | 3 |
| Enterprise | Unlimited | 10 |

Exports exceeding the record limit return an `EXPORT_LIMIT_EXCEEDED` error.

## See Also

- [Imports Endpoint](imports-endpoint.md) — importing data into Nimbus
- [Content Negotiation](content-negotiation.md) — inline format selection
- [Reports Endpoint](reports-endpoint.md) — report exports
- [Audit Endpoint](audit-endpoint.md) — audit log exports

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: export formats, size limits, or scheduling options change -->
