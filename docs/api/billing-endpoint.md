# Billing Endpoint

The Billing API manages workspace subscriptions, usage tracking, and payment methods. Billing operations require the `billing:manage` scope.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/billing/subscription` | Get current subscription |
| POST | `/v1/billing/subscription` | Change subscription plan |
| GET | `/v1/billing/usage` | Get current usage data |
| GET | `/v1/billing/payment-methods` | List payment methods |
| POST | `/v1/billing/payment-methods` | Add a payment method |
| DELETE | `/v1/billing/payment-methods/{id}` | Remove a payment method |
| POST | `/v1/billing/payment-methods/{id}/default` | Set default payment method |

## Current Subscription

```json
{
  "data": {
    "plan": "pro",
    "status": "active",
    "billing_cycle": "monthly",
    "current_period_start": "2026-03-01",
    "current_period_end": "2026-03-31",
    "seats": { "included": 10, "used": 7, "additional_cost_per_seat": 12.00 },
    "monthly_amount": 99.00,
    "currency": "USD"
  }
}
```

## Plan Changes

Upgrade or downgrade the subscription:

```json
POST /v1/billing/subscription
{
  "plan": "enterprise",
  "billing_cycle": "annual",
  "seats": 25
}
```

Upgrades take effect immediately with prorated billing. Downgrades take effect at the end of the current billing period.

## Usage Data

Track resource consumption against plan limits:

```json
{
  "data": {
    "seats": { "limit": 10, "used": 7 },
    "storage_gb": { "limit": 50, "used": 12.4 },
    "api_calls_monthly": { "limit": 10000, "used": 4523 },
    "projects": { "limit": 50, "used": 12 },
    "automations": { "limit": 25, "used": 8 }
  }
}
```

## Payment Methods

Add a credit card or bank account:

```json
POST /v1/billing/payment-methods
{
  "type": "card",
  "token": "tok_stripe_abc123"
}
```

Payment method tokens are generated client-side using the Stripe.js or payment provider's client SDK. Nimbus never receives raw card numbers.

## Billing History

Billing events are logged in the audit trail and accessible via the invoices endpoint. Failed payments trigger email notifications and a 14-day grace period before workspace suspension.

## Enterprise Billing

Enterprise plans support:
- Custom payment terms (net-30, net-60)
- Purchase order numbers on invoices
- Multiple billing contacts
- Volume discounts and committed-use pricing

## See Also

- [Invoices Endpoint](invoices-endpoint.md) — invoice history and downloads
- [Subscriptions Endpoint](subscriptions-endpoint.md) — plan details and features
- [Admin Endpoint](admin-endpoint.md) — workspace seat management
- [Audit Endpoint](audit-endpoint.md) — billing action audit trail

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: plan tiers, usage limits, or payment provider changes -->
