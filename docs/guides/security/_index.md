# Security Guides

Security guidelines and best practices for the Nimbus platform. Every engineer is responsible for understanding and applying these practices in their daily work.

## Available Guides

| Guide | When to use it |
|-------|---------------|
| [Threat Model](threat-model.md) | You need to understand the attack surfaces and trust boundaries in the Nimbus architecture. |
| [Input Validation](input-validation.md) | You are accepting user input and need to validate, sanitize, and constrain it properly. |
| [XSS Prevention](xss-prevention.md) | You are rendering user-generated content and need to prevent cross-site scripting attacks. |
| [CSRF Protection](csrf-protection.md) | You are building forms or state-changing API endpoints and need to protect against cross-site request forgery. |
| [Secrets Management](secrets-management.md) | You need to use, rotate, or manage API keys, tokens, or other sensitive credentials. |
| [Dependency Scanning](dependency-scanning.md) | You need to understand how we detect and remediate vulnerabilities in third-party dependencies. |
| [Penetration Testing](penetration-testing.md) | You are preparing for, participating in, or remediating findings from a penetration test. |
| [Compliance](compliance.md) | You need to understand our SOC 2, GDPR, or data residency compliance requirements. |

## Security Principles

1. **Defense in depth**: No single layer is trusted. Validate at the API, service, and database layers.
2. **Least privilege**: Services and users get the minimum permissions needed.
3. **Tenant isolation**: Every query must be scoped by `tenantId`. Cross-tenant data access is a P0 security incident.
4. **Secure defaults**: Libraries and frameworks are configured securely out of the box.

## Reporting Vulnerabilities

If you discover a security vulnerability, report it to `security@nimbus.io` or via the `#security-reports` Slack channel (private). Do not file a public GitHub issue.

## See Also

- [Code Review](../code-review.md) — security review checklist
- [Error Handling Patterns](../../conventions/error-handling-patterns.md) — safe error responses
- [Incident Response](../incident-response.md) — handling security incidents

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: security policy, compliance requirements, or reporting process changes -->
