# File Uploads

Nimbus supports file uploads via multipart form data and presigned URLs. Uploads can be attached to tasks, comments, or projects.

## Multipart Upload

For files under 50 MB, use standard multipart upload:

```
POST /v1/files/upload
Content-Type: multipart/form-data

file=@document.pdf
resource_type=task
resource_id=task_42
```

The response returns a file object with metadata:

```json
{
  "data": {
    "id": "file_abc123",
    "filename": "document.pdf",
    "size": 2048576,
    "content_type": "application/pdf",
    "url": "https://cdn.nimbus.io/files/file_abc123",
    "created_at": "2026-03-15T10:30:00Z"
  }
}
```

## Presigned URLs

For files over 50 MB or for client-side uploads from browsers, use presigned URLs:

```
POST /v1/files/presign
Content-Type: application/json

{
  "filename": "large-video.mp4",
  "content_type": "video/mp4",
  "size": 524288000
}
```

The response includes a presigned URL for direct upload to cloud storage:

```json
{
  "upload_url": "https://storage.nimbus.io/upload?token=...",
  "file_id": "file_def456",
  "expires_at": "2026-03-15T11:30:00Z"
}
```

After uploading to the presigned URL, confirm the upload:

```
POST /v1/files/file_def456/confirm
```

## Upload Progress

For presigned uploads, query progress via:

```
GET /v1/files/file_def456/status
```

Returns `pending`, `uploading`, `processing`, `ready`, or `failed`.

## File Type Validation

Allowed file types are configured per workspace. Default allowed types include documents, images, videos, and archives. Executable files (`.exe`, `.bat`, `.sh`) are blocked by default.

Custom allow/block lists can be configured in workspace settings.

## Size Limits

| Tier | Max File Size | Total Storage |
|------|--------------|---------------|
| Free | 25 MB | 1 GB |
| Pro | 100 MB | 50 GB |
| Enterprise | 5 GB | Unlimited |

## Virus Scanning

All uploaded files are scanned for malware before being marked as `ready`. Infected files are quarantined and the uploader is notified.

## See Also

- [Attachments Endpoint](attachments-endpoint.md) — associating files with resources
- [REST Overview](rest-overview.md) — multipart content type handling
- [Rate Limits](rate-limits.md) — upload endpoint rate limits
- [Admin Endpoint](admin-endpoint.md) — configuring file type restrictions

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: upload size limits, presigned URL flow, or virus scanning behavior changes -->
