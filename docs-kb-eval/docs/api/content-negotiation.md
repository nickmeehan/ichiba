# Content Negotiation

Nimbus supports multiple response formats via content negotiation. Clients can request JSON, CSV, or XML responses using the `Accept` header.

## Supported Content Types

| Accept Header | Format | Availability |
|--------------|--------|-------------|
| `application/json` | JSON (default) | All endpoints |
| `text/csv` | CSV | List endpoints only |
| `application/xml` | XML | All endpoints |
| `application/pdf` | PDF | Report and invoice endpoints only |

## Accept Header Handling

Set the `Accept` header to request a specific format:

```
GET /v1/tasks?filter[project_id]=proj_01
Accept: text/csv
```

If no `Accept` header is provided, the default is `application/json`. If an unsupported format is requested, the API returns `406 Not Acceptable`.

## JSON Responses

JSON is the primary response format. All API documentation examples use JSON. Responses follow the standard envelope format described in the REST Overview.

## CSV Responses

CSV responses flatten nested objects and return headers based on field names:

```csv
id,name,status,priority,project_id,assignee_id,created_at
task_01,Design mockups,in_progress,3,proj_01,user_05,2026-03-10T09:00:00Z
task_02,Write tests,open,2,proj_01,user_03,2026-03-11T14:00:00Z
```

Nested objects use dot notation for column headers (e.g., `assignee.name`). CSV responses do not include pagination metadata — use the `Link` header for next/previous page URLs.

## XML Responses

XML responses mirror the JSON structure:

```xml
<response>
  <data>
    <task>
      <id>task_01</id>
      <name>Design mockups</name>
      <status>in_progress</status>
    </task>
  </data>
  <meta>
    <request_id>req_abc123</request_id>
  </meta>
</response>
```

## Content Type Detection

For file upload responses, the `Content-Type` is determined by the file's detected MIME type, regardless of the `Accept` header.

## Quality Values

Multiple formats can be specified with quality values:

```
Accept: application/json;q=1.0, text/csv;q=0.8
```

Nimbus selects the highest-quality supported format.

## Charset

All text responses use UTF-8 encoding. The `charset=utf-8` parameter is included in response `Content-Type` headers.

## See Also

- [REST Overview](rest-overview.md) — response envelope format
- [Exports Endpoint](exports-endpoint.md) — async data export in multiple formats
- [Reports Endpoint](reports-endpoint.md) — report format options
- [Invoices Endpoint](invoices-endpoint.md) — PDF invoice generation

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: supported content types, CSV format rules, or quality value handling changes -->
