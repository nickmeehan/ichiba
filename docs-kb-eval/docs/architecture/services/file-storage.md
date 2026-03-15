# File Storage

The file storage service manages file uploads, downloads, and media processing for Nimbus. It uses S3-compatible object storage with presigned URLs for direct client-to-storage transfers that bypass the API server.

## Upload Flow

1. Client requests a presigned upload URL from the API, providing the file name and MIME type.
2. API generates a presigned PUT URL with a 15-minute expiration, scoped to the workspace's storage prefix.
3. Client uploads the file directly to S3 using the presigned URL.
4. Client confirms the upload by calling the API with the S3 key.
5. API records the file metadata in PostgreSQL and triggers post-upload processing.

This approach keeps large file transfers off the API server and allows direct uploads of up to 5 GB per file.

## Post-Upload Processing

After a file is confirmed, a background worker processes it:

- **Virus Scanning**: Files are scanned using ClamAV. Infected files are quarantined and the uploader is notified.
- **Thumbnail Generation**: Images and PDFs have thumbnails generated at 200x200 and 800x800 resolutions using Sharp.
- **Metadata Extraction**: EXIF data from images and page counts from PDFs are stored as file metadata.

## Storage Layout

Files are organized in S3 with the following key structure:

```
{tenantId}/{projectId}/attachments/{fileId}/{filename}
{tenantId}/{projectId}/attachments/{fileId}/thumb_200.webp
{tenantId}/{projectId}/attachments/{fileId}/thumb_800.webp
```

The `tenantId` prefix ensures that even at the storage level, files are namespaced by workspace.

## Download and Access

File downloads use presigned GET URLs with a 1-hour expiration. The API verifies that the requesting user has read access to the project before generating the URL. Presigned URLs are not cached because they contain time-limited signatures.

## Storage Quotas

Each workspace has a storage quota based on its subscription tier:

| Tier       | Storage Quota |
|------------|---------------|
| Free       | 100 MB        |
| Pro        | 10 GB         |
| Enterprise | 100 GB        |

The upload endpoint checks the workspace's current usage before issuing a presigned URL. Usage is calculated by summing file sizes from the `files` table, with a cached value refreshed every 5 minutes.

## Cleanup

When a file is deleted through the API, the database record is soft-deleted. A nightly cleanup job permanently removes soft-deleted files from S3 after a 30-day retention period, allowing recovery if the deletion was accidental.

## See Also

- [Billing](./billing.md) - Storage quota enforcement by subscription tier
- [Scheduler](./scheduler.md) - Cleanup job scheduling
- [Virus Scanning Pipeline](../data-flow.md) - Worker processing flow

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Storage provider changes or quota limits are adjusted -->
