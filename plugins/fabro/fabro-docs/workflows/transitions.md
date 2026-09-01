> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Transitions

> How Fabro decides which node to execute next

After each node finishes, Fabro must decide which edge to follow to the next node. This decision is deterministic by default — given the same outcome and context, Fabro always picks the same edge. Nodes can opt into [random selection](#random-selection) for weighted-random tiebreaking instead. Understanding the transition logic helps you design workflows that route reliably.

## How transitions work

When a node completes, it produces an **outcome** with a [stage outcome](/execution/outcomes) (`succeeded`, `failed`, `partially_succeeded`, or `skipped`) and optional signals like a preferred label or suggested next node. A node's retry policy runs before routing starts. Fabro then selects the next step in this order:

1. **Direct jump** — An outcome's `jump_to_node` value bypasses edge selection.
2. **Condition match** — Edges with a `condition` attribute are evaluated first. If one or more conditions match, the edge with the highest `weight` wins (lexical tiebreak on target node ID).
3. **Preferred label** — If the node's outcome includes a preferred label (for example, from a human gate selection), the edge whose `label` matches is chosen.
4. **Suggested next** — If the node suggests a specific next node ID, the edge pointing to that node is chosen.
5. **Failure policy** — For a failed outcome with no explicit route, the effective `on_failure` policy (node-level `on_failure` first, then graph-level) decides what happens next. `exit` skips the unconditional fallback. `succeed` promotes the outcome to `succeeded` and routes it as a success. `route` continues to the unconditional fallback.
6. **Unconditional fallback** — Edges without conditions are considered last, again using `weight` then lexical tiebreak.
7. **Retry target** — For a failed outcome with no selected edge, Fabro checks node-level and graph-level `retry_target` and `fallback_retry_target` values.

If no edge or retry target supplies a next node, the workflow ends. A failed node produces a failed run outcome.

## Failed-node routing policy

The `on_failure` attribute controls what happens to a failed node when no explicit recovery route matches:

| Policy            | Effective outcome   | Fallback routing                                                         |
| ----------------- | ------------------- | ------------------------------------------------------------------------ |
| `route` (default) | stays `failed`      | takes the unconditional edge                                             |
| `exit`            | stays `failed`      | skips the unconditional edge; the run ends unless a retry target applies |
| `succeed`         | becomes `succeeded` | uses normal success routing                                              |

Set it at the graph level to apply the policy to every node, or on a node to control that node alone. A node-level `on_failure` overrides the graph level. A node without the attribute inherits the graph policy.

This lets a linear workflow stop at the first failed work node:

```dot title="stop-on-failure.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Build {
    graph [on_failure="exit"]

    start [shape=Mdiamond]
    exit [shape=Msquare]
    plan [prompt="Plan the work"]
    implement [prompt="Implement the plan"]
    verify [prompt="Verify the implementation"]

    start -> plan -> implement -> verify -> exit
}
```

Node-level overrides work in both directions. A strict graph can mark one best-effort node as `route` so its failure continues down the unconditional edge, and a default graph can mark one critical node as `exit`:

```dot title="mixed-policies.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Build {
    graph [on_failure="exit"]

    start [shape=Mdiamond]
    exit [shape=Msquare]
    implement [prompt="Implement the change"]
    lint [prompt="Run optional lint cleanup" on_failure="route"]
    verify [prompt="Verify the implementation"]

    start -> implement -> lint -> verify -> exit
}
```

Use `succeed` for a best-effort node whose failure must not block the workflow. Its failure becomes a `succeeded` outcome, so the node's normal success routing applies:

```dot title="best-effort-node.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Review {
    graph [on_failure="exit"]

    start [shape=Mdiamond]
    exit [shape=Msquare]
    required_check [script="./required-check"]
    optional_scan [script="./optional-scan" on_failure="succeed"]

    start -> required_check -> optional_scan -> exit
}
```

Under `succeed`, Fabro first checks explicit routes against the original `failed` outcome. If a `condition="outcome=failed"` edge, a matching preferred label, a matching suggested next node, or a handler jump applies, the outcome stays `failed` and that route is taken. Otherwise Fabro rewrites the outcome to `succeeded` before it records the node, so goal gates, the run context, events, and routing all see the promoted outcome. Edge selection then runs again: `condition="outcome=succeeded"` edges and unconditional edges apply. The original failure details stay on the `stage.completed` event and in the checkpoint, and the outcome's notes record which scope promoted it. A promoted outcome is not `failed`, so retry targets do not apply to it.

Both `exit` and `succeed` apply only to the `failed` outcome. They do not change routing for `succeeded`, `partially_succeeded`, or `skipped` outcomes.

Conditioned edges, matching preferred labels, and matching suggested node IDs are explicit recovery routes. They take priority under every policy. An unmatched preferred label or suggested node ID does not make an unconditional edge explicit.

Retry targets also remain available under `exit`. Fabro checks them after it skips the unconditional fallback. Use graph-level `max_node_visits` or node-level `max_visits` to bound workflows whose retry targets return to a failing path.

A failed human gate never falls through to an unconditional edge as a failure, regardless of policy. Node-level `on_failure="route"` does not change that; route an interrupted gate explicitly with `condition="outcome=failed"`. Under `succeed`, an interrupted gate with no explicit route is promoted like any other node and then follows its success routing.

When `exit` stops routing, Fabro checkpoints the failed node without a next node and ends the run as failed. It does not execute the graph's exit node or emit an edge selection for an edge it did not take. An explicit recovery route can still reach the exit node normally.

For a parallel node, `exit` and `succeed` see the final outcome returned by the parallel handler. `exit` can stop routing for a failed parallel outcome; `succeed` promotes it. Neither adds branch-level fail-fast behavior, and a `partially_succeeded` parallel outcome continues normally. Inside the fan-out, a branch node whose effective policy is `succeed` counts as `succeeded` in the parent's aggregate when it fails. Branches have no edge routing, so there is no explicit route to prefer.

<Note>
  `auto_status=true` is the deprecated spelling of node-level `on_failure="succeed"`. Fabro still accepts it as an alias and validation warns with the replacement. See [Node Outcomes](/execution/outcomes#succeed-on-failure).
</Note>

## Edge attributes

| Attribute   | Description                                                             |
| ----------- | ----------------------------------------------------------------------- |
| `label`     | Display text on the edge; also used for human gate option matching      |
| `condition` | Boolean expression that must evaluate to true for this edge (see below) |
| `weight`    | Numeric priority for tiebreaking (higher wins, default: 0)              |

## Conditions

Edge conditions are boolean expressions evaluated against the stage outcome and run context. Conditions go in the `condition` attribute on an edge:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
gate -> exit      [label="Pass", condition="outcome=succeeded"]
gate -> implement [label="Fix", condition="outcome=failed"]
```

### Available keys

| Key               | Resolves to                                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `outcome`         | The stage outcome: `succeeded`, `failed`, `partially_succeeded`, or `skipped`. See [Node Outcomes](/execution/outcomes). |
| `preferred_label` | The label selected by a human gate                                                                                       |
| `context.KEY`     | A value from the run context (e.g. `context.tests_passed`)                                                               |
| `KEY`             | Shorthand for context lookup (without the `context.` prefix)                                                             |

### Operators

| Operator   | Example                          | Description                          |
| ---------- | -------------------------------- | ------------------------------------ |
| `=`        | `outcome=succeeded`              | Equality                             |
| `!=`       | `outcome!=failed`                | Inequality                           |
| `>`        | `context.score > 80`             | Greater than (numeric)               |
| `<`        | `context.count < 5`              | Less than (numeric)                  |
| `>=`       | `context.score >= 80`            | Greater than or equal (numeric)      |
| `<=`       | `context.count <= 10`            | Less than or equal (numeric)         |
| `contains` | `context.message contains error` | Substring match, or array membership |
| `matches`  | `context.version matches ^v\d+`  | Regular expression match             |

A bare key with no operator is a **truthiness check** — it passes if the value is non-empty, not `"false"`, and not `"0"`:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
gate -> next [condition="my_flag"]
```

### Combining conditions

Use `&&` (AND), `||` (OR), and `!` (NOT) to build compound expressions. `&&` binds tighter than `||`:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
// Both must be true
gate -> deploy [condition="outcome=succeeded && context.tests_passed=true"]

// Either can be true
gate -> proceed [condition="outcome=succeeded || outcome=partially_succeeded"]

// Negation
gate -> retry [condition="!outcome=succeeded"]

// Mixed precedence: (a AND b) OR c
gate -> next [condition="outcome=succeeded && context.ready=true || context.override"]
```

## Agent transitions

Agent and prompt nodes can influence which edge is taken by including a JSON object in their response with routing directives. Fabro scans the LLM output for the last JSON object containing any of these fields:

```json theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
{
  "preferred_next_label": "fix",
  "suggested_next_ids": ["implement", "review"],
  "context_updates": { "tests_passed": true }
}
```

| Field                  | Effect                                                                |
| ---------------------- | --------------------------------------------------------------------- |
| `preferred_next_label` | Matched against edge labels (same as human gate selection)            |
| `suggested_next_ids`   | Ordered list of preferred target node IDs                             |
| `context_updates`      | Key-value pairs merged into the run context for downstream conditions |

Fabro automatically scans LLM output for these JSON objects — no special configuration is needed. However, you do need to instruct the LLM to emit the JSON in your prompt. For example:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
review [
    label="Review",
    shape=tab,
    prompt="Review the implementation for correctness and \
        code quality. If changes are needed, respond with: \
        {\"preferred_next_label\": \"fix\"}. If everything \
        looks good, respond with: \
        {\"preferred_next_label\": \"approve\"}."
]

review -> fix     [label="Fix"]
review -> approve [label="Approve"]
```

The LLM's natural language response can contain other text — Fabro finds the last JSON object with a recognized routing field and extracts the directives from it.

## Human gate transitions

Human gates use edge labels to present options to the user. The selected label becomes the `preferred_label` in the outcome, and Fabro matches it to the corresponding edge:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
approve [shape=hexagon, label="Approve Plan"]

approve -> implement [label="[A] Approve"]
approve -> plan      [label="[R] Revise"]
approve -> skip      [label="[S] Skip"]
```

The `[A]`, `[R]`, `[S]` prefixes are keyboard accelerators — Fabro strips them when matching, so the user can type just the letter.

## Unconditional edges

An edge without a `condition` attribute is the normal fallback. When a node has a single outgoing edge, it doesn't need a condition:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
start -> plan -> implement -> exit
```

When mixing conditional and unconditional edges, conditional matches take priority. An unconditional edge acts as the default fallback:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
gate -> fast_path [condition="outcome=succeeded"]
gate -> slow_path
```

For a failed outcome, `on_failure="exit"` skips this fallback after explicit routes are checked, and `on_failure="succeed"` promotes the outcome to `succeeded` before taking it. The default `on_failure="route"` keeps the behavior shown above.

## Weight tiebreaking

When multiple edges match (e.g. two unconditional edges), `weight` determines the winner. Higher weight wins:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
node -> preferred [weight=10]
node -> fallback  [weight=1]
```

If weights are equal, the edge with the lexicographically first target node ID is chosen. This makes the behavior fully deterministic.

## Random selection

By default, tiebreaking between candidate edges is deterministic (highest weight, then lexical node ID). Setting `selection="random"` on a node switches to weighted-random tiebreaking for its outgoing edges:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
picker [label="Pick path", selection="random"]

picker -> path_a [weight=3]
picker -> path_b [weight=1]
```

In this example, `path_a` is chosen \~75% of the time and `path_b` \~25%. Edges with weight ≤ 0 are treated as weight 1. The cascade priority (conditions → preferred label → suggested next → unconditional) is unchanged — randomness only affects the pick-one-from-candidates step within each tier.

<Note>
  `selection="random"` cannot be combined with conditional edges on the same node. Validation rejects this combination because condition evaluation order would conflict with random selection. Use unconditional edges with weights instead.
</Note>
