# Dependency Scanning

Third-party dependencies are a significant attack vector. Nimbus uses automated scanning to detect and remediate vulnerabilities in all packages.

## Snyk Integration

Nimbus uses [Snyk](https://snyk.io/) for continuous dependency vulnerability scanning. Snyk is integrated at two points:

1. **CI pipeline**: Every PR is scanned by Snyk. PRs introducing new high or critical vulnerabilities are blocked.
2. **Continuous monitoring**: Snyk monitors the `main` branch daily and opens automated PRs for newly discovered vulnerabilities.

The Snyk project is configured in `.snyk` at the repo root and managed via the Snyk dashboard.

## Vulnerability Severity Thresholds

| Severity | CI behavior | Remediation SLA |
|----------|------------|-----------------|
| Critical (CVSS 9.0+) | Blocks PR merge | 24 hours |
| High (CVSS 7.0-8.9) | Blocks PR merge | 7 days |
| Medium (CVSS 4.0-6.9) | Warning only | 30 days |
| Low (CVSS 0.1-3.9) | Informational | Next quarterly update cycle |

Severity is based on the CVSS score from the National Vulnerability Database (NVD), adjusted by Snyk for exploitability context.

## Update Cadence

Dependencies are updated on a regular schedule to reduce vulnerability accumulation:

| Dependency type | Update frequency | Process |
|----------------|-----------------|---------|
| Security patches | Immediately (automated Snyk PR) | Auto-merge if tests pass |
| Minor updates | Weekly (Renovate bot) | Review and merge |
| Major updates | Monthly (manual) | Review changelog, test in staging |

Renovate is configured in `renovate.json` with auto-merge enabled for patch-level updates that pass all CI checks.

## Exception Process

If a vulnerability cannot be remediated immediately (e.g., no fix available, breaking upgrade):

1. File a Linear ticket with the `security-exception` label.
2. Document the vulnerability, affected package, and justification for delay.
3. Get approval from the tech lead and security lead.
4. Add the exception to `.snyk` with an expiry date:

```yaml
ignore:
  SNYK-JS-EXAMPLE-123456:
    - '*':
        reason: 'No fix available. Mitigated by input validation. Expires 2026-06-15.'
        expires: 2026-06-15
```

5. Set a calendar reminder to revisit the exception before expiry.

## See Also

- [Compliance](compliance.md) — vulnerability management as a SOC 2 control
- [CI/CD Pipeline](../deployment/ci-cd.md) — where scanning runs in the pipeline
- [Penetration Testing](penetration-testing.md) — external validation of dependency security

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Snyk configuration, severity thresholds, or update cadence changes -->
