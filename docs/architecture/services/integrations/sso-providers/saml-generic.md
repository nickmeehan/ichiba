# Generic SAML

This document covers configuring a SAML 2.0 identity provider with Nimbus for enterprise single sign-on. This guide applies to any SAML-compliant IdP that is not covered by a provider-specific integration.

## SP Metadata

Nimbus exposes its SAML Service Provider metadata at:

```
https://{workspace}.nimbus.app/api/auth/sso/saml/metadata
```

This XML document contains the SP entity ID, assertion consumer service (ACS) URL, and the SP's signing certificate. Most identity providers can import this URL directly to auto-configure the SAML integration.

Key SP metadata values:

| Field                    | Value                                                        |
|-------------------------|--------------------------------------------------------------|
| Entity ID               | `https://{workspace}.nimbus.app/saml`                       |
| ACS URL                 | `https://{workspace}.nimbus.app/api/auth/sso/saml/acs`     |
| SLO URL                 | `https://{workspace}.nimbus.app/api/auth/sso/saml/slo`     |
| NameID Format           | `urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress`   |

## IdP Configuration

On the identity provider side, configure the following:

1. Create a new SAML application with the SP metadata above.
2. Set the NameID to the user's email address.
3. Configure attribute statements to include the required user attributes.
4. Download or copy the IdP metadata XML.
5. Upload the IdP metadata to the Nimbus SSO settings page.

## Attribute Mapping

Nimbus expects the following SAML attributes in the assertion:

| SAML Attribute                           | Nimbus Field    | Required |
|-----------------------------------------|-----------------|----------|
| `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` | Email  | Yes      |
| `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname`    | First Name | Yes  |
| `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname`      | Last Name  | Yes  |
| `memberOf` or `groups`                   | Role (mapped)   | No       |

Custom attribute URIs can be configured in the Nimbus SSO settings if the IdP uses non-standard attribute names.

## Signed Assertions

Nimbus requires that SAML assertions are signed by the IdP. Both the assertion signature and the response signature are verified against the IdP's signing certificate provided in the metadata. Unsigned assertions are rejected with a `SAML_SIGNATURE_INVALID` error.

The SP can optionally sign authentication requests. This is disabled by default but can be enabled in the SSO settings for IdPs that require signed requests.

## Single Logout (SLO)

Nimbus supports SAML Single Logout via both HTTP-Redirect and HTTP-POST bindings. When a user logs out of Nimbus, a LogoutRequest is sent to the IdP's SLO endpoint. Conversely, when the IdP initiates a logout, Nimbus processes the LogoutRequest and terminates the user's session.

SLO is optional and can be disabled if the IdP does not support it.

## See Also

- [Okta SSO](./okta/_index.md) - Okta-specific SAML/OIDC setup
- [Azure AD SSO](./azure-ad.md) - Azure AD OIDC integration
- [Auth Service](../../auth.md) - Session management after SAML login

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: SAML library is updated or new attribute mappings are required -->
