# CSRF Protection

Cross-Site Request Forgery (CSRF) attacks trick authenticated users into making unintended requests. Nimbus uses a layered approach to prevent CSRF across all state-changing operations.

## CSRF Token Generation

Nimbus generates a CSRF token per session and stores it in a secure, HttpOnly cookie. The token is also embedded in the page HTML as a meta tag for the frontend to read.

Server-side token generation (`apps/api/src/middleware/csrf.ts`):

```typescript
import { randomBytes } from 'crypto';

function generateCsrfToken(): string {
  return randomBytes(32).toString('hex');
}
```

The frontend reads the token from the meta tag and includes it in all state-changing requests:

```typescript
// Automatically attached by the API client
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
headers['X-CSRF-Token'] = csrfToken;
```

## SameSite Cookies

All Nimbus session cookies are set with `SameSite=Lax`:

```typescript
res.cookie('session', token, {
  httpOnly: true,
  secure: true,
  sameSite: 'lax',
  maxAge: 24 * 60 * 60 * 1000, // 24 hours
  domain: '.nimbus.io',
});
```

`SameSite=Lax` prevents the cookie from being sent on cross-origin POST requests, which blocks the most common CSRF attack vector. We use `Lax` instead of `Strict` to allow top-level navigations from external links (e.g., email notification links).

## Double-Submit Cookie Pattern

As an additional layer, Nimbus implements the double-submit cookie pattern:

1. The server sets a `csrf-token` cookie (not HttpOnly, so JavaScript can read it).
2. The frontend sends the same value in the `X-CSRF-Token` header.
3. The server verifies that the cookie value matches the header value.

An attacker cannot read the cookie value from a different origin due to the Same-Origin Policy, so they cannot forge the header.

## CORS Interaction

CSRF protection works in conjunction with CORS configuration:

```typescript
const corsOptions = {
  origin: ['https://app.nimbus.io', 'https://staging.nimbus.io'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
};
```

- Only `nimbus.io` subdomains are allowed as origins.
- `credentials: true` allows cookies to be sent cross-origin within our subdomains.
- Preflight requests (`OPTIONS`) are handled automatically by the CORS middleware.

## Exempt Endpoints

The following endpoints are exempt from CSRF checks:

- `POST /webhooks/*` — Verified by webhook signature instead.
- `POST /api/v1/auth/token` — OAuth2 token endpoint uses client credentials.

All exemptions are documented in `apps/api/src/middleware/csrf.ts` with justification comments.

## See Also

- [XSS Prevention](xss-prevention.md) — preventing token theft via XSS
- [Secrets Management](secrets-management.md) — managing session signing keys
- [API Design](../../conventions/api-design.md) — HTTP method semantics

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: authentication flow, cookie configuration, or CORS policy changes -->
