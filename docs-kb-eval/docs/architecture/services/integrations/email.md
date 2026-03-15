# Email Integration

The email integration enables bi-directional communication between Nimbus and email clients. Users can create tasks by sending emails, reply to task notifications to add comments, and configure email forwarding rules for automated task creation.

## Inbound Email Processing

Nimbus receives inbound emails through a SendGrid Inbound Parse webhook. When an email arrives at a designated address (e.g., `tasks@workspace.nimbus.app`), SendGrid forwards the parsed email content to the Nimbus API.

### Creating Tasks from Email

Emails sent to the workspace's inbound address are converted to tasks:

| Email Field | Task Field   | Notes                                          |
|-------------|-------------|------------------------------------------------|
| Subject     | Title       | Prefixes like "Re:" and "Fwd:" are stripped     |
| Body        | Description | HTML is converted to Markdown, signatures removed|
| From        | Reporter    | Matched to a Nimbus user by email address       |
| Attachments | Attachments | Uploaded to S3 and linked to the task           |
| CC          | Watchers    | CC'd users are added as task watchers           |

The target project is determined by the email sub-address. For example, `tasks+alpha@workspace.nimbus.app` creates a task in the "Alpha" project.

## Reply-by-Email for Comments

When Nimbus sends a notification email about a task (e.g., a new comment), the `Reply-To` header contains a unique address that maps back to the task:

```
Reply-To: reply+tsk_abc123+comment@nimbus.app
```

When the user replies, the inbound parser extracts the task ID from the address, strips the quoted reply content, and adds the new text as a comment on the task.

## Email Forwarding Rules

Workspace admins can configure forwarding rules that automatically create tasks from emails matching specific criteria:

| Rule Condition          | Example                            |
|------------------------|------------------------------------|
| From address matches   | `support@customer.com`             |
| Subject contains       | `[BUG]` or `[FEATURE]`            |
| Forwarding address     | `bugs+alpha@workspace.nimbus.app`  |

Rules are evaluated in priority order, and the first matching rule determines the target project and initial task labels.

## Security

- Inbound emails are verified using DKIM and SPF checks. Emails failing verification are rejected.
- Reply-to addresses include an HMAC signature that prevents forged replies from being accepted.
- Email content is sanitized to remove potentially dangerous HTML before storing as Markdown.

## Rate Limiting

Inbound email processing is rate-limited to 100 emails per hour per workspace to prevent abuse. Emails exceeding the limit are queued and processed in the next window.

## See Also

- [Notifications](../notifications.md) - Outbound email notification delivery
- [File Storage](../file-storage.md) - Attachment handling from emails
- [Scheduler](../scheduler.md) - Email queue processing

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Email provider changes or new forwarding rule conditions are added -->
