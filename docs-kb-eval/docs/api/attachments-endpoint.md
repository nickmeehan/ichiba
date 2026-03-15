# Attachments Endpoint

The Attachments API manages file associations with tasks, comments, and other resources. Attachments link uploaded files to specific resources and provide metadata and download access.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/tasks/{task_id}/attachments` | List attachments on a task |
| POST | `/v1/tasks/{task_id}/attachments` | Attach a file to a task |
| GET | `/v1/attachments/{id}` | Get attachment metadata |
| DELETE | `/v1/attachments/{id}` | Remove an attachment |
| GET | `/v1/attachments/{id}/download` | Get a download URL |
| GET | `/v1/attachments/{id}/preview` | Get a preview/thumbnail URL |

## Attaching a File

First upload the file via the File Uploads API, then attach it to a resource:

```json
POST /v1/tasks/task_42/attachments
{
  "file_id": "file_abc123",
  "description": "Final mockup for homepage redesign"
}
```

## Attachment Metadata

```json
{
  "data": {
    "id": "attach_001",
    "file_id": "file_abc123",
    "task_id": "task_42",
    "filename": "homepage-v3.png",
    "content_type": "image/png",
    "size": 1048576,
    "description": "Final mockup for homepage redesign",
    "uploaded_by": "user_05",
    "created_at": "2026-03-15T10:30:00Z"
  }
}
```

## Download Links

Download URLs are temporary signed URLs valid for 1 hour:

```
GET /v1/attachments/attach_001/download
```

```json
{
  "data": {
    "download_url": "https://cdn.nimbus.io/files/file_abc123?token=...",
    "expires_at": "2026-03-15T11:30:00Z"
  }
}
```

## Inline Previews

For images and PDFs, a preview endpoint generates thumbnail URLs:

```
GET /v1/attachments/attach_001/preview?width=300&height=200
```

Preview generation is asynchronous. If the preview is not yet ready, the response includes `status: "processing"` and clients should retry.

## Attachment Limits

| Tier | Attachments per Task | Total per Workspace |
|------|---------------------|---------------------|
| Free | 10 | 500 |
| Pro | 50 | 10,000 |
| Enterprise | 200 | Unlimited |

## Comment Attachments

Files can also be attached to comments:

```json
POST /v1/comments/comment_101/attachments
{
  "file_id": "file_def456"
}
```

## Searching Attachments

Search across all attachments in a project:

```
GET /v1/projects/proj_01/attachments?filter[content_type.starts_with]=image&filter[filename.contains]=mockup
```

## See Also

- [File Uploads](file-uploads.md) — uploading files before attaching
- [Tasks Endpoint](tasks-endpoint.md) — task that attachments belong to
- [Comments Endpoint](comments-endpoint.md) — comment attachments
- [Search Endpoint](search-endpoint.md) — searching attachment metadata

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: attachment limits, preview generation, or download URL behavior changes -->
