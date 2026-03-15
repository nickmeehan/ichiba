# Subscriptions Endpoint

The Subscriptions API provides detailed plan information, feature flag access, and trial management. It complements the Billing API with plan-specific data.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/subscriptions/current` | Get current subscription details |
| GET | `/v1/subscriptions/plans` | List available plans |
| GET | `/v1/subscriptions/plans/{plan_id}` | Get plan details |
| POST | `/v1/subscriptions/upgrade` | Upgrade to a higher plan |
| POST | `/v1/subscriptions/downgrade` | Downgrade to a lower plan |
| GET | `/v1/subscriptions/features` | List features for current plan |
| POST | `/v1/subscriptions/trial` | Start a trial of a higher plan |

## Available Plans

```
GET /v1/subscriptions/plans
```

```json
{
  "data": [
    { "id": "free", "name": "Free", "price_monthly": 0, "seats_included": 3 },
    { "id": "pro", "name": "Pro", "price_monthly": 9.99, "seats_included": 10 },
    { "id": "business", "name": "Business", "price_monthly": 24.99, "seats_included": 50 },
    { "id": "enterprise", "name": "Enterprise", "price_monthly": null, "seats_included": null, "contact_sales": true }
  ]
}
```

## Upgrade and Downgrade

Upgrade takes effect immediately:

```json
POST /v1/subscriptions/upgrade
{
  "plan_id": "business",
  "billing_cycle": "annual"
}
```

Downgrade takes effect at the end of the billing period:

```json
POST /v1/subscriptions/downgrade
{
  "plan_id": "pro",
  "effective_date": "end_of_period"
}
```

When downgrading, the API validates that current usage fits within the lower plan's limits. If it does not, the response lists the items that must be addressed before downgrading.

## Trial Management

Start a 14-day trial of a higher plan:

```json
POST /v1/subscriptions/trial
{
  "plan_id": "business"
}
```

During a trial, all features of the trial plan are available. If the trial is not converted to a paid subscription, the workspace reverts to its previous plan. Only one trial per plan is allowed.

## Feature Flags

Check which features are available on the current plan:

```
GET /v1/subscriptions/features
```

```json
{
  "data": {
    "custom_fields": true,
    "automations": true,
    "time_tracking": true,
    "advanced_reports": false,
    "sso": false,
    "audit_log_extended": false,
    "api_rate_limit_tier": "pro",
    "max_file_size_mb": 100
  }
}
```

Use feature flags to conditionally display UI elements and gate API access.

## Plan Comparison

```
GET /v1/subscriptions/plans/compare?plans=pro,business
```

Returns a side-by-side feature comparison matrix.

## See Also

- [Billing Endpoint](billing-endpoint.md) — payment and usage
- [Invoices Endpoint](invoices-endpoint.md) — billing history
- [Admin Endpoint](admin-endpoint.md) — workspace plan management
- [Rate Limits](rate-limits.md) — rate limits by plan tier

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: available plans, feature flags, or trial policy changes -->
