> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Decisions

> Adding human review and intervention to workflows

Not every decision should be made by an LLM. Fabro provides several mechanisms for humans to participate in workflows — approving plans, choosing between options, providing free-form input, and steering agents while they run.

## Human gates

A human gate is a node with shape `hexagon` that pauses the workflow and presents the user with a choice. The options are derived from the outgoing edge labels:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
approve [shape=hexagon, label="Approve Plan"]

approve -> implement [label="[A] Approve"]
approve -> plan      [label="[R] Revise"]
approve -> skip      [label="[S] Skip"]
```

When execution reaches the gate, the user sees the previous stage's output followed by the node's label ("Approve Plan") and the available options. In the CLI, this appears as an interactive menu. In the web UI, blocked runs show an interview dock on the run page where the user can answer the pending question.

### Keyboard accelerators

The prefixes `[A]`, `[R]`, `[S]` in edge labels serve as keyboard accelerators. Fabro supports three formats:

| Format      | Example       |
| ----------- | ------------- |
| `[K] Label` | `[A] Approve` |
| `K) Label`  | `A) Approve`  |
| `K - Label` | `A - Approve` |

When matching the user's selection to an edge, Fabro strips the accelerator prefix so typing `A` matches `[A] Approve`.

### Freeform input

In addition to fixed choices, a human gate can accept freeform text input. Add an edge with `freeform=true`:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
review [shape=hexagon, label="Review Changes"]

review -> implement [label="[A] Approve"]
review -> plan      [label="[R] Revise"]
review -> custom    [freeform=true]
```

If the user types something that doesn't match any fixed option, their input routes to the freeform edge. The text is available to downstream nodes as `human.gate.text` in the run context.

When a gate has only a freeform edge and no fixed choices, the user goes directly to a text input prompt — skipping the multiple-choice menu entirely. This is useful for conversational loops like REPL workflows where the user provides open-ended instructions each iteration.

### Question types

Human gates infer their interview type from their edges: fixed choices become `multiple_choice`, and a gate with only a freeform edge becomes `freeform`. To force another interviewer presentation, set `question_type` on the node:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
confirm [shape=hexagon, label="Continue?", question_type="confirmation"]

confirm -> next [label="[Y] Yes"]
confirm -> exit [label="[N] No"]
```

Supported values are `yes_no`, `confirmation`, `multiple_choice`, `multi_select`, and `freeform`.

### Review targets

A human gate can present one external document as the primary review link. Set
`review_target=true` on the gate:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
review [
  shape=hexagon,
  review_target=true
]

review -> sync     [label="[S] Review complete; sync the current Markdown"]
review -> address  [label="[A] Ask the agent to address human feedback"]
review -> review   [label="[C] Continue reviewing"]
```

Before the workflow reaches the gate, an agent, prompt, or command node must set
the flat `review_target` context key. A routing response can do this directly:

```json theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
{
  "outcome": "succeeded",
  "context_updates": {
    "review_target": {
      "label": "Quarry review exercise",
      "url": "https://quarry.lithos.computer/tmp/0123456789abcdef0123456789abcdef",
      "kind": "document"
    }
  }
}
```

Fabro then presents this question:

> Review the [Quarry review exercise](https://quarry.lithos.computer/tmp/0123456789abcdef0123456789abcdef) document, then choose the next action.

The link uses the target URL from context. The example uses a placeholder
secret, not a live Quarry document.

Fabro generates this question text from the target. A `label` on the gate is
not used while `review_target=true`.

The target object has three required fields:

| Field   | Meaning                                                                                                                       |
| ------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `label` | The link text. It must contain 1 to 200 characters and no control characters.                                                 |
| `url`   | An absolute HTTP or HTTPS URL. It must contain a host, must not contain URL credentials, and must be at most 2048 characters. |
| `kind`  | The resource type. The supported value is `document`.                                                                         |

Fabro validates the target before it starts the interview. A missing or invalid
target fails the gate deterministically. A gate without `review_target=true`
ignores this context key and keeps its normal label.

The context value remains available after the human answers. A feedback loop
can return to the same gate without recreating the target. A later stage can
replace the target by writing a new value to the same context key.

Fabro does not fetch the URL. Web and Slack clients open it as an external link.
Treat bearer-capability links as secrets and only provide them to people who
can access the run.

### Default choice on timeout

If a human gate has a timeout configured, you can specify a default choice using the `human.default_choice` attribute:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
approve [shape=hexagon, label="Approve?", human.default_choice="approve"]
```

If the timeout elapses without a response, the workflow continues to the default target rather than failing.

### Unanswered gates fail closed

Fabro does not treat missing input as approval. A human gate advances only when one of these happens:

* A person explicitly answers the question
* The gate times out and `human.default_choice` is set
* The run uses `--auto-approve`

If stdin is closed, a prompt is canceled, a web session disconnects, or no answer is otherwise captured, the gate is treated as unanswered. Fabro will not fall through to an unconditional approval edge. If you want to handle that case explicitly, add a failure route such as `condition="outcome=failed"` or a `retry_target`.

### Auto-approve

For testing or fully automated runs, pass `--auto-approve` to skip all human gates:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro run workflow.fabro --auto-approve
```

Auto-approve selects `Yes` for yes/no gates and the first option for multiple-choice gates.

## Where to place human gates

Human gates are most valuable at high-leverage decision points:

* **Before implementation** — Approve a plan before the agent writes code
* **After review** — Confirm that a code review's findings are worth fixing
* **At branch points** — Choose a strategy when multiple approaches are viable
* **Before external actions** — Approve before deploying, merging, or sending notifications

A workflow can have multiple human gates. Place them where the cost of a wrong decision is high relative to the cost of a brief pause.

## Context set by human gates

When a user makes a selection, the human gate sets several context values for downstream use:

| Context key                  | Value                                                              |
| ---------------------------- | ------------------------------------------------------------------ |
| `human.gate.selected`        | The accelerator key (e.g. `"A"`) or `"freeform"`                   |
| `human.gate.label`           | The full label of the selected edge                                |
| `human.gate.text`            | The user's freeform text (if applicable)                           |
| `human.gate.<node>.question` | The question text for a specific human gate node                   |
| `human.gate.<node>.answer`   | The answer text for a specific human gate node                     |
| `human.gate.<node>.label`    | The selected label for a specific human gate node, when applicable |

These can be read in edge conditions or referenced by downstream agents.
