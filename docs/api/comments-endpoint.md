# Comments Endpoint

The Comments API supports threaded discussions on tasks and other resources. Comments support @mentions, emoji reactions, rich text formatting, and edit history.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/tasks/{task_id}/comments` | List comments on a task |
| POST | `/v1/tasks/{task_id}/comments` | Add a comment to a task |
| GET | `/v1/comments/{id}` | Get a specific comment |
| PATCH | `/v1/comments/{id}` | Edit a comment |
| DELETE | `/v1/comments/{id}` | Delete a comment |
| GET | `/v1/comments/{id}/replies` | List replies to a comment |

## Creating a Comment

```json
POST /v1/tasks/task_42/comments
{
  "body": "The design looks great! @user_05 can you review the color palette?",
  "format": "markdown"
}
```

## Threaded Comments

Comments support one level of threading. Reply to a comment by specifying `parent_comment_id`:

```json
POST /v1/tasks/task_42/comments
{
  "body": "Sure, I will review it today.",
  "parent_comment_id": "comment_100"
}
```

Replies are returned with their parent comment. The parent includes a `reply_count` field.

## @Mentions

Mention users with `@user_id` or `@display_name` syntax in the comment body. Mentioned users receive a notification. The API resolves mentions and returns structured mention data:

```json
{
  "data": {
    "id": "comment_101",
    "body": "The design looks great! @user_05 can you review?",
    "mentions": [
      { "user_id": "user_05", "display_name": "Jane Chen", "offset": 28, "length": 8 }
    ]
  }
}
```

## Reactions

Add emoji reactions to comments via the Reactions endpoint. Each comment includes a `reactions_summary`:

```json
{
  "reactions_summary": [
    { "emoji": "thumbsup", "count": 3 },
    { "emoji": "heart", "count": 1 }
  ]
}
```

## Rich Text

Comments support Markdown formatting including headings, lists, code blocks, links, and inline images. The `format` field indicates the format: `markdown` (default) or `plain`.

## Edit History

Edited comments retain their history. The `edited_at` field is set on modification, and the full edit history is available:

```
GET /v1/comments/comment_101/history
```

Returns an array of previous versions with timestamps and author information.

## Permissions

Users can edit and delete their own comments. Users with `comments:delete_any` permission can delete any comment. Workspace admins can always delete comments.

## See Also

- [Tasks Endpoint](tasks-endpoint.md) — the parent resource for comments
- [Reactions Endpoint](reactions-endpoint.md) — emoji reactions on comments
- [Notifications Endpoint](notifications-endpoint.md) — mention notifications
- [Attachments Endpoint](attachments-endpoint.md) — inline file references

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: threading model, mention resolution, or rich text support changes -->
