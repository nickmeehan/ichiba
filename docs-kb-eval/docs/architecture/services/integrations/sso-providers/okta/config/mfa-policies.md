# Okta MFA Policies

This guide covers configuring multi-factor authentication policies in Okta for the Nimbus application. MFA policies are managed entirely in Okta; Nimbus relies on Okta to enforce MFA before issuing authentication tokens.

## Factor Enrollment

Before users can authenticate with MFA, they must enroll in at least one factor. Configure factor enrollment in the Okta Admin Console:

1. Navigate to **Security > Multifactor**.
2. Enable the desired factors:

| Factor              | Type      | Recommended | Notes                               |
|--------------------|-----------|-----------  |--------------------------------------|
| Okta Verify        | Push      | Yes         | Most user-friendly, supports push    |
| Google Authenticator| TOTP     | Yes         | Widely supported fallback            |
| SMS                | OTP       | No          | Vulnerable to SIM swapping           |
| Email              | OTP       | No          | Adds latency, use as last resort     |
| WebAuthn/FIDO2     | Biometric | Yes         | Strongest security, hardware keys    |
| Security Question  | Knowledge | No          | Weak factor, not recommended         |

3. Under **Factor Enrollment**, create or edit a policy to set which factors are required, optional, or disabled for the Nimbus user group.

## Sign-On Policies

Sign-on policies determine when MFA is prompted during the Nimbus login flow:

1. Navigate to **Security > Authentication Policies**.
2. Create a new policy or edit the default policy.
3. Add a rule for the Nimbus application:

| Setting                        | Recommended Value                         |
|-------------------------------|-------------------------------------------|
| User must authenticate with   | Password + Another factor                 |
| Re-authentication frequency   | Every sign-in, or Every 12 hours          |
| Session lifetime              | 8 hours (aligns with a work day)          |

## App-Level MFA Requirements

For stricter security, Okta supports app-level MFA rules that apply specifically when accessing Nimbus:

1. In the Nimbus application settings, go to **Sign On > Sign On Policy**.
2. Add a rule requiring MFA for all users accessing Nimbus.
3. Configure conditions:
   - **Network zone**: Require MFA outside the corporate network, skip on internal network.
   - **Device trust**: Skip MFA on managed devices, require on unknown devices.
   - **Risk level**: Always require MFA when Okta detects elevated risk.

These conditions allow a balance between security and user convenience.

## Fallback Factors

If a user's primary MFA factor is unavailable (e.g., they lost their phone), fallback options include:

1. **Backup codes**: Users can generate one-time backup codes in their Okta account settings. Nimbus documentation recommends all users save backup codes during enrollment.
2. **Alternative factor**: If multiple factors are enrolled, the user can select a different one on the MFA prompt screen.
3. **Admin reset**: An Okta admin can reset a user's MFA factors, requiring them to re-enroll on next login.

## Impact on Nimbus Login Flow

When MFA is enabled, the SSO login flow adds an additional step:

1. User clicks "Sign in with Okta" in Nimbus.
2. User enters Okta username and password.
3. **MFA Challenge**: User is prompted for their second factor.
4. Upon successful MFA, Okta issues the OIDC tokens.
5. Nimbus processes the tokens and creates the session.

The MFA step is entirely within Okta's domain. Nimbus receives tokens only after MFA is successfully completed, so no changes to the Nimbus backend are required to support MFA.

## See Also

- [App Registration](./app-registration.md) - Application-level sign-on policies
- [Troubleshooting](../troubleshooting.md) - MFA-related login failures
- [Auth Service](../../../../auth.md) - Session creation after MFA

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Okta MFA options change or new factor types are supported -->
