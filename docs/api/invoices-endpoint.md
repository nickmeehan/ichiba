# Invoices Endpoint

The Invoices API provides access to billing invoices, PDF generation, and payment status tracking. Invoices are generated automatically at the end of each billing cycle.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/invoices` | List invoices |
| GET | `/v1/invoices/{id}` | Get invoice details |
| GET | `/v1/invoices/{id}/pdf` | Download invoice as PDF |
| POST | `/v1/invoices/{id}/pay` | Retry payment on a failed invoice |
| POST | `/v1/invoices/{id}/refund` | Request a refund |

## Listing Invoices

```
GET /v1/invoices?filter[status]=paid&filter[date.gte]=2026-01-01&sort=-date
```

Response:

```json
{
  "data": [
    {
      "id": "inv_2026_03",
      "date": "2026-03-01",
      "due_date": "2026-03-15",
      "status": "paid",
      "amount": 99.00,
      "currency": "USD",
      "line_items": [
        { "description": "Pro Plan - March 2026", "amount": 99.00 }
      ],
      "payment_method": { "type": "card", "last_four": "4242" },
      "paid_at": "2026-03-01T00:05:00Z"
    }
  ]
}
```

## Invoice Statuses

| Status | Description |
|--------|-------------|
| `draft` | Invoice being prepared (not yet finalized) |
| `open` | Finalized and awaiting payment |
| `paid` | Payment received |
| `past_due` | Payment failed or not received by due date |
| `void` | Invoice cancelled |
| `refunded` | Full refund issued |
| `partially_refunded` | Partial refund issued |

## PDF Generation

Download a formatted PDF invoice:

```
GET /v1/invoices/inv_2026_03/pdf
```

Returns a redirect to a signed PDF download URL. PDFs include workspace details, line items, tax information, and payment details.

## Payment Status

For past-due invoices, retry payment with the default payment method:

```
POST /v1/invoices/inv_2026_03/pay
```

If the default payment method fails, specify an alternative:

```json
POST /v1/invoices/inv_2026_03/pay
{
  "payment_method_id": "pm_backup_card"
}
```

## Refunds

Request a refund for a paid invoice:

```json
POST /v1/invoices/inv_2026_03/refund
{
  "amount": 49.50,
  "reason": "Downgraded mid-cycle"
}
```

Partial refunds are supported. Refunds are processed within 5-10 business days.

## Invoice Webhooks

Automated notifications are sent for invoice events:
- `invoice.created` — new invoice generated
- `invoice.paid` — payment succeeded
- `invoice.payment_failed` — payment attempt failed
- `invoice.past_due` — invoice is overdue

## See Also

- [Billing Endpoint](billing-endpoint.md) — subscription and payment management
- [Subscriptions Endpoint](subscriptions-endpoint.md) — plan details
- [Content Negotiation](content-negotiation.md) — PDF content type
- [Audit Endpoint](audit-endpoint.md) — billing audit trail

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: invoice statuses, PDF format, or refund policy changes -->
