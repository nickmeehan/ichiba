> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Nodes & Stages

> All node types and how they become stages at runtime

## Nodes vs. stages

A **node** is a step defined in the Graphviz file at author time. A **stage** is the runtime execution of a node. In a simple linear workflow, each node runs once and produces one stage. But when a workflow loops — for example, an implement-test-fix cycle — the same node can produce multiple stages within a single run.

This distinction matters for observability and debugging: the workflow graph shows nodes, but the run timeline shows stages. Each stage records its own inputs, outputs, duration, and token usage.

## Node types

An explicit `type` attribute selects a node's execution behavior. Otherwise, its Graphviz `shape` selects the behavior. When both are omitted, a node with `script` is a command node and every other node defaults to an agent.

### Start

**Shape:** `Mdiamond`

The entry point of the workflow. Every workflow must have exactly one start node.

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
start [shape=Mdiamond, label="Start"]
```

### Exit

**Shape:** `Msquare`

The terminal node. When execution reaches exit, the workflow completes. Every workflow must have exactly one exit node.

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
exit [shape=Msquare, label="Exit"]
```

### Agent

**Shape:** `box` (default when `shape`, `type`, and `script` are omitted)

Runs an LLM with access to tools — bash, file editing, sub-agents — in an agentic loop. The agent works autonomously, calling tools as needed, until it decides the task is complete.

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
implement [label="Implement", prompt="Read plan.md and implement every step."]
```

Key attributes:

| Attribute          | Description                                                                                                          |
| ------------------ | -------------------------------------------------------------------------------------------------------------------- |
| `prompt`           | The task instructions for the agent                                                                                  |
| `reasoning_effort` | `low`, `medium`, or `high` (default: `high`)                                                                         |
| `max_tokens`       | Maximum tokens for LLM responses                                                                                     |
| `fidelity`         | How much prior context is passed to this node (see [Context](/execution/context#fidelity-controlling-agent-context)) |
| `thread_id`        | Groups nodes into a shared conversation thread (advanced — see below)                                                |
| `timeout`          | Execution timeout (e.g. `"900s"`). Time spent waiting for an answer to an agent question does not count.             |

**Fidelity levels:**

| Value            | Behavior                                                  |
| ---------------- | --------------------------------------------------------- |
| `compact`        | Structured summary of prior stages (default)              |
| `full`           | Complete context from all prior stages — no summarization |
| `summary:high`   | Detailed summary including outputs and key details        |
| `summary:medium` | Moderate summary with outcomes and notable findings       |
| `summary:low`    | Brief summary with just outcomes per stage                |
| `truncate`       | Minimal — only the goal and run ID                        |

Fidelity can also be set at the graph level (`default_fidelity`) or on individual edges to control the transition between stages. See [Context](/execution/context#fidelity-controlling-agent-context) for the full reference on fidelity precedence, preamble construction, and thread integration.

**Thread ID:**

Setting `thread_id` on multiple nodes (e.g. `thread_id="impl"`) groups them into a shared conversation thread, preserving context continuity across nodes as if they were part of the same session. This is an advanced feature typically used within subgraph clusters:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
subgraph cluster_impl {
    node [fidelity="full", thread_id="impl"]
    plan      [label="Plan"]
    implement [label="Implement"]
    review    [label="Review"]
}
```

### Prompt

**Shape:** `tab`

Makes a single LLM call with no tool use. Useful for analysis, summarization, generation, and lightweight reasoning where tools aren't needed.

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
spec [label="Write Spec", shape=tab, prompt="Write a brief spec for a string utility module."]
```

Prompt nodes accept the same attributes as agent nodes (`prompt`, `reasoning_effort`, `max_tokens`, etc.) but never invoke tools.

### Command

**Shape:** `parallelogram` (optional when `shape` and `type` are omitted — inferred from `script`)

Runs a shell script inside the configured sandbox and captures its output. The output is available to downstream nodes as context. This ensures command nodes execute in the same environment as agent nodes.

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
test [label="Run Tests", script="cargo test 2>&1 || true"]

merge_results [
    script="python3 scripts/merge.py",
    stdin_source="context.parallel.results"
]
```

When a node has no explicit `shape` or `type`, the presence of `script` makes it a command node. Writing `shape=parallelogram` explicitly is still valid and does the same thing.

| Attribute      | Description                                                                                                                                                                           |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `script`       | The shell command to execute (required). Substitutes `{{ goal }}`, `{{ inputs.NAME }}`, and `{{ vars.NAME }}` — see [command node scripts](/workflows/variables#command-node-scripts) |
| `language`     | `"shell"` (default) or `"python"`                                                                                                                                                     |
| `stdin_source` | Flat runtime context key to pass to the command's standard input. `context.NAME` first checks that exact key, then falls back to `NAME`.                                              |

For `stdin_source`, strings are passed unchanged. Other JSON values use compact
JSON. Fabro does not add a newline. A missing source, or a value larger than
30 MiB, fails before the command starts.

### Human

**Shape:** `hexagon`

Pauses the workflow and waits for a person to choose a path. The outgoing edge labels define the available options:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
approve [shape=hexagon, label="Approve Plan"]

approve -> implement [label="[A] Approve"]
approve -> plan      [label="[R] Revise"]
```

In the web UI, human gates appear as interactive prompts. From the CLI, they appear as a menu.

### Wait

**Shape:** `insulator`

Pauses the workflow for a configured duration before proceeding. Useful for rate limiting between API calls or waiting for external processes to complete.

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
cooldown [label="Wait 30s", shape=insulator, duration="30s"]
```

| Attribute  | Description                                                                                          |
| ---------- | ---------------------------------------------------------------------------------------------------- |
| `duration` | How long to pause (required). Supports `ms`, `s`, and `m` suffixes (e.g. `"500ms"`, `"30s"`, `"2m"`) |

### Conditional

**Shape:** `diamond`

Routes execution to different edges based on conditions evaluated against the current run context:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
gate [shape=diamond, label="Tests passing?"]

gate -> exit      [label="Pass", condition="outcome=succeeded"]
gate -> implement [label="Fix"]
```

Conditions support `=`, `!=`, `&&`, and context variable lookups (e.g. `context.tests_passed=true`). An edge with no condition acts as the default fallback.

### Parallel (fan-out)

**Shape:** `component`

Fans out to execute multiple branches concurrently. Every branch runs in the same sandbox checkout and working directory, and the parallel node waits for every branch to finish.

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fork [label="Fan Out", shape=component]

fork -> security
fork -> architecture
fork -> quality
```

| Attribute      | Description                                                                                              |
| -------------- | -------------------------------------------------------------------------------------------------------- |
| `max_parallel` | Maximum concurrent branches (default: 4)                                                                 |
| `for_each`     | Flat context key containing a runtime JSON array. Requires one outgoing agent or prompt template target. |

To run one template node for a runtime array, add `for_each`:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
review_batch [shape=component, for_each="context.candidates", max_parallel=8]
reviewer [prompt="Review this candidate for security issues."]
aggregate [shape=tripleoctagon, prompt="Synthesize every candidate review."]

review_batch -> reviewer -> aggregate
```

Fabro accepts an inline array or a managed JSON artifact reference. It runs
`reviewer` once per item, appends the item to the prompt as fenced data, and
keeps the results in input order. The source lookup is flat:
`context.candidates` checks that exact key and then `candidates`; it does not
traverse nested objects.

Each item can contribute up to 64 KiB of serialized JSON to its branch prompt. Fabro stores larger items as content-addressed blobs and replaces the inline item with its size, a readable file path, and a 300-character preview. The preview remains inside the untrusted-data fence, and the branch agent can read the file for the full item.

The template target must be an agent or prompt node, and nested `for_each` is
rejected. An empty source array succeeds with `parallel.results=[]` and skips
straight to `aggregate`. Missing, invalid, non-array, or over-long sources fail
the parallel stage before any branches start; the limit is 1000 items.

Because the checkout is shared, file changes from one branch are immediately visible to the others. Concurrent writes can race or overwrite each other. Fabro does not isolate branch files, lock paths, detect conflicts, or warn about overlapping writes. Design branches to be read-only or assign each branch disjoint files and directories when deterministic workspace changes matter.

For each branch's first node, fidelity resolves from the fork-to-branch edge, then the branch node; otherwise it inherits the fork preamble unchanged. Fabro renders branch-specific preambles before fan-out from the fork snapshot. Branch-level `full` degrades to `summary:high` because concurrent branches cannot share sessions, and `thread_id` on a branch node or fork-to-branch edge is inert.

### Merge (fan-in)

**Shape:** `tripleoctagon`

Converges parallel branches after all of them finish. Branch status and context updates are collected in the runtime context at `parallel.results`; Fabro does not create a `parallel_results.json` file in the checkout.

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
merge [
    label="Synthesize Results",
    shape=tripleoctagon,
    prompt="Synthesize every branch result into one report."
]

security     -> merge
architecture -> merge
quality      -> merge
merge -> report
```

A fan-in node with a `prompt` synthesizes the collected results. It never chooses, restores, or merges a branch's workspace state: all branches have already operated on the same checkout. Without a prompt, fan-in is only a convergence barrier.

## Common node attributes

These attributes can be set on any node type:

| Attribute      | Description                                                                                                     |
| -------------- | --------------------------------------------------------------------------------------------------------------- |
| `label`        | Display name shown in the graph visualization                                                                   |
| `class`        | CSS-like class for [model stylesheet](/workflows/stylesheets) targeting. Separate multiple classes with spaces. |
| `max_visits`   | Max times this node can execute in a run. Overrides the graph-level `max_node_visits` for this node.            |
| `goal_gate`    | When `true`, the workflow fails if this node doesn't succeed                                                    |
| `max_retries`  | Override default retry count for this node                                                                      |
| `retry_policy` | Named retry preset (see table below)                                                                            |

**Retry policies:**

| Preset       | Attempts | Backoff                       | Description                          |
| ------------ | -------- | ----------------------------- | ------------------------------------ |
| `none`       | 1        | —                             | No retries, fail immediately         |
| `standard`   | 5        | 5s initial, 2x exponential    | Good default for transient failures  |
| `aggressive` | 5        | 500ms initial, 2x exponential | Longer initial delay for rate limits |
| `linear`     | 3        | 500ms fixed                   | Constant delay between attempts      |
| `patient`    | 3        | 2s initial, 3x exponential    | Slow ramp for unreliable services    |

If neither `retry_policy` nor `max_retries` is set, nodes default to 3 retries with standard backoff.
