# Compliance

Nimbus maintains compliance with SOC 2 Type II, GDPR, and customer-specific data residency requirements. This guide covers what engineers need to know about compliance obligations.

## SOC 2 Type II

Nimbus holds a SOC 2 Type II certification covering the Security, Availability, and Confidentiality trust service criteria. Key controls that impact engineering:

| Control area | Engineering responsibility |
|-------------|--------------------------|
| Access control | Use SSO for all services. Remove access within 24 hours of offboarding. |
| Change management | All code changes go through PR review. No direct pushes to `main`. |
| Incident management | Follow the [Incident Response](../incident-response.md) process for all P0/P1 incidents. |
| Vulnerability management | Remediate vulnerabilities within [defined SLAs](dependency-scanning.md). |
| Logging and monitoring | Maintain audit logs for 1 year. Do not disable logging. |
| Encryption | Data encrypted at rest (AES-256) and in transit (TLS 1.2+). |

The SOC 2 audit occurs annually. The auditor may interview engineers and review code samples.

## GDPR

Nimbus processes personal data of EU-based users and must comply with GDPR:

### Data Subject Rights
- **Right to access**: Users can export their data via Settings > Export Data.
- **Right to deletion**: Users can request account deletion. The `gdpr:delete-user` script handles cascading deletion and anonymization.
- **Right to portability**: Data export is in JSON format, machine-readable.
- **Right to rectification**: Users can update their profile data directly.

### Data Processing
- Personal data processing purposes are documented in the privacy policy.
- Data processing agreements (DPAs) are in place with all sub-processors (AWS, Stripe, SendGrid, Datadog).
- PII is redacted from logs using the Pino redaction configuration (see [Logging](../../conventions/logging.md)).

## Data Residency

Enterprise customers can specify data residency requirements:

| Region | Database | File storage | Available |
|--------|----------|-------------|-----------|
| US (us-east-1) | RDS PostgreSQL | S3 | Default |
| EU (eu-west-1) | RDS PostgreSQL | S3 | Available |
| APAC (ap-southeast-1) | RDS PostgreSQL | S3 | Roadmap |

Tenant data residency is configured at tenant creation and cannot be changed without a data migration. The `tenantRegion` field in the tenant record determines which database and storage backend are used.

## Audit Evidence Collection

Evidence for SOC 2 audits is collected automatically where possible:

- **Access reviews**: Quarterly automated reports from GitHub and AWS IAM.
- **Change management**: GitHub PR history with required approvals.
- **Incident response**: Linear tickets with `incident` label and PIR documents.
- **Vulnerability management**: Snyk dashboard exports.

Manual evidence (policy acknowledgments, training records) is tracked in the compliance dashboard at `https://compliance.nimbus.io` (internal).

## Compliance Dashboard

The internal compliance dashboard shows:
- Current audit status and upcoming deadlines
- Open compliance-related tickets
- Policy document versions and acknowledgment status
- Sub-processor inventory and DPA status

## See Also

- [Secrets Management](secrets-management.md) — encryption and key management
- [Logging Conventions](../../conventions/logging.md) — PII redaction in logs
- [Penetration Testing](penetration-testing.md) — security validation

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: compliance certifications, GDPR requirements, or data residency options change -->
