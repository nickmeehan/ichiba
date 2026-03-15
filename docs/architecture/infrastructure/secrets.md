# Secrets Management

Nimbus uses AWS Secrets Manager to store and manage all sensitive configuration values. Secrets are injected into application pods as environment variables at startup and are never stored in the codebase or container images.

## Stored Secrets

| Secret Name                    | Contents                              | Used By           |
|-------------------------------|---------------------------------------|--------------------|
| `nimbus/prod/database`        | PostgreSQL connection string          | API, workers        |
| `nimbus/prod/redis`           | Redis connection string               | API, workers, WS    |
| `nimbus/prod/jwt`             | JWT signing key pair (RS256)          | API                 |
| `nimbus/prod/stripe`          | Stripe API key and webhook secret     | API                 |
| `nimbus/prod/sendgrid`        | SendGrid API key                      | Workers             |
| `nimbus/prod/s3`              | S3 access key and secret key          | API, workers        |
| `nimbus/prod/elasticsearch`   | Elasticsearch credentials             | API, workers        |
| `nimbus/prod/encryption`      | AES-256 key for token encryption      | API                 |
| `nimbus/prod/okta`            | Okta client secret                    | API                 |
| `nimbus/prod/github-app`      | GitHub App private key                | API                 |

## Rotation Policies

Secrets are rotated on a regular schedule:

| Secret Category      | Rotation Frequency | Method                                |
|---------------------|--------------------|---------------------------------------|
| Database passwords  | 90 days            | Automatic via Secrets Manager rotation |
| API keys            | 180 days           | Manual rotation with dual-key overlap  |
| JWT signing keys    | 365 days           | Key rotation with JWKS versioning      |
| Encryption keys     | 365 days           | Dual-key decryption during transition  |

Automatic rotation uses Lambda functions triggered by Secrets Manager. The Lambda creates a new credential, updates the target service, and stores the new value in Secrets Manager.

## Environment Variable Injection

Secrets are injected into Kubernetes pods using the AWS Secrets and Config Provider (ASCP) for the Secrets Store CSI Driver:

1. A `SecretProviderClass` resource defines which Secrets Manager entries to mount.
2. The CSI driver mounts the secrets as a tmpfs volume in the pod.
3. An init container reads the mounted secrets and exports them as environment variables.
4. The application reads standard environment variables (e.g., `DATABASE_URL`).

This approach avoids baking secrets into container images or Kubernetes Secret objects (which are base64-encoded, not encrypted at rest by default).

## Secret Versioning

Secrets Manager automatically versions every secret update. This enables:

- **Rollback**: If a rotated credential causes issues, the previous version can be restored immediately.
- **Audit**: Every version change is logged in CloudTrail with the identity of the actor.
- **Staged rotation**: New credentials can be tested (AWSPENDING stage) before being promoted to the current version (AWSCURRENT).

## Access Audit

Access to secrets is logged through AWS CloudTrail. The following events are monitored:

| Event                        | Alert Condition                        |
|-----------------------------|----------------------------------------|
| `GetSecretValue`            | Access from unexpected IAM role        |
| `PutSecretValue`            | Any manual update (non-rotation)       |
| `DeleteSecret`              | Always alert                           |
| `RotationFailed`            | Always alert                           |

Alerts are sent to the `#security-alerts` Slack channel and the on-call pager.

## See Also

- [Terraform](./terraform.md) - Secrets Manager resources provisioned via Terraform
- [Kubernetes](./kubernetes.md) - CSI driver and pod configuration
- [OAuth Flows](../services/integrations/oauth-flows.md) - Token encryption using managed keys

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Rotation policies change or new secrets are added -->
