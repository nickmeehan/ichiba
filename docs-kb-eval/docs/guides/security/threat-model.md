# Threat Model

This document describes the Nimbus threat model using the STRIDE framework, covering attack surfaces, trust boundaries, and mitigation strategies.

## STRIDE Analysis

| Threat | Category | Risk | Mitigation |
|--------|----------|------|------------|
| Tenant data leakage | Information Disclosure | Critical | Row-level `tenantId` filtering on all queries |
| Session hijacking | Spoofing | High | Secure, HttpOnly, SameSite cookies; short-lived JWTs |
| Privilege escalation | Elevation of Privilege | High | Role-based access control (RBAC) checked at API layer |
| SQL injection | Tampering | High | Parameterized queries via Prisma ORM |
| CSRF on state-changing endpoints | Tampering | Medium | CSRF tokens + SameSite cookies |
| XSS via user-generated content | Tampering | Medium | React auto-escaping + CSP headers |
| DDoS on public API | Denial of Service | Medium | Rate limiting, WAF rules, auto-scaling |
| Dependency vulnerabilities | Tampering | Medium | Automated Snyk scanning + update cadence |

## Attack Surfaces

### External Attack Surface
- **Web application** (`app.nimbus.io`): Authenticated React SPA. Attack vectors include XSS, CSRF, and session fixation.
- **Public API** (`api.nimbus.io/v1/`): OAuth2/JWT-authenticated REST API. Attack vectors include injection, broken authentication, and rate limit bypass.
- **Webhook endpoints** (`api.nimbus.io/webhooks/`): Verified by signature (Stripe, GitHub). Attack vector: signature bypass.

### Internal Attack Surface
- **Database**: PostgreSQL with TLS. Access restricted to API and worker services via security groups.
- **Redis**: Used for caching and job queues. No authentication in VPC (access controlled by security groups).
- **S3 buckets**: Private by default. Pre-signed URLs for upload/download with 15-minute expiry.

## Trust Boundaries

1. **Internet to ALB**: TLS termination, WAF filtering, rate limiting.
2. **ALB to ECS**: Internal VPC traffic. Services trust the `X-Tenant-ID` header set by the auth middleware (never from external requests).
3. **ECS to Database**: TLS connection, IAM authentication, connection pooling via PgBouncer.
4. **ECS to External Services**: Outbound traffic through NAT gateway. API keys stored in AWS Secrets Manager.

## Risk Assessment

Risks are assessed on a matrix of likelihood (1-5) and impact (1-5):

- **Critical** (score 20-25): Must be mitigated before launch. Reviewed quarterly.
- **High** (score 12-19): Must have mitigation plan. Reviewed quarterly.
- **Medium** (score 6-11): Should be mitigated. Reviewed semi-annually.
- **Low** (score 1-5): Accept or mitigate opportunistically.

## Mitigation Strategies

Each identified threat has a corresponding mitigation tracked in the security backlog. Mitigations are reviewed in the monthly security review meeting. For implementation details, see the specific security guides linked below.

## See Also

- [Input Validation](input-validation.md) — protecting against injection attacks
- [XSS Prevention](xss-prevention.md) — mitigating cross-site scripting
- [Compliance](compliance.md) — regulatory requirements that drive security controls

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: architecture changes, new external integrations, or annual threat model review -->
