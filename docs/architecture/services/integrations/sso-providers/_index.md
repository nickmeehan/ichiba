# SSO Providers

This section covers the enterprise single sign-on integrations available in Nimbus. SSO is available on the Enterprise tier and allows organizations to authenticate their users through their existing identity provider.

## Contents

### [Okta](./okta/_index.md)
When you are configuring Okta as the identity provider, setting up SCIM provisioning, or troubleshooting Okta-specific authentication issues.

### [Azure AD](./azure-ad.md)
When you are integrating with Microsoft Azure Active Directory, configuring OIDC, or mapping Azure AD groups to Nimbus roles.

### [Google Workspace](./google-workspace.md)
When you are setting up Google Workspace as the identity provider, configuring domain-wide delegation, or syncing Google groups with Nimbus.

### [Generic SAML](./saml-generic.md)
When you are connecting a SAML-compliant identity provider that is not explicitly supported, or need to understand the SAML assertion format Nimbus expects.

### [LDAP](./ldap.md)
When you are integrating with an on-premises LDAP directory for user authentication and group synchronization.

## Common Configuration

All SSO providers share a common configuration pattern in Nimbus:

1. Enable SSO in the workspace security settings (requires Enterprise tier).
2. Configure the identity provider using the provider-specific guide.
3. Test the connection with a single user before enforcing SSO for all members.
4. Optionally enable "SSO Required" to prevent password-based login for workspace members.

When SSO is enforced, users are redirected to the identity provider's login page when accessing the workspace. Workspace owners retain the ability to log in with email/password as a recovery mechanism.

## See Also

- [Auth Service](../../auth.md) - Core authentication that SSO builds upon
- [OAuth Flows](../oauth-flows.md) - OAuth2/OIDC protocol implementation
- [Billing](../../billing.md) - Enterprise tier requirement for SSO

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New SSO providers are supported or the SSO enrollment flow changes -->
