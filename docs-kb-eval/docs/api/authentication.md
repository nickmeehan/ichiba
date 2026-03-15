# Authentication

All Nimbus API requests require authentication. Nimbus supports Bearer tokens, API keys, and OAuth 2.0 flows depending on the integration context.

## Bearer Tokens

The primary authentication method uses short-lived JWT Bearer tokens obtained through the OAuth 2.0 authorization code flow or the token endpoint.

```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

Tokens expire after 1 hour. Use refresh tokens to obtain new access tokens without requiring user interaction.

## API Keys

For server-to-server integrations, API keys provide long-lived authentication. Keys are created in the workspace settings and scoped to specific permissions.

```
Authorization: ApiKey nbs_k_abc123def456
```

API keys are prefixed with `nbs_k_` for identification. They do not expire but can be rotated or revoked by workspace admins.

## OAuth 2.0 Scopes

Tokens are scoped to specific permissions. Available scopes include:

| Scope | Description |
|-------|-------------|
| `projects:read` | Read project data |
| `projects:write` | Create and modify projects |
| `tasks:read` | Read task data |
| `tasks:write` | Create and modify tasks |
| `admin:read` | Read workspace admin settings |
| `admin:write` | Modify workspace admin settings |
| `billing:manage` | Manage billing and subscriptions |

Request only the scopes you need. Overly broad scopes may be rejected during review for marketplace apps.

## Token Introspection

Verify a token's validity and metadata via the introspection endpoint:

```
POST /v1/oauth/introspect
Content-Type: application/json

{ "token": "eyJhbGciOiJSUzI1NiIs..." }
```

The response includes `active`, `scope`, `exp`, `sub`, and `workspace_id` fields.

## Auth Middleware

The Nimbus API middleware validates tokens on every request. If the token is expired, malformed, or lacks required scopes, the API returns a `401 Unauthorized` or `403 Forbidden` error with a descriptive message.

## Multi-Tenant Context

Each token is bound to a workspace. To operate across workspaces, obtain separate tokens for each workspace or use workspace-switching headers with an appropriately scoped token.

## See Also

- [REST Overview](rest-overview.md) — general API conventions
- [Rate Limits](rate-limits.md) — rate limits vary by auth method
- [Roles Endpoint](roles-endpoint.md) — role-based access control
- [Permissions Endpoint](permissions-endpoint.md) — fine-grained permissions

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: OAuth scopes, token formats, or auth middleware behavior changes -->
