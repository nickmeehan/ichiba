# GraphQL API

Nimbus provides a GraphQL API alongside the REST API for clients that benefit from flexible query shapes. The GraphQL endpoint supports queries, mutations, and subscriptions.

## Endpoint

```
POST https://api.nimbus.io/graphql
```

Authentication is the same as the REST API — include a Bearer token in the `Authorization` header.

## Schema Design

The schema is organized around the core domain types: `Project`, `Task`, `User`, `Team`, `Sprint`, `Board`, and related entities. All root types are accessible from the `Query` and `Mutation` types.

```graphql
type Query {
  project(id: ID!): Project
  projects(filter: ProjectFilter, first: Int, after: String): ProjectConnection
  task(id: ID!): Task
  me: User
}

type Mutation {
  createTask(input: CreateTaskInput!): Task
  updateTask(id: ID!, input: UpdateTaskInput!): Task
  deleteTask(id: ID!): DeleteResult
}
```

## DataLoaders

The resolver layer uses DataLoaders to batch and cache database lookups within a single request. This prevents N+1 query problems when fetching nested relationships. DataLoaders are instantiated per-request to avoid cross-request data leakage.

## Query Complexity Limits

To prevent abuse, each query is scored for complexity. The default limit is **1000 points** per query. Field complexity is calculated as:

- Scalar fields: 1 point
- Object fields: 2 points
- Connection/list fields: 5 points per item (multiplied by `first` argument)

Queries exceeding the limit return a `QUERY_TOO_COMPLEX` error with the computed score.

## Subscriptions

Subscriptions use WebSocket transport via the `graphql-ws` protocol:

```
wss://api.nimbus.io/graphql/ws
```

Available subscriptions include `taskUpdated`, `commentAdded`, `sprintProgressChanged`, and `notificationReceived`. Subscriptions are scoped to the authenticated user's visible resources.

## Introspection

Introspection is enabled in development and staging environments. In production, introspection is disabled by default but can be enabled per-workspace via admin settings.

## Error Handling

GraphQL errors follow the standard `errors` array format with extensions for Nimbus-specific error codes:

```json
{
  "errors": [{
    "message": "Task not found",
    "extensions": {
      "code": "NOT_FOUND",
      "resource": "Task",
      "id": "task_999"
    }
  }]
}
```

## See Also

- [REST Overview](rest-overview.md) — REST API conventions
- [Authentication](authentication.md) — auth for GraphQL requests
- [Realtime Subscriptions](realtime-subscriptions.md) — WebSocket protocol details
- [Rate Limits](rate-limits.md) — rate limiting applies to GraphQL too

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: GraphQL schema structure, complexity limits, or subscription transport changes -->
