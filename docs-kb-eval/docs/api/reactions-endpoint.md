# Reactions Endpoint

The Reactions API manages emoji reactions on comments and other reactable resources. Reactions follow toggle semantics and provide aggregated counts.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/comments/{comment_id}/reactions` | Add or toggle a reaction |
| DELETE | `/v1/comments/{comment_id}/reactions/{emoji}` | Remove a reaction |
| GET | `/v1/comments/{comment_id}/reactions` | List all reactions |
| GET | `/v1/comments/{comment_id}/reactions/{emoji}/users` | List users who reacted with a specific emoji |

## Adding a Reaction

```json
POST /v1/comments/comment_101/reactions
{
  "emoji": "thumbsup"
}
```

Response:

```json
{
  "data": {
    "emoji": "thumbsup",
    "user_id": "user_05",
    "created_at": "2026-03-15T10:30:00Z"
  }
}
```

## Toggle Semantics

Reactions use toggle behavior. If a user posts the same emoji reaction twice, the second request removes the reaction. The response indicates the resulting state:

```json
{
  "data": {
    "emoji": "thumbsup",
    "action": "removed"
  }
}
```

Alternatively, use the DELETE endpoint to explicitly remove a reaction.

## Reaction Counts

Aggregated reaction counts are included in the parent comment response:

```json
{
  "reactions_summary": [
    { "emoji": "thumbsup", "count": 5, "user_reacted": true },
    { "emoji": "heart", "count": 2, "user_reacted": false },
    { "emoji": "rocket", "count": 1, "user_reacted": false }
  ]
}
```

The `user_reacted` field indicates whether the authenticated user has added this reaction.

## Listing Users per Reaction

```
GET /v1/comments/comment_101/reactions/thumbsup/users
```

Returns a paginated list of users who reacted with the specified emoji, sorted by reaction time.

## Supported Emojis

Nimbus supports a curated set of emoji codes: `thumbsup`, `thumbsdown`, `heart`, `rocket`, `eyes`, `tada`, `thinking`, `laughing`, `confused`, `fire`, `100`, `check`. Custom emojis are not supported.

## Rate Limiting

Reaction endpoints have a per-user limit of 30 reactions per minute to prevent abuse.

## Reactable Resources

While comments are the primary reactable resource, reactions are also supported on:

- Task descriptions (via `/v1/tasks/{task_id}/reactions`)
- Updates/status posts (via `/v1/updates/{update_id}/reactions`)

## See Also

- [Comments Endpoint](comments-endpoint.md) — comments that reactions attach to
- [Notifications Endpoint](notifications-endpoint.md) — reaction notifications
- [Tasks Endpoint](tasks-endpoint.md) — task-level reactions
- [Rate Limits](rate-limits.md) — reaction rate limits

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: supported emojis, toggle behavior, or reactable resource types change -->
