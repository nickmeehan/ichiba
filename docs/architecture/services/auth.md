# Auth Service

The auth service handles user authentication, session management, and role-based access control for the Nimbus platform. It supports both email/password credentials and OAuth2 social login providers.

## JWT Token Strategy

Nimbus uses a dual-token approach:

- **Access Token**: Short-lived (15 minutes), contains user ID, tenant ID, and role. Sent as a Bearer token in the `Authorization` header.
- **Refresh Token**: Long-lived (30 days), stored in an HTTP-only secure cookie. Used to obtain new access tokens without re-authentication.

Tokens are signed with RS256 using a rotating key pair. The public key is available at `/.well-known/jwks.json` for external verification.

## OAuth2 Providers

Users can sign in through the following OAuth2 providers:

| Provider  | Scopes Requested           | Notes                                |
|-----------|---------------------------|---------------------------------------|
| Google    | `openid email profile`     | Domain restriction available          |
| GitHub    | `user:email read:org`      | Organization membership checked       |
| Microsoft | `openid email profile`     | Azure AD tenant restriction available |

On first OAuth login, a Nimbus account is created and linked to the provider. Subsequent logins match by email address with provider verification.

## RBAC Model

Permissions are assigned through roles at the workspace level:

| Role    | Description                                    | Example Permissions                        |
|---------|------------------------------------------------|--------------------------------------------|
| Owner   | Full workspace control including billing        | All permissions, transfer ownership        |
| Admin   | Manage members, projects, and workspace settings| Invite members, delete projects, manage integrations |
| Member  | Standard project participation                  | Create tasks, comment, manage own items     |
| Guest   | Read-only access to specific projects           | View tasks, view comments                   |

Custom roles can be created by Owners and Admins. Each custom role is defined as a set of granular permission strings (e.g., `task.create`, `project.settings.update`).

## Permission Checks

Authorization checks happen at the service layer using a `requirePermission` helper:

```typescript
async function updateTask(taskId: string, updates: TaskUpdate) {
  await requirePermission('task.update', { taskId });
  // ... business logic
}
```

The helper resolves the user's effective permissions from their role and any project-level overrides, then throws an `AuthorizationError` if the check fails.

## Session Management

Active sessions are tracked in Redis. When a user's role changes or they are removed from a workspace, all their active sessions for that workspace are invalidated immediately by deleting the refresh token entries.

## See Also

- [OAuth Flows](./integrations/oauth-flows.md) - OAuth2 implementation details
- [SSO Providers](./integrations/sso-providers/_index.md) - Enterprise SSO configuration
- [Multi-Tenancy](../multi-tenancy.md) - Tenant context in JWT claims

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New OAuth providers are added or the RBAC model changes -->
