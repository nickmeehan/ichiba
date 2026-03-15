# Okta SCIM Provisioning

This document covers setting up SCIM (System for Cross-domain Identity Management) provisioning between Okta and Nimbus. SCIM enables automatic user provisioning, deprovisioning, and group synchronization.

## Overview

With SCIM provisioning enabled, changes in Okta are automatically reflected in Nimbus:

| Okta Action                  | Nimbus Result                                |
|-----------------------------|----------------------------------------------|
| Assign user to Nimbus app   | User account created, invitation email sent  |
| Unassign user from Nimbus   | User account deactivated, sessions revoked   |
| Update user profile in Okta | User profile updated in Nimbus               |
| Push group to Nimbus        | Group created/updated, role mappings applied |
| Suspend user in Okta        | User account deactivated in Nimbus           |

## SCIM Endpoint Configuration

In the Okta Admin Console, configure the SCIM connector for the Nimbus application:

1. Navigate to **Applications > Nimbus > Provisioning > Integration**.
2. Enable the SCIM connector and enter:
   - **SCIM connector base URL**: `https://{workspace}.nimbus.app/api/scim/v2`
   - **Unique identifier field**: `email`
   - **Supported provisioning actions**: Push New Users, Push Profile Updates, Push Groups
   - **Authentication Mode**: HTTP Header
   - **Authorization**: Bearer token (generated in Nimbus workspace settings)

3. Click **Test Connector Configuration** to verify connectivity.

## User Provisioning

When a user is assigned to the Nimbus application in Okta, the SCIM endpoint receives a `POST /Users` request. Nimbus creates the user account and sends a welcome email. The user can then log in via Okta SSO without needing to set a Nimbus password.

### Attribute Mapping

See the [Attribute Mapping](./config/attribute-mapping.md) guide for the full list of SCIM attributes mapped to Nimbus user fields.

## User Deprovisioning

When a user is unassigned from the Nimbus app or suspended in Okta, the SCIM endpoint receives a `PATCH /Users/{id}` request setting `active` to `false`. Nimbus deactivates the account, revokes all active sessions, and removes the user from project assignments. The user's data (tasks, comments) is retained for audit purposes.

## Group Push

Okta's Group Push feature synchronizes Okta groups with Nimbus:

1. In the Okta Admin Console, go to **Applications > Nimbus > Push Groups**.
2. Select the Okta groups to push (e.g., `Nimbus-Admins`, `Nimbus-Members`).
3. Okta sends `POST /Groups` or `PATCH /Groups/{id}` requests to Nimbus.

Nimbus maps pushed groups to workspace roles using the same group-to-role mapping configured in the SSO settings.

## SCIM Endpoint Implementation

The Nimbus SCIM endpoint implements the SCIM 2.0 protocol (RFC 7644):

| Endpoint                | Method | Purpose                  |
|------------------------|--------|--------------------------|
| `/scim/v2/Users`       | GET    | List/search users         |
| `/scim/v2/Users`       | POST   | Create user               |
| `/scim/v2/Users/{id}`  | GET    | Get user by ID            |
| `/scim/v2/Users/{id}`  | PATCH  | Update user               |
| `/scim/v2/Users/{id}`  | DELETE | Deactivate user           |
| `/scim/v2/Groups`      | GET    | List groups               |
| `/scim/v2/Groups`      | POST   | Create group              |
| `/scim/v2/Groups/{id}` | PATCH  | Update group membership   |

## See Also

- [Okta Setup](./setup.md) - SSO configuration prerequisite
- [Attribute Mapping](./config/attribute-mapping.md) - SCIM attribute details
- [Auth Service](../../../auth.md) - Session revocation on deprovisioning

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: SCIM endpoint implementation changes or Okta SCIM version updates -->
