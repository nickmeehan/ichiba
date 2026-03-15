# Okta App Registration

This guide provides a detailed walkthrough for creating and configuring the OIDC application in Okta for the Nimbus integration.

## Step 1: Create the Application

1. Log in to the Okta Admin Console.
2. Navigate to **Applications > Applications > Create App Integration**.
3. Select **OIDC - OpenID Connect**.
4. Select **Web Application** and click **Next**.

## Step 2: Configure General Settings

| Field                    | Value                                                              |
|-------------------------|--------------------------------------------------------------------|
| App integration name    | Nimbus SSO                                                         |
| Logo                    | Upload the Nimbus logo (optional)                                  |
| Grant type              | Authorization Code (checked), Refresh Token (checked)              |
| Sign-in redirect URIs   | `https://{workspace}.nimbus.app/api/auth/sso/okta/callback`      |
| Sign-out redirect URIs  | `https://{workspace}.nimbus.app/logout`                           |
| Controlled access       | Limit access to selected groups (recommended)                     |

Click **Save** to create the application.

## Step 3: Client ID and Secret Management

After creation, the **Client Credentials** section displays:

- **Client ID**: A public identifier for the application. This value is not sensitive and is included in authorization requests.
- **Client Secret**: A confidential value used by the Nimbus backend to exchange authorization codes for tokens. This value must be stored securely.

To rotate the client secret:

1. Click **Edit** in the Client Credentials section.
2. Click **Add new secret**. Okta allows two active secrets simultaneously.
3. Update the secret in Nimbus SSO settings.
4. Verify the connection works with the new secret.
5. Delete the old secret in Okta.

This two-secret approach enables zero-downtime secret rotation.

## Step 4: Allowed Grant Types

For the Nimbus integration, the following grant types should be enabled:

| Grant Type          | Purpose                                         | Required |
|--------------------|--------------------------------------------------|----------|
| Authorization Code | Primary login flow via browser redirect           | Yes      |
| Refresh Token      | Obtain new access tokens without re-authentication| Yes      |
| Implicit           | Not used by Nimbus                                | No       |
| Client Credentials | Not used for user authentication                  | No       |

## Step 5: Token Settings

Configure token lifetimes in the Okta authorization server:

| Token Type     | Recommended Lifetime | Notes                                    |
|---------------|---------------------|------------------------------------------|
| Access Token  | 1 hour              | Nimbus caches the token for the session  |
| ID Token      | 1 hour              | Contains user claims for role mapping    |
| Refresh Token | 30 days             | Enables long-lived sessions              |

Token settings are configured under **Security > API > Authorization Servers > default > Access Policies**.

## Step 6: Assign Users and Groups

1. Navigate to the **Assignments** tab of the Nimbus application.
2. Assign individual users or groups that should have access to Nimbus.
3. Only assigned users will be able to authenticate through the SSO flow.

It is recommended to assign groups rather than individual users for easier management.

## See Also

- [Attribute Mapping](./attribute-mapping.md) - Configure profile field mapping
- [MFA Policies](./mfa-policies.md) - Add MFA requirements to the app
- [Troubleshooting](../troubleshooting.md) - Client credential issues

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Okta Admin Console UI changes or OIDC application options are updated -->
