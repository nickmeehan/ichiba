# Okta SSO Setup

This guide walks through configuring Okta as the identity provider for a Nimbus workspace using OIDC. The process involves creating an Okta application, configuring redirect URIs, and setting up group claims.

## Prerequisites

- An Okta organization with admin access.
- A Nimbus workspace on the Enterprise tier.
- The workspace URL (e.g., `https://acme.nimbus.app`).

## Create the Okta Application

1. In the Okta Admin Console, navigate to **Applications > Create App Integration**.
2. Select **OIDC - OpenID Connect** as the sign-in method.
3. Select **Web Application** as the application type.
4. Configure the application:
   - **App integration name**: Nimbus
   - **Grant type**: Authorization Code
   - **Sign-in redirect URI**: `https://{workspace}.nimbus.app/api/auth/sso/okta/callback`
   - **Sign-out redirect URI**: `https://{workspace}.nimbus.app/logout`
   - **Controlled access**: Assign to the appropriate groups.
5. Save the application and note the **Client ID** and **Client Secret**.

## Configure Nimbus

In the Nimbus workspace settings, navigate to **Security > SSO > Okta** and enter:

| Field              | Value                                                    |
|-------------------|----------------------------------------------------------|
| Okta Domain       | `https://acme.okta.com` (your Okta org URL)              |
| Client ID         | From the Okta application settings                       |
| Client Secret     | From the Okta application settings                       |
| Scopes            | `openid email profile groups` (default)                  |

## Group Claims

To enable role mapping based on Okta groups, configure a groups claim in the Okta application:

1. In the Okta application, go to **Sign On > OpenID Connect ID Token**.
2. Under **Groups claim type**, select "Filter".
3. Set the filter to: **Starts with** `Nimbus-`.
4. Set the claim name to `groups`.

This ensures that only Nimbus-related group names are included in the ID token, avoiding token bloat from unrelated groups.

## MFA Enforcement

If your organization requires MFA, configure an Okta sign-on policy for the Nimbus application:

1. In the Okta Admin Console, navigate to **Security > Authentication Policies**.
2. Create or edit a policy and add a rule for the Nimbus application.
3. Set **User must authenticate with** to "Password + Another factor".

Nimbus does not manage MFA directly; it relies on Okta to enforce MFA before issuing the OIDC tokens.

## Nimbus-Side Configuration

After saving the Okta settings in Nimbus, click **Test Connection** to verify the setup. This initiates a test authentication flow that confirms:

- The Okta domain is reachable.
- The client ID and secret are valid.
- The redirect URI matches.
- Group claims are present in the token.

Once the test passes, enable "SSO Required" to enforce Okta authentication for all workspace members.

## See Also

- [App Registration](./config/app-registration.md) - Detailed Okta app configuration
- [Attribute Mapping](./config/attribute-mapping.md) - User profile field mapping
- [Troubleshooting](./troubleshooting.md) - Common setup issues

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Okta Admin Console UI changes or OIDC configuration options are updated -->
