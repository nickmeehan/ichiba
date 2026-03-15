# Integrations

This section covers the third-party integrations available in the Nimbus platform. Each integration connects Nimbus to an external service for collaboration, development workflow, or identity management.

## Contents

### [Slack](./slack.md)
When you are setting up the Slack bot, adding new slash commands, or debugging channel notification delivery for task updates.

### [GitHub](./github.md)
When you need to link pull requests to tasks, configure repository webhooks, or understand how tasks auto-close on merge.

### [Jira](./jira.md)
When you are helping a customer migrate from Jira, need to understand the field mapping logic, or troubleshoot import failures.

### [Email](./email.md)
When you are working with inbound email parsing, configuring reply-by-email for comments, or setting up email forwarding rules.

### [Outbound Webhooks](./webhooks-outbound.md)
When you need to register a new webhook event type, debug delivery failures, or understand the webhook signing mechanism.

### [SSO Providers](./sso-providers/_index.md)
When you are configuring enterprise single sign-on with Okta, Azure AD, Google Workspace, or a generic SAML/LDAP provider.

### [OAuth Flows](./oauth-flows.md)
When you are implementing a new OAuth2 provider connection, debugging token exchange failures, or understanding how refresh token rotation works.

## See Also

- [Auth Service](../auth.md) - Core authentication that integrations build upon
- [Event-Driven Architecture](../../event-driven.md) - Events that trigger integration actions
- [Outbound Webhooks](./webhooks-outbound.md) - Generic event delivery to external systems

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New integrations are added or existing integration APIs change significantly -->
