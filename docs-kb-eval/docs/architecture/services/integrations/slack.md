# Slack Integration

The Slack integration connects Nimbus workspaces to Slack channels, enabling slash commands for quick task management and automated notifications when task statuses change.

## Bot Setup

The integration uses a Slack App with bot token scopes. Workspace admins install the Nimbus Slack App through the OAuth flow, which stores the bot token and links the Slack workspace to the Nimbus workspace.

Required bot scopes:
- `commands` - Register slash commands
- `chat:write` - Post messages to channels
- `chat:write.public` - Post to channels the bot has not been invited to
- `users:read` - Resolve Slack user IDs to email addresses for Nimbus user matching

## Slash Commands

### `/nimbus-task`
Creates a new task from Slack. Opens a modal dialog with fields for title, project, assignee, and priority.

```
/nimbus-task Fix login page redirect bug
```

If a plain text argument is provided, it pre-fills the title field in the modal.

### `/nimbus-status`
Shows the current sprint status for a linked project. Returns an ephemeral message with task counts by status column and the sprint burndown percentage.

```
/nimbus-status project:alpha
```

## Interactive Messages

When a task is created or updated from Slack, the bot posts a rich message with action buttons:

- **View in Nimbus** - Opens the task in the Nimbus web app.
- **Assign to me** - Assigns the task to the Slack user (matched by email).
- **Change status** - Opens a dropdown to move the task to a different column.

Button interactions are handled by the Slack interactivity endpoint (`/api/integrations/slack/interactions`), which verifies the Slack signing secret before processing.

## Channel Notifications

Teams can link a Slack channel to a Nimbus project. When configured, the bot posts messages for:

| Event                  | Message Format                                           |
|-----------------------|----------------------------------------------------------|
| Task created          | "{user} created task **{title}** in {project}"          |
| Task completed        | "{user} completed **{title}**"                           |
| Sprint started        | "Sprint **{name}** has started with {n} tasks"           |
| Sprint completed      | "Sprint **{name}** completed: {done}/{total} tasks done" |

Notification frequency can be set to immediate, hourly digest, or daily digest per channel.

## User Mapping

Slack users are mapped to Nimbus users by email address. When a Slack user interacts with the bot, their Slack email is looked up in the Nimbus user table. Unmatched users are prompted to link their accounts.

## See Also

- [Notifications](../notifications.md) - In-app notification counterpart
- [Outbound Webhooks](./webhooks-outbound.md) - Alternative event delivery mechanism
- [Auth Service](../auth.md) - User identity resolution

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Slack API changes or new slash commands are added -->
