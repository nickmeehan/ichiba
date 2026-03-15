# Imports Endpoint

The Imports API handles bulk data import from CSV and JSON files into Nimbus. Imports support field mapping, validation, and progress tracking for migrating data from other tools.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/imports` | Start a new import |
| GET | `/v1/imports/{id}` | Get import status |
| GET | `/v1/imports/{id}/errors` | List import errors |
| POST | `/v1/imports/{id}/cancel` | Cancel a running import |
| GET | `/v1/imports/mappings` | Get suggested field mappings |
| POST | `/v1/imports/preview` | Preview import results |

## Starting an Import

Upload a file and configure the import:

```json
POST /v1/imports
Content-Type: multipart/form-data

file=@tasks-export.csv
resource_type=task
project_id=proj_01
mapping={"Name": "name", "Status": "status", "Assigned To": "assignee_email", "Due": "due_date"}
```

## CSV Import

CSV files must include a header row. Nimbus auto-detects common column names and suggests mappings:

```csv
Name,Status,Priority,Assigned To,Due Date
Design homepage,In Progress,High,jane@example.com,2026-04-01
Write API docs,Open,Medium,tom@example.com,2026-04-15
```

## JSON Import

JSON imports accept an array of objects:

```json
{
  "resource_type": "task",
  "project_id": "proj_01",
  "data": [
    { "name": "Design homepage", "status": "in_progress", "priority": 3 },
    { "name": "Write API docs", "status": "open", "priority": 2 }
  ]
}
```

## Field Mapping

Map source columns to Nimbus fields:

```json
{
  "mapping": {
    "Name": "name",
    "Status": { "field": "status", "transform": { "In Progress": "in_progress", "Done": "done" } },
    "Points": "cf_story_points",
    "Assigned To": { "field": "assignee_id", "lookup_by": "email" }
  }
}
```

The `transform` option maps source values to Nimbus enum values. The `lookup_by` option resolves user references by email or display name.

## Validation

Before processing, Nimbus validates all records. Preview validation results:

```json
POST /v1/imports/preview
```

Returns a sample of validated records with any warnings or errors.

## Import Status

```json
{
  "data": {
    "id": "import_001",
    "status": "processing",
    "total_records": 500,
    "processed_records": 342,
    "successful_records": 335,
    "failed_records": 7,
    "progress_percentage": 68
  }
}
```

Statuses: `validating`, `processing`, `completed`, `failed`, `cancelled`.

## Error Handling

Retrieve errors for failed records:

```
GET /v1/imports/import_001/errors
```

```json
{
  "data": [
    { "row": 45, "field": "due_date", "value": "next Friday", "error": "Invalid date format" },
    { "row": 102, "field": "assignee_email", "value": "unknown@example.com", "error": "User not found" }
  ]
}
```

Failed records are skipped; successful records are committed. There is no rollback for partial imports.

## See Also

- [Exports Endpoint](exports-endpoint.md) — exporting data from Nimbus
- [Batch Operations](batch-operations.md) — programmatic bulk operations
- [Tasks Endpoint](tasks-endpoint.md) — task data model
- [Custom Fields Endpoint](custom-fields-endpoint.md) — mapping to custom fields

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: supported formats, field mapping options, or validation behavior changes -->
