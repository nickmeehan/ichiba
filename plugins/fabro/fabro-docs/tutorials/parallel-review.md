> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Parallel Review

> Shared-checkout fan-out, fan-in, and result synthesis

This tutorial runs three code review perspectives in parallel — security, architecture, and quality — then merges the results into a single report.

## The workflow

<Frame>
  <img src="https://mintcdn.com/qltysoftware-21b56213/G7Im2lhV2VdE8zmz/images/tutorial-parallel-review.svg?fit=max&auto=format&n=G7Im2lhV2VdE8zmz&q=85&s=157d945602fa398cfff2fd87144eeb6f" alt="Parallel Review workflow: Start → Fan Out → Security Audit, Architecture Review, Code Quality → Merge → Final Report → Exit" width="855" height="203" data-path="images/tutorial-parallel-review.svg" />
</Frame>

```dot title="parallel.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Parallel {
    graph [goal="Perform a multi-perspective code review"]
    rankdir=LR

    start [shape=Mdiamond, label="Start"]
    exit  [shape=Msquare, label="Exit"]

    fork [label="Fork Analysis", shape=component]

    security     [label="Security Audit", prompt="Examine the codebase for security concerns: hardcoded secrets, injection risks, unsafe dependencies. List findings as bullet points.", shape=tab, reasoning_effort="low"]
    architecture [label="Architecture Review", prompt="Assess the codebase architecture: separation of concerns, dependency structure, modularity. List findings as bullet points.", shape=tab, reasoning_effort="low"]
    quality      [label="Code Quality", prompt="Check code quality: naming conventions, dead code, test coverage gaps, error handling. List findings as bullet points.", shape=tab, reasoning_effort="low"]

    merge  [label="Synthesize Findings", shape=tripleoctagon, prompt="Synthesize every branch result into a prioritized summary report with the top 5 action items."]
    report [label="Write Final Report", prompt="Write the synthesized review as a clear final report.", shape=tab]

    start -> fork
    fork -> security
    fork -> architecture
    fork -> quality
    security -> merge
    architecture -> merge
    quality -> merge
    merge -> report -> exit
}
```

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro run docs/internal/demo/06-parallel.fabro
```

## Fan-out with the fork node

The `fork` node has `shape=component`, making it a **parallel fan-out node**. Every outgoing edge becomes a concurrent branch:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fork [label="Fork Analysis", shape=component]

fork -> security
fork -> architecture
fork -> quality
```

All three branches start concurrently and operate in the same sandbox checkout and working directory. This review is safe because the branches are prompt nodes with no workspace tools.

<Warning>
  Parallel branches are not isolated from one another. If branches edit files, they can observe, race with, or overwrite each other's changes. Fabro does not lock files, detect overlapping writes, or warn about races. Keep branches read-only or give each branch responsibility for disjoint paths.
</Warning>

The parallel node always waits for every branch to finish before continuing.

## Fan-in with the merge node

The `merge` node has `shape=tripleoctagon`, making it a **merge (fan-in) node**. It receives every branch's status and context updates in `parallel.results` and synthesizes them with its prompt:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
merge [
    label="Synthesize Findings",
    shape=tripleoctagon,
    prompt="Synthesize every branch result into a prioritized summary report with the top 5 action items."
]

security     -> merge
architecture -> merge
quality      -> merge
```

`parallel.results` is runtime context, not a `parallel_results.json` file in the checkout. Fan-in never selects a branch's files or changes workspace state; every branch has already worked in the same checkout. The downstream `report` node writes the synthesis produced by fan-in as the final report.

## Concurrency control

By default, Fabro runs up to 4 parallel branches simultaneously. Control this with `max_parallel`:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fork [shape=component, max_parallel=2]
```

This is useful when branches are resource-intensive (e.g., each running a full agent session with tool calls) and you want to limit concurrency.

## Review a runtime candidate list

Static branches work when the review perspectives are known while writing the
graph. A security scan often discovers its review candidates at runtime. Write
that array to a flat context key, then use `for_each` to run one reviewer per
candidate:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
discover [
    shape=tab,
    output_schema="routing",
    prompt="Identify security review candidates. Return only JSON with \
      context_updates.candidates as an array of objects. Give every object a \
      name, path, and reason."
]

review_batch [
    shape=component,
    for_each="context.candidates",
    max_parallel=4
]

reviewer [
    label="Candidate Reviewer",
    prompt="Inspect this candidate for exploitable security problems. Report \
      evidence, severity, and a concrete remediation."
]

aggregate [
    shape=tripleoctagon,
    prompt="Synthesize all candidate reviews. Call out candidates whose branch failed."
]

discover -> review_batch
review_batch -> reviewer
reviewer -> aggregate
```

The `routing` output schema merges `context_updates.candidates` into the flat
`candidates` context key. `review_batch` accepts that inline array or its
automatically offloaded managed artifact reference. It clones `reviewer` for
each item, appends the item as pretty JSON inside a fresh
`<untrusted-{16 lowercase hex}>` fence with a matching closing tag, and keeps
`parallel.results` in candidate order.

Each result has `id="reviewer"`, a zero-based `index`, and an `item_label`
chosen from the item's `name`, then `label`, then index. An empty candidate
array succeeds and proceeds directly to `aggregate`. Mixed success and failure
also proceeds; only an all-failed batch fails the parallel stage.

Retries and executor-enforced timeouts apply independently to each candidate.
A retry keeps the same result index and branch identity, and releases its
`max_parallel` slot while waiting for backoff. If a run stops partway through
the batch, resuming it reruns every item because per-item checkpoints are not
created.

<Warning>
  The randomized fence prevents candidate text from closing its own data block,
  but it does not sandbox a tool-enabled reviewer. Candidate data can still try
  to influence the model. Limit the target agent's tools and permissions to the
  minimum needed for the review.
</Warning>

## What you've learned

* **Fan-out nodes** (`shape=component`) spawn concurrent branches and wait for all of them
* `for_each` runs one agent or prompt template for every item in a runtime array
* Parallel branches share one checkout, so workflows must prevent or tolerate file races
* **Fan-in nodes** (`shape=tripleoctagon`) can synthesize `parallel.results` with a prompt
* Fan-in never selects or restores workspace state, and no results file is created

## Next

<Card title="Multi-Model Routing" icon="arrow-right" href="/tutorials/multi-model">
  Assign different models to different workflow nodes using stylesheets.
</Card>
