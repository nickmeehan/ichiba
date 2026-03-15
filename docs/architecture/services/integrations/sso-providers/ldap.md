# LDAP Integration

This document covers integrating an LDAP directory (Active Directory, OpenLDAP, or similar) with Nimbus for user authentication and group synchronization. LDAP integration is available on the Enterprise tier.

## Directory Sync

Nimbus connects to the LDAP directory to synchronize users and groups. The sync process runs on a configurable schedule (default: every 4 hours) and can also be triggered manually from the SSO settings page.

During sync, Nimbus:

1. Queries the directory for users matching the configured search filter.
2. Creates or updates Nimbus user records based on the LDAP attributes.
3. Queries group memberships and updates Nimbus role assignments accordingly.
4. Disables Nimbus accounts for users no longer found in the directory.

## Bind Configuration

Nimbus connects to the LDAP server using a service account (bind DN):

| Setting          | Description                               | Example                                  |
|-----------------|-------------------------------------------|------------------------------------------|
| `ldap_url`      | LDAP server URL                           | `ldaps://ldap.company.com:636`           |
| `bind_dn`       | Service account distinguished name        | `cn=nimbus-svc,ou=services,dc=company,dc=com` |
| `bind_password` | Service account password                  | Stored encrypted in Secrets Manager      |
| `base_dn`       | Base DN for user searches                 | `ou=employees,dc=company,dc=com`         |
| `tls_enabled`   | Require TLS (LDAPS or StartTLS)           | `true` (strongly recommended)            |

The bind password is stored encrypted using the same AES-256-GCM scheme used for OAuth tokens.

## Search Filters

User and group searches use configurable LDAP filters:

**User filter** (default):
```
(&(objectClass=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
```
This finds all active person objects, excluding disabled accounts in Active Directory.

**Group filter** (default):
```
(&(objectClass=group)(cn=Nimbus-*))
```
This finds groups whose common name starts with "Nimbus-" to avoid importing unrelated groups.

Both filters can be customized in the Nimbus SSO settings.

## Group Mapping

LDAP groups are mapped to Nimbus roles through a configuration table:

| LDAP Group DN                                      | Nimbus Role |
|---------------------------------------------------|-------------|
| `cn=Nimbus-Admins,ou=groups,dc=company,dc=com`    | Admin       |
| `cn=Nimbus-Members,ou=groups,dc=company,dc=com`   | Member      |
| `cn=Nimbus-ReadOnly,ou=groups,dc=company,dc=com`  | Guest       |

Users who belong to multiple mapped groups receive the highest-privilege role.

## Connection Pooling

To avoid creating a new LDAP connection for every sync or authentication attempt, Nimbus maintains a connection pool:

- **Pool size**: 5 connections (configurable)
- **Idle timeout**: 5 minutes
- **Max lifetime**: 30 minutes (forces reconnection to pick up server-side changes)

Connections are validated with a simple bind before use. Stale connections are evicted and replaced.

## Authentication Flow

When LDAP authentication is enabled, user login follows this path:

1. User enters email and password in Nimbus.
2. Nimbus looks up the user's DN by searching for the email attribute.
3. Nimbus attempts an LDAP bind with the user's DN and password.
4. If the bind succeeds, Nimbus issues a JWT and creates a session.
5. If the bind fails, the user receives an authentication error.

## See Also

- [Azure AD SSO](./azure-ad.md) - Cloud-based alternative to on-premises LDAP
- [Auth Service](../../auth.md) - JWT issuance after LDAP authentication
- [Secrets Management](../../../infrastructure/secrets.md) - Bind password storage

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: LDAP library is updated or new directory server types are tested -->
