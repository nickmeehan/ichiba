# Okta Attribute Mapping

This guide covers how Okta user profile attributes are mapped to Nimbus user fields during SSO authentication and SCIM provisioning. Correct attribute mapping ensures that user profiles are complete and role assignments are accurate.

## Standard Attribute Mapping

The following Okta profile attributes map to Nimbus user fields by default:

| Okta Attribute    | Nimbus Field     | OIDC Claim   | SCIM Attribute            | Required |
|-------------------|-----------------|--------------|---------------------------|----------|
| `login`           | Email           | `email`      | `userName`                | Yes      |
| `firstName`       | First Name      | `given_name` | `name.givenName`          | Yes      |
| `lastName`        | Last Name       | `family_name`| `name.familyName`         | Yes      |
| `displayName`     | Display Name    | `name`       | `displayName`             | No       |
| `profileUrl`      | Avatar URL      | `picture`    | `photos[0].value`         | No       |
| `department`      | Department      | -            | `urn:nimbus:department`   | No       |
| `title`           | Job Title       | -            | `title`                   | No       |

## Custom Attributes

Organizations can define custom Okta profile attributes and map them to Nimbus custom user fields. Custom attributes are configured in Okta under **Directory > Profile Editor > Nimbus**.

To add a custom attribute:

1. In the Okta Profile Editor, click **Add Attribute**.
2. Define the attribute (e.g., `nimbusTeam`, type: String).
3. In Nimbus SSO settings, add a custom mapping: `nimbusTeam` -> Custom Field "Team".

Custom attributes flow through SCIM provisioning. For OIDC, custom attributes must be added as claims in the Okta authorization server.

## Expression Language

Okta supports expression language for transforming attribute values before they reach Nimbus. Common expressions:

| Expression                                          | Result                          |
|----------------------------------------------------|---------------------------------|
| `String.toLowerCase(user.email)`                   | Normalizes email to lowercase   |
| `String.substringBefore(user.email, "@")`          | Extracts username from email    |
| `user.firstName + " " + user.lastName`             | Builds full display name        |
| `Arrays.contains(user.groups, "Nimbus-Admins") ? "admin" : "member"` | Derives role from group |

Expressions are configured in the Okta Profile Editor or in the application's attribute mapping section.

## Default Values

When an Okta attribute is empty or not mapped, Nimbus applies default values:

| Nimbus Field   | Default Value                    |
|---------------|----------------------------------|
| Display Name  | `{firstName} {lastName}`         |
| Avatar URL    | Generated Gravatar URL from email|
| Department    | Empty (not displayed)            |
| Job Title     | Empty (not displayed)            |
| Timezone      | Workspace default timezone       |

## Attribute Sync Behavior

Attributes are synced at two points:

- **Login**: Every time a user authenticates via SSO, their OIDC claims update the Nimbus profile. This ensures profile changes in Okta are reflected immediately.
- **SCIM Push**: When SCIM provisioning is enabled, profile updates in Okta trigger an immediate SCIM PATCH request to Nimbus, updating the profile without requiring a login.

If both OIDC and SCIM update the same attribute, the most recent update wins.

## See Also

- [SCIM Provisioning](../scim.md) - SCIM-based attribute sync
- [App Registration](./app-registration.md) - Custom claims configuration
- [Auth Service](../../../../auth.md) - Profile storage after mapping

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New mappable attributes are added or Okta expression language changes -->
