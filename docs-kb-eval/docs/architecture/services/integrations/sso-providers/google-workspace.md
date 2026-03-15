# Google Workspace SSO

This document covers integrating Google Workspace with Nimbus for enterprise single sign-on. The integration uses OAuth2/OIDC for authentication and supports Google Groups synchronization for role management.

## OAuth Consent Screen

Before users can sign in, a Google Workspace admin must configure the OAuth consent screen:

1. Navigate to **Google Cloud Console > APIs & Services > OAuth consent screen**.
2. Select "Internal" to restrict sign-in to the organization's domain.
3. Set the application name to "Nimbus" and upload the Nimbus logo.
4. Add the scopes: `openid`, `email`, `profile`.
5. Add the authorized domain: `nimbus.app`.

Then create OAuth2 credentials:

1. Go to **Credentials > Create Credentials > OAuth client ID**.
2. Select "Web application".
3. Add the authorized redirect URI: `https://{workspace}.nimbus.app/api/auth/sso/google/callback`.
4. Copy the client ID and client secret into the Nimbus SSO configuration.

## Domain-Wide Delegation

For advanced features like group sync and user directory access, Nimbus requires domain-wide delegation:

1. Create a service account in the Google Cloud Console.
2. Enable domain-wide delegation on the service account.
3. In the Google Admin Console, authorize the service account with the scopes:
   - `https://www.googleapis.com/auth/admin.directory.group.readonly`
   - `https://www.googleapis.com/auth/admin.directory.user.readonly`
4. Upload the service account JSON key to Nimbus SSO settings.

This allows Nimbus to read group memberships and user profiles without requiring individual user consent.

## Group Sync

When domain-wide delegation is enabled, Nimbus can synchronize Google Groups with workspace roles:

| Google Group Email          | Nimbus Role |
|----------------------------|-------------|
| `nimbus-admins@company.com` | Admin       |
| `nimbus-team@company.com`   | Member      |
| `nimbus-external@company.com`| Guest      |

Group membership is checked on each login and can optionally be refreshed on a schedule (every 6 hours) via the scheduler service.

## Admin SDK Usage

The Admin SDK is used for:

- **User provisioning**: When a Google Workspace user is added to a mapped group, they are automatically invited to the Nimbus workspace on their next login.
- **User deprovisioning**: When a user is suspended or deleted in Google Workspace, their Nimbus sessions are revoked on the next group sync.
- **Directory lookup**: The user picker in Nimbus can search the Google Workspace directory to invite users who are not yet members.

## Domain Restriction

Sign-in is restricted to the Google Workspace domain configured during setup. Personal Gmail accounts are rejected even if they attempt to use the SSO endpoint. This is enforced by the `hd` (hosted domain) parameter in the authorization request.

## See Also

- [Azure AD SSO](./azure-ad.md) - Alternative cloud identity provider
- [Auth Service](../../auth.md) - How SSO tokens integrate with Nimbus auth
- [Scheduler](../../scheduler.md) - Group sync scheduling

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Google Workspace API changes or Admin SDK deprecates endpoints -->
