# Okta Troubleshooting

This guide covers common issues encountered when configuring or using the Okta SSO integration with Nimbus. Each section describes the symptom, cause, and resolution.

## Common Errors

### `invalid_client` Error

**Symptom**: Users see "invalid_client" on the Okta login page or are redirected back to Nimbus with this error.

**Cause**: The Client ID or Client Secret configured in Nimbus does not match the Okta application.

**Resolution**:
1. Open the Okta Admin Console and navigate to **Applications > Nimbus > General**.
2. Copy the Client ID and Client Secret.
3. Update the values in Nimbus under **Security > SSO > Okta**.
4. Click **Test Connection** to verify.

### Mismatched Redirect URI

**Symptom**: Okta displays "The redirect URI is not allowed for this application" or a similar error.

**Cause**: The redirect URI configured in Okta does not exactly match the one Nimbus sends in the authorization request.

**Resolution**:
1. In Okta, go to **Applications > Nimbus > General > Login**.
2. Verify the sign-in redirect URI is exactly: `https://{workspace}.nimbus.app/api/auth/sso/okta/callback`
3. Check for trailing slashes, protocol mismatches (http vs https), or subdomain differences.

### Missing Groups Claim

**Symptom**: Users authenticate successfully but are assigned the default role instead of their expected role.

**Cause**: The groups claim is not included in the OIDC token or the group filter does not match any groups.

**Resolution**:
1. In Okta, navigate to **Applications > Nimbus > Sign On > OpenID Connect ID Token**.
2. Verify a groups claim is configured with the filter "Starts with: Nimbus-".
3. Ensure users are assigned to at least one Okta group matching the filter.
4. Check that the group names in Okta match the role mapping in Nimbus SSO settings.

### Token Signature Verification Failed

**Symptom**: Nimbus logs show "JWT signature verification failed" and users cannot complete login.

**Cause**: The JWKS endpoint is unreachable, or the signing key has rotated and the cached JWKS is stale.

**Resolution**:
1. Verify that the Nimbus backend can reach `https://{okta-domain}/oauth2/v1/keys`.
2. Clear the JWKS cache by restarting the Nimbus backend pods.
3. If the issue persists, check for network/firewall rules blocking outbound HTTPS from the Nimbus cluster.

## Token Debugging

To inspect the contents of an Okta-issued token:

1. Enable SSO debug logging in Nimbus by setting `SSO_DEBUG=true` in the environment variables.
2. Attempt a login. The decoded token payload will appear in the backend logs.
3. Verify that the `email`, `sub`, and `groups` claims are present and correct.
4. Disable debug logging after troubleshooting (`SSO_DEBUG=false`).

Alternatively, use Okta's **Token Preview** feature in the Admin Console to see what claims will be included in the token for a specific user.

## SAML Trace Analysis

If using the SAML protocol instead of OIDC, install the SAML-tracer browser extension to capture the SAML request and response. Key things to verify:

- The Assertion Consumer Service URL matches the Nimbus ACS endpoint.
- The NameID format is `emailAddress`.
- The assertion is signed and the signature is valid.
- Required attributes (email, firstName, lastName) are present.

## Support Escalation

If the issue cannot be resolved using this guide, gather the following before contacting Nimbus support:

- Nimbus backend logs from the failed login attempt (filter by `requestId`).
- Okta System Log entries for the same timeframe.
- Screenshot of the Okta application configuration.
- The Nimbus workspace ID and the affected user's email address.

## See Also

- [Okta Setup](./setup.md) - Initial configuration guide
- [App Registration](./config/app-registration.md) - Client ID/secret configuration
- [MFA Policies](./config/mfa-policies.md) - MFA-related login failures

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New error scenarios are discovered or Okta error messages change -->
