# Azure AD SSO

This document covers integrating Azure Active Directory (now Microsoft Entra ID) with Nimbus for enterprise single sign-on. The integration uses OpenID Connect for authentication and supports group-to-role mapping.

## App Registration

To connect Azure AD with Nimbus, a workspace admin registers Nimbus as an application in the Azure portal:

1. Navigate to **Azure Active Directory > App registrations > New registration**.
2. Set the application name to "Nimbus SSO".
3. Set the redirect URI to `https://{workspace}.nimbus.app/api/auth/sso/azure/callback`.
4. Select "Accounts in this organizational directory only" for supported account types.
5. After creation, note the **Application (client) ID** and **Directory (tenant) ID**.
6. Under **Certificates & secrets**, create a new client secret and copy the value.

Enter these values in the Nimbus workspace SSO settings under the Azure AD provider section.

## OIDC Configuration

Nimbus uses the following Azure AD OIDC endpoints:

| Endpoint      | URL                                                                      |
|--------------|--------------------------------------------------------------------------|
| Authorization | `https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/authorize`   |
| Token         | `https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token`       |
| UserInfo      | `https://graph.microsoft.com/oidc/userinfo`                             |
| JWKS          | `https://login.microsoftonline.com/{tenantId}/discovery/v2.0/keys`     |

The requested scopes are `openid email profile` and optionally `GroupMember.Read.All` for group sync.

## Group-to-Role Mapping

Azure AD groups can be mapped to Nimbus RBAC roles. When a user authenticates via SSO, their Azure AD group memberships are read from the ID token's `groups` claim or via the Microsoft Graph API.

| Azure AD Group         | Nimbus Role |
|-----------------------|-------------|
| `Nimbus-Admins`       | Admin       |
| `Nimbus-Members`      | Member      |
| `Nimbus-Guests`       | Guest       |

Group mappings are configured in the Nimbus SSO settings. Users whose groups change in Azure AD have their Nimbus roles updated on their next login.

## Conditional Access Policies

Azure AD conditional access policies are respected by the integration. Common policies that affect the Nimbus login flow:

- **MFA requirement**: Users may be prompted for MFA during the Azure AD login step.
- **Location-based access**: Users outside approved networks are blocked at the Azure AD level.
- **Device compliance**: Only managed devices can complete the sign-in.

These policies are managed entirely in Azure AD and are transparent to Nimbus.

## See Also

- [Google Workspace SSO](./google-workspace.md) - Alternative cloud identity provider
- [Generic SAML](./saml-generic.md) - SAML-based alternative
- [Auth Service](../../auth.md) - How SSO tokens are processed by Nimbus

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Azure AD API changes or Microsoft rebrands endpoints -->
