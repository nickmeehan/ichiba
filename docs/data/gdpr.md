# GDPR Compliance

Nimbus processes personal data of EU residents and is fully compliant with the General Data Protection Regulation (GDPR). This document covers technical implementation of data subject rights, the erasure pipeline, data portability, consent management, and Data Processing Agreement (DPA) requirements.

## Data Subject Rights

Nimbus supports all GDPR data subject rights through both the user interface and admin API:

| Right | Implementation | SLA |
|-------|---------------|-----|
| Right of access (Art. 15) | Users can download all their data from Settings > Privacy | 24 hours |
| Right to rectification (Art. 16) | Users edit their profile directly; admins can correct data via API | Immediate |
| Right to erasure (Art. 17) | Erasure request via Settings or admin API triggers deletion pipeline | 30 days |
| Right to portability (Art. 20) | Data export in JSON and CSV formats | 24 hours |
| Right to restrict processing (Art. 18) | Account suspension flag stops all processing except storage | Immediate |
| Right to object (Art. 21) | Marketing preferences and analytics opt-out in Settings | Immediate |

## Right to Erasure Pipeline

When a user or tenant admin requests erasure:

1. **Request logged**: An erasure request record is created in the `erasure_requests` table with status `pending`.
2. **Grace period**: A 7-day grace period allows the request to be cancelled (for accidental requests).
3. **Erasure execution**: A Temporal workflow processes the erasure:
   - Deletes user profile, avatar, and preferences from PostgreSQL
   - Removes user's comments and replaces author with "Deleted User"
   - Anonymizes task assignment history (replaces user ID with a hash)
   - Deletes entries from the event store or replaces PII in event payloads
   - Removes user data from ClickHouse analytics tables
   - Deletes uploaded files from S3
   - Purges user data from Redis caches
   - Removes user from search indexes (Elasticsearch)
4. **Verification**: A post-erasure audit query scans all data stores to confirm no PII remains.
5. **Confirmation**: The user receives an email confirming erasure completion.

Erasure does not delete data that must be retained for legal obligations (e.g., billing records, which are anonymized instead).

## Data Portability

Users can export their data in two formats:

- **JSON**: Structured export following the Nimbus API schema. Includes profile, tasks created, comments, time entries, and activity history.
- **CSV**: Flat export suitable for spreadsheet import. Each entity type is a separate CSV file in a ZIP archive.

Export jobs run asynchronously. The user receives an email with a download link (valid for 48 hours) when the export is ready. Exports are encrypted at rest in S3 using AES-256.

## Consent Management

Nimbus tracks consent for each processing purpose:

| Purpose | Lawful Basis | Consent Required |
|---------|-------------|-----------------|
| Core service delivery | Contract (Art. 6(1)(b)) | No |
| Email notifications | Legitimate interest (Art. 6(1)(f)) | Opt-out available |
| Analytics and product improvement | Consent (Art. 6(1)(a)) | Yes |
| Marketing communications | Consent (Art. 6(1)(a)) | Yes |
| Third-party integrations | Consent (Art. 6(1)(a)) | Yes, per integration |

Consent records are stored in the `consent_records` table with timestamp, IP address, and the version of the privacy policy the user agreed to. Consent can be withdrawn at any time from Settings > Privacy.

## DPA Requirements

Enterprise tenants sign a Data Processing Agreement that specifies:

- **Data categories**: Names, email addresses, profile photos, task content, file uploads
- **Processing purposes**: Project management service delivery, analytics, support
- **Sub-processors**: AWS (infrastructure), Cloudflare (CDN), Sentry (error tracking), SendGrid (email)
- **Data location**: EU region (eu-west-1) for EU tenants, US region (us-east-1) for US tenants
- **Breach notification**: Within 72 hours of discovery, as required by Art. 33
- **Audit rights**: Tenants may request SOC 2 Type II reports and penetration test summaries

The sub-processor list is maintained at `https://nimbus.io/legal/sub-processors` and updated 30 days before adding new sub-processors.

## See Also

- [ETL Pipelines](etl-pipelines.md) for PII masking in analytics data
- [Data Models](models.md) for which fields contain personal data
- [Disaster Recovery](../ops/disaster-recovery.md) for data retention in backups after erasure

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: GDPR regulations are updated, sub-processors change, or erasure pipeline is modified -->
