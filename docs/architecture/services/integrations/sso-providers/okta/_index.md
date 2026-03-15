# Okta SSO

This section covers the Okta integration for Nimbus, including SSO setup, SCIM user provisioning, and troubleshooting common configuration issues. Okta is the most commonly used identity provider among Nimbus Enterprise customers.

## Contents

### [Setup](./setup.md)
When you are configuring Okta SSO for the first time, need to set up redirect URIs, or configure group claims for role mapping.

### [SCIM Provisioning](./scim.md)
When you need to enable automatic user provisioning and deprovisioning from Okta, or configure group push to sync Okta groups with Nimbus roles.

### [Troubleshooting](./troubleshooting.md)
When you are debugging SSO login failures, token validation errors, or mismatched redirect URIs between Okta and Nimbus.

### [Configuration](./config/_index.md)
When you need step-by-step guides for specific Okta configuration tasks like app registration, attribute mapping, or MFA policies.

## Overview

The Okta integration supports two protocols:

- **OIDC** (recommended): OpenID Connect for authentication, providing a simpler setup and JWT-based token flow.
- **SAML 2.0**: For organizations that require SAML or have existing SAML policies.

Both protocols support group-based role mapping, just-in-time user provisioning, and single logout.

## See Also

- [Azure AD SSO](../azure-ad.md) - Alternative enterprise identity provider
- [Generic SAML](../saml-generic.md) - SAML protocol details shared with Okta SAML mode
- [Auth Service](../../../auth.md) - How SSO integrates with the Nimbus auth layer

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Okta API versions change or new provisioning features are supported -->
