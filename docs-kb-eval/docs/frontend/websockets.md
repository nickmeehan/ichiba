# WebSocket Integration

Nimbus uses Socket.io for real-time communication between the server and client. WebSocket connections power live task updates, presence indicators, notification delivery, and collaborative features like simultaneous editing of project descriptions.

## Socket.io Client Setup

The Socket.io client is initialized in `src/lib/socket.ts` and managed by the `SocketProvider` component. The connection is established after authentication and scoped to the active tenant.

```ts
const socket = io(SOCKET_URL, {
  auth: { token: accessToken },
  query: { tenantId },
  transports: ["websocket", "polling"],
  reconnectionDelay: 1000,
  reconnectionDelayMax: 30000,
  reconnectionAttempts: Infinity,
});
```

The provider exposes the socket instance via React context. Components access it through the `useSocket` hook.

## Connection Management

The socket lifecycle is tied to the authenticated session:

1. **Connect**: Socket connects when the user authenticates and the `SocketProvider` mounts.
2. **Room joining**: On connect, the client joins rooms for the active tenant (`tenant:{tenantId}`) and the user's personal channel (`user:{userId}`). When viewing a project, it joins `project:{projectId}`.
3. **Room switching**: When the user navigates to a different project, the client leaves the previous project room and joins the new one.
4. **Disconnect**: Socket disconnects on logout or when the browser tab is closed.

Connection state is tracked in a Zustand store (`useSocketStore`) with states: `connected`, `connecting`, `disconnected`, `error`. A subtle status indicator in the app header shows the connection state.

## Event Handling

Events follow a naming convention of `entity:action`:

| Event | Direction | Description |
|-------|-----------|-------------|
| `task:created` | Server to Client | New task created in current project |
| `task:updated` | Server to Client | Task fields changed (status, assignee, etc.) |
| `task:deleted` | Server to Client | Task removed |
| `comment:added` | Server to Client | New comment on a task the user is viewing |
| `presence:update` | Bidirectional | User online/offline/viewing status |
| `notification:new` | Server to Client | New notification for the user |
| `cursor:move` | Bidirectional | Collaborative cursor position |

Event handlers update the React Query cache directly to ensure the UI reflects changes immediately without a full refetch:

```tsx
useSocketEvent("task:updated", (payload: TaskUpdateEvent) => {
  queryClient.setQueryData(["tasks", payload.taskId], (old: Task) => ({
    ...old,
    ...payload.changes,
  }));
});
```

## Reconnection Strategy

Socket.io handles reconnection automatically with exponential backoff. Additional Nimbus-specific logic:

- **Missed event recovery**: On reconnect, the client sends a `sync:request` event with the timestamp of the last received event. The server responds with all events since that timestamp.
- **Cache invalidation**: If the disconnection lasted more than 60 seconds, all active React Query caches are invalidated to ensure freshness.
- **User notification**: After 5 seconds of disconnection, a toast appears: "Real-time updates paused. Reconnecting..." It auto-dismisses when the connection is restored.

## Presence

The presence system tracks which users are online and what they are currently viewing:

- Heartbeats are sent every 30 seconds to maintain presence status
- When a user opens a task detail, their avatar appears in the task's "currently viewing" indicator
- Presence data is stored in Redis on the server with a 60-second TTL

## See Also

- [Data Fetching](data-fetching.md) for how WebSocket events interact with React Query caches
- [Error Boundaries](error-boundaries.md) for handling socket connection failures
- [State Management](state-management.md) for the socket connection Zustand store

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Socket.io is upgraded or real-time architecture changes -->
