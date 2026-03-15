# Penetration Testing

Nimbus undergoes regular penetration testing to validate our security controls. This guide covers the schedule, scope, remediation process, and retest requirements.

## Annual Pentest Schedule

Nimbus conducts a comprehensive penetration test annually, typically in Q1, plus a focused retest in Q3. The timeline:

| Phase | Duration | Activities |
|-------|----------|-----------|
| Scoping | 2 weeks | Define targets, credentials, and rules of engagement |
| Testing | 3 weeks | External firm conducts testing |
| Reporting | 1 week | Firm delivers findings report |
| Remediation | 4-8 weeks | Engineering addresses findings |
| Retest | 1 week | Firm verifies critical/high findings are resolved |

The pentest is conducted by an independent third-party firm selected through the vendor review process. The current vendor is reviewed annually.

## Scope Definition

The pentest scope includes:

### In Scope
- Web application (`app.nimbus.io`)
- Public API (`api.nimbus.io/v1/`)
- Authentication and session management
- Multi-tenant isolation (critical focus area)
- File upload and download functionality
- Webhook endpoints
- Infrastructure configuration (AWS)

### Out of Scope
- Physical security
- Social engineering against employees
- Denial of service testing against production (staging only)
- Third-party SaaS integrations (Stripe, SendGrid, LaunchDarkly)

Test credentials and a dedicated staging tenant are provided to the testing firm.

## Finding Remediation SLAs

Findings are prioritized by severity and assigned remediation deadlines:

| Severity | SLA | Example |
|----------|-----|---------|
| Critical | 7 days | Authentication bypass, SQL injection, tenant data leakage |
| High | 30 days | Stored XSS, privilege escalation, insecure direct object reference |
| Medium | 90 days | Missing security headers, verbose error messages, weak session config |
| Low | 180 days | Information disclosure in HTTP headers, cookie without Secure flag |
| Informational | Best effort | Minor configuration recommendations |

Findings are tracked as Linear tickets with the `pentest-finding` label and assigned severity.

## Retest Process

After remediation:

1. The engineering team marks findings as resolved in the tracking system.
2. The pentest firm retests all critical and high findings.
3. Findings that pass retest are closed.
4. Findings that fail retest have their SLA reset and are escalated to the engineering manager.

The retest report is shared with the security team and archived for SOC 2 audit evidence.

## See Also

- [Threat Model](threat-model.md) — understanding what the pentest validates
- [Compliance](compliance.md) — pentest as a compliance requirement
- [Incident Response](../incident-response.md) — handling findings that indicate active exploitation

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: pentest vendor, schedule, scope, or SLA policy changes -->
