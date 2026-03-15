# GitHub Integration

The GitHub integration links Nimbus tasks to GitHub pull requests and commits, enabling automatic status updates and bi-directional traceability between code changes and project management.

## Setup

A workspace admin installs the Nimbus GitHub App on their GitHub organization. The app requests the following permissions:

- **Pull requests**: Read and write (to post status checks and comments)
- **Contents**: Read (to detect task references in commits)
- **Webhooks**: Receive events for PR and push activity

The installation is linked to a Nimbus workspace, and individual repositories are mapped to Nimbus projects through the integration settings page.

## PR Linking

Developers reference Nimbus tasks in PR titles or descriptions using the format `NIM-{taskId}`:

```
feat: implement user avatar upload (NIM-1234)
```

When a PR is opened or updated, the GitHub webhook handler parses the title and body for task references. Matched tasks display a link to the PR in the Nimbus task detail view, and a status check is posted on the PR showing the linked task's current status.

## Commit References

Commit messages can also reference tasks using the same `NIM-{taskId}` pattern. The integration records commit references on the task timeline, showing the commit hash, message, and author.

## Status Checks

The Nimbus GitHub App posts a commit status check on linked PRs:

| Task Status   | Check Status | Description                    |
|--------------|-------------|--------------------------------|
| Open         | pending     | "Task NIM-1234 is open"        |
| In Progress  | pending     | "Task NIM-1234 is in progress" |
| In Review    | pending     | "Task NIM-1234 is in review"   |
| Done         | success     | "Task NIM-1234 is complete"    |

Teams can optionally require the Nimbus status check to pass (task must be Done) before merging.

## Auto-Close on Merge

When a PR is merged and its description contains `closes NIM-{taskId}` or `fixes NIM-{taskId}`, the integration automatically moves the referenced task to the Done column. This mirrors GitHub's native issue-closing syntax.

## Repository Webhooks

The integration listens for the following GitHub webhook events:

- `pull_request.opened` - Scan for task references, post status check
- `pull_request.synchronize` - Update status check
- `pull_request.closed` - Auto-close tasks if merged with closing keywords
- `push` - Scan commit messages for task references

Webhook payloads are verified using the webhook secret configured during GitHub App installation.

## See Also

- [Slack Integration](./slack.md) - Complementary notification channel
- [Outbound Webhooks](./webhooks-outbound.md) - Custom webhook delivery
- [Event-Driven Architecture](../../event-driven.md) - Events emitted by the GitHub handler

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: GitHub App permissions change or new webhook events are handled -->
