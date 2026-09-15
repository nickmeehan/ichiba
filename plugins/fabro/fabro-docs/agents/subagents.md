> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Sub-agents

> Delegate subtasks to child agent sessions

An agent can spawn **sub-agents** to delegate work to independent child sessions. Each sub-agent gets its own LLM session and tool access, runs concurrently with the parent, and returns its result when finished.

<Note>
  Sub-agents are only available with the [API backend](/core-concepts/agents#api-backend-default) (the default). Agents using the [ACP backend](/core-concepts/agents#acp-backend) cannot spawn Fabro sub-agents.
</Note>

## Tools

Sub-agent management is exposed through four built-in tools:

| Tool          | Description                                              |
| ------------- | -------------------------------------------------------- |
| `spawn_agent` | Create a new sub-agent with a task prompt                |
| `send_input`  | Send follow-up input to a running or completed sub-agent |
| `wait`        | Block until a sub-agent completes and return its result  |
| `close_agent` | Close a running or completed sub-agent                   |

These tools are registered automatically when the session starts. They inherit the parent's permissions.

## Session isolation

Each sub-agent runs in its own session:

* **Own conversation** -- the child starts with a fresh LLM history
* **Own tool access** -- the child can use the same tools as the parent
* **Concurrent execution** -- the parent can continue working before calling `wait`

The parent can spawn multiple sub-agents and synchronize with them later.

## Continue a completed session

A completed sub-agent remains available until the parent closes it. Calling `send_input` starts another turn in the same child session, so the child keeps its conversation history. A message sent while the child is still running is queued for a safe turn boundary instead.

Call `wait` again to receive the new turn's result. Call `close_agent` when the child is no longer needed; a closed child cannot accept more input.

## Depth limits

Sub-agents can themselves spawn sub-agents, creating a hierarchy. The coding agent limits how many child sessions a stage can hold open at once and how deep the tree can grow; the defaults keep one level of children.

If a child tries to exceed the limit, `spawn_agent` returns an error immediately.

## Error handling

Sub-agent failures do not automatically fail the parent stage. The parent receives the failure through `wait` and decides how to respond.

Common cases:

* **Panics or errors** -- returned as a failed `wait` result
* **`spawn_agent` fails** -- returned immediately as a tool result

## Event forwarding

Sub-agent observability now uses **session linkage**, not wrapper events.

Parent-owned lifecycle events:

| Event                 | When                              |
| --------------------- | --------------------------------- |
| `agent.sub.spawned`   | A sub-agent was created           |
| `agent.sub.completed` | A sub-agent finished successfully |
| `agent.sub.failed`    | A sub-agent failed                |
| `agent.sub.closed`    | A sub-agent was cancelled         |

Forwarded child activity:

* Child tool calls, assistant messages, warnings, and other non-noisy session events are forwarded into the parent run's event stream as normal agent events.
* The forwarded event keeps the child's `session_id`.
* `parent_session_id` points to the child's immediate parent session.

Example envelope:

```json theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
{
  "event": "agent.tool.started",
  "session_id": "ses_child",
  "parent_session_id": "ses_parent",
  "node_id": "code",
  "properties": {
    "tool_name": "read_file"
  }
}
```

Nested sub-agents preserve the immediate parent-child relationship. A grandchild forwarded through multiple parents still carries its own `session_id`, and `parent_session_id` remains set to the grandchild's direct parent rather than the root.

High-volume streaming events such as text deltas and tool output deltas are filtered out of the forwarded stream to reduce noise.

## When to use sub-agents

Sub-agents are most useful for:

* **Parallel research** -- inspect multiple code paths at once
* **Isolation** -- try a risky approach without polluting the parent's context
* **Divide and conquer** -- split an independent task into smaller pieces
* **Context management** -- offload work when the parent session is getting crowded

Use [child runs](/execution/child-runs) instead when the delegated work should be a separate Fabro run with its own workflow, lifecycle, sandbox, checkpoints, and outputs.

<Note>
  Sub-agents run until they complete, fail, are cancelled, or hit the session's wall-clock timeout. All active sub-agents are cleaned up automatically when the parent session closes.
</Note>
