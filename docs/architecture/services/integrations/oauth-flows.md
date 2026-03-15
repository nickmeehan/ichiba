# OAuth Flows

This document describes how Nimbus implements OAuth2 for both authenticating users via social login and connecting third-party integrations. The implementation follows RFC 6749 and RFC 7636 (PKCE).

## Authorization Code Flow

The standard authorization code flow is used for server-side integrations (Slack, GitHub, Jira):

1. **Initiate**: User clicks "Connect {Provider}" in Nimbus. The backend generates a state parameter (random string stored in the user's session) and redirects to the provider's authorization endpoint.
2. **Authorize**: User grants permissions on the provider's consent screen.
3. **Callback**: Provider redirects to `/api/integrations/{provider}/callback` with an authorization code and the state parameter.
4. **Verify State**: Backend verifies the state parameter matches the session value to prevent CSRF.
5. **Exchange**: Backend exchanges the authorization code for access and refresh tokens using the provider's token endpoint.
6. **Store**: Tokens are encrypted with AES-256-GCM and stored in the `integration_tokens` table, scoped to the workspace.

## PKCE for SPAs

When the frontend initiates OAuth flows (e.g., social login), PKCE (Proof Key for Code Exchange) is used to secure the flow since the SPA cannot safely store a client secret:

1. Frontend generates a random `code_verifier` and computes the `code_challenge` (SHA-256 hash, base64url-encoded).
2. The authorization request includes `code_challenge` and `code_challenge_method=S256`.
3. On callback, the backend sends the `code_verifier` with the token exchange request.
4. The authorization server verifies the challenge matches before issuing tokens.

## Token Storage

| Token Type     | Storage Location          | Encryption       | TTL                   |
|---------------|---------------------------|------------------|-----------------------|
| Access Token  | In-memory (backend)       | AES-256-GCM     | Provider-dependent     |
| Refresh Token | PostgreSQL                | AES-256-GCM     | Until revoked          |
| State Param   | Redis                     | None (random)    | 10 minutes             |

Encryption keys are stored in AWS Secrets Manager and rotated quarterly. Old keys are retained for decryption of existing tokens during the rotation period.

## Refresh Token Rotation

When an access token expires, the backend uses the stored refresh token to obtain a new pair. If the provider supports refresh token rotation (e.g., returning a new refresh token with each refresh), the old refresh token is immediately replaced. This limits the window of exposure if a refresh token is compromised.

## Scope Management

Each integration requests only the minimum OAuth scopes required for its functionality. Scopes are defined per integration in the configuration:

```typescript
const GITHUB_SCOPES = ['repo', 'read:org', 'read:user'];
const SLACK_SCOPES = ['commands', 'chat:write', 'users:read'];
```

If a user has previously authorized with fewer scopes, the integration prompts for re-authorization with the updated scope list.

## Token Revocation

When a workspace admin disconnects an integration, Nimbus calls the provider's revocation endpoint to invalidate the tokens, then deletes the encrypted token records from the database.

## See Also

- [Auth Service](../auth.md) - Social login using OAuth
- [SSO Providers](./sso-providers/_index.md) - Enterprise OAuth/OIDC flows
- [Secrets Management](../../infrastructure/secrets.md) - Encryption key storage

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New OAuth providers are added or token storage strategy changes -->
