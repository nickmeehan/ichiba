# Inbound Webhooks

Nimbus can receive inbound webhooks from external services to trigger actions within the platform. This document covers payload validation, signature verification, and event processing.

## Webhook Endpoint

Register inbound webhook URLs in workspace settings. Each webhook gets a unique endpoint:

```
POST https://api.nimbus.io/v1/webhooks/inbound/{webhook_id}
```

The `webhook_id` is generated when you create the webhook configuration.

## Payload Validation

Inbound payloads must be valid JSON with a `Content-Type: application/json` header. The maximum payload size is 1 MB. Payloads exceeding this limit receive a `413 Payload Too Large` response.

Required fields in the payload:

```json
{
  "event_type": "issue.created",
  "timestamp": "2026-03-15T10:30:00Z",
  "data": { ... }
}
```

If `event_type` is missing or unrecognized, Nimbus returns a 400 error but still logs the attempt for debugging.

## Signature Verification

Each webhook configuration includes a signing secret. Nimbus expects inbound webhooks to include a signature header for verification:

```
X-Webhook-Signature: sha256=abc123def456...
```

The signature is computed as `HMAC-SHA256(signing_secret, raw_request_body)`. Nimbus verifies the signature before processing the payload. Failed verification returns `401 Unauthorized`.

## Idempotency Keys

Include an `X-Idempotency-Key` header to prevent duplicate processing:

```
X-Idempotency-Key: evt_unique_123
```

Nimbus stores processed idempotency keys for 24 hours. Duplicate keys within that window receive a `200 OK` response without reprocessing.

## Event Processing

Validated webhooks are placed in a processing queue. Processing is asynchronous — the endpoint returns `202 Accepted` immediately. Processing status can be queried:

```
GET /v1/webhooks/inbound/{webhook_id}/events/{event_id}
```

## Retry Policy

If the external service expects acknowledgment, Nimbus sends responses within 5 seconds. For outgoing webhook retries (when Nimbus is the sender), see the automations documentation.

## Supported Integrations

Pre-built inbound webhook handlers exist for GitHub, GitLab, Slack, Jira, and Zendesk. Custom integrations use the generic webhook endpoint with configurable field mapping.

## See Also

- [Automations Endpoint](automations-endpoint.md) — trigger automations from webhook events
- [Idempotency](idempotency.md) — idempotency key mechanics
- [Authentication](authentication.md) — webhook auth context
- [Imports Endpoint](imports-endpoint.md) — bulk data import alternative

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: webhook signature algorithm, payload limits, or supported integrations change -->
