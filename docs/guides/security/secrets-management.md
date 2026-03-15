# Secrets Management

This guide covers how Nimbus handles secrets (API keys, tokens, database credentials, signing keys) across all environments.

## Never Commit Secrets

Secrets must never appear in the Git repository. The following safeguards are in place:

- **`.gitignore`**: Patterns for `.env`, `.env.local`, `*.pem`, and `credentials.json`.
- **Pre-commit hook**: Runs `detect-secrets` to scan staged files for patterns matching API keys, tokens, and passwords.
- **CI check**: The `ci.yml` workflow includes a secrets scan step that fails the build if secrets are detected.

If a secret is accidentally committed, treat it as compromised: rotate immediately and follow the emergency rotation procedure below.

## Environment Variable Injection

Secrets are injected into running services via environment variables, never baked into Docker images or config files.

| Environment | Secret storage | Injection method |
|------------|---------------|-----------------|
| Local dev | `.env.local` file | Loaded by `dotenv` |
| Staging | AWS Parameter Store | ECS task definition |
| Production | AWS Secrets Manager | ECS task definition |

Secrets in AWS Secrets Manager are encrypted with a KMS key managed by the security team. Access is controlled by IAM policies scoped to specific ECS task roles.

## Secret Rotation

Regular rotation reduces the blast radius of a compromised secret:

| Secret type | Rotation frequency | Owner |
|------------|-------------------|-------|
| Database credentials | 90 days | DevOps |
| JWT signing keys | 180 days | DevOps |
| Third-party API keys | 365 days or per vendor policy | DevOps |
| Session encryption keys | 90 days | DevOps |

Rotation is semi-automated: a scheduled Lambda function rotates the secret in AWS and updates the ECS task definition. Services are restarted with a rolling update to pick up the new value.

## Emergency Rotation Procedure

If a secret is compromised (leaked in logs, committed to repo, exposed in error message):

1. **Rotate immediately**: Generate a new secret value and update AWS Secrets Manager.
2. **Restart services**: Force a new ECS deployment to pick up the rotated secret.
3. **Revoke the old secret**: Disable the compromised key at the provider (Stripe dashboard, GitHub settings, etc.).
4. **Audit usage**: Check logs for unauthorized use of the compromised secret. Search for the first 8 characters in Datadog logs.
5. **File an incident**: Follow the [Incident Response](../incident-response.md) process for P1 severity.

```bash
# Emergency rotation commands
pnpm ops:secret-rotate --name STRIPE_SECRET_KEY --env production
pnpm ops:ecs-restart --service api --env production
```

## See Also

- [Compliance](compliance.md) — audit requirements for secret management
- [Incident Response](../incident-response.md) — handling compromised secrets
- [Local Development](../local-dev.md) — local `.env.local` setup

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: secret storage provider, rotation policy, or injection mechanism changes -->
