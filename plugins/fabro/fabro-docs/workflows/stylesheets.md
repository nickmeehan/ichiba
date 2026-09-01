> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Model Stylesheets

> Assign LLM models to workflow nodes using CSS-like rules

Model stylesheets let you assign LLM models, providers, and settings to workflow nodes using a CSS-like syntax. Instead of hardcoding a model on every node, you write a set of rules that target nodes by ID, class, shape, or a universal wildcard — and Fabro applies them by specificity.

## Defining a stylesheet

Stylesheets are set in the `model_stylesheet` graph attribute:

```dot title="example.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Example {
    graph [
        goal="Build and review a utility function",
        model_stylesheet="
            *        { model: claude-haiku-4-5;}
            .coding  { model: claude-sonnet-4-5; reasoning_effort: high; }
            #review  { model: gemini-3.1-pro-preview;}
        "
    ]

    start [shape=Mdiamond, label="Start"]
    exit  [shape=Msquare, label="Exit"]

    spec      [label="Write Spec"]
    implement [label="Implement", class="coding"]
    test      [label="Write Tests", class="coding"]
    review    [label="Code Review"]

    start -> spec -> implement -> test -> review -> exit
}
```

In this example:

* **spec** gets Haiku (matches `*`)
* **implement** and **test** get Sonnet with high reasoning (match `.coding`)
* **review** gets Gemini Pro (matches `#review`)

## Template stylesheets

The root graph's `model_stylesheet` is a [MiniJinja template](/workflows/variables). It can read typed run inputs and server-managed variables through `inputs` and `vars`:

```dot title="variable-effort.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Review {
    graph [
        model_stylesheet="
            * { reasoning_effort: low; }

            {% if inputs.effort == 'deep' %}
            .variable-effort { reasoning_effort: high; }
            {% elif inputs.effort == 'balanced' %}
            .variable-effort { reasoning_effort: medium; }
            {% endif %}
        "
    ]

    triage [prompt="Triage the change"]
    review [prompt="Review the change", class="variable-effort"]
}
```

Stylesheet templates support expressions, conditionals, loops, filters, macros, `{% set %}`, and normal local values such as `loop`. They do not expose `goal`, `env`, or `secrets`.

Fabro renders a stylesheet once. If an input or variable contains `{{ ... }}` or `{% ... %}`, that text stays literal. Fabro does not render it again.

Template output is not escaped as stylesheet syntax. Map user-facing choices to fixed declarations instead of inserting unrestricted text directly:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
model_stylesheet="
    {% set efforts = {'quick': 'low', 'thorough': 'high'} %}
    .review { reasoning_effort: {{ efforts[inputs.review_mode] }}; }
"
```

Use single quotes inside MiniJinja expressions when possible. A double quote must follow normal DOT string escaping because the surrounding graph attribute uses double quotes. MiniJinja braces need no extra escaping inside the quoted DOT attribute.

Static template includes are supported and resolve relative to the workflow template root:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
graph [model_stylesheet="{% include 'styles/models.partial' %}"]
```

Include paths must be literal. Dynamic or root-escaping include paths fail validation. `model_stylesheet` does not support the `@file` shorthand.

Fabro uses this order:

1. Parse the DOT source.
2. Expand workflow imports and supported file references.
3. Render the root `model_stylesheet` with `{ inputs, vars }`.
4. Parse and apply the rendered stylesheet.
5. Resolve model and provider selectors.
6. Validate the transformed graph.

A `model_stylesheet` on an imported graph is ignored and produces an `imported_model_stylesheet_ignored` warning. Put the stylesheet on the root graph. A root stylesheet can target imported nodes by their generated IDs, classes, or shapes.

If an input or variable is unavailable, `fabro validate` reports `template_undefined_variable`. It skips stylesheet syntax and model checks for that validation pass. Run-style commands treat the same diagnostic as an error before they create or start a run.

## Selectors

Each rule starts with a selector that determines which nodes it applies to:

| Selector  | Syntax                        | Matches                        | Specificity |
| --------- | ----------------------------- | ------------------------------ | ----------- |
| Universal | `*`                           | All nodes                      | 0           |
| Shape     | `box`, `tab`, `hexagon`, etc. | Nodes with that Graphviz shape | 1           |
| Class     | `.classname`                  | Nodes with `class="classname"` | 2           |
| ID        | `#nodeid`                     | The node with that specific ID | 3           |

### Assigning classes

Set the `class` attribute on a node to target it with class selectors. Separate multiple classes with spaces:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
implement [label="Implement", class="coding critical"]
```

This node matches both `.coding` and `.critical` rules.

## Properties

Stylesheets support five properties:

| Property           | Description                                                                                                                                                                                                                                     | Example                                   |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| `model`            | Model ID or alias                                                                                                                                                                                                                               | `claude-sonnet-4-5`, `opus`, `gemini-pro` |
| `provider`         | Provider name (optional — auto-inferred from the model catalog when omitted)                                                                                                                                                                    | `anthropic`, `openai`, `gemini`           |
| `reasoning_effort` | Reasoning effort level                                                                                                                                                                                                                          | `low`, `medium`, `high`                   |
| `speed`            | Output speed mode. `fast` enables Anthropic's fast mode for up to 2.5x faster output at higher cost.                                                                                                                                            | `fast`                                    |
| `backend`          | Agent execution backend — `api` (default) runs Fabro's own tool loop, `cli` delegates to a legacy external CLI tool, and `acp` runs an Agent Client Protocol stdio agent in the active sandbox. See [Backends](/core-concepts/agents#backends). | `api`, `cli`, `acp`                       |

See [Models](/core-concepts/models) for the full list of model IDs and aliases.

## Specificity and cascading

When multiple rules match the same node, the rule with the **highest specificity** wins. This follows the same principle as CSS:

```
* (0) < shape (1) < .class (2) < #id (3)
```

For example:

```
*       { model: claude-haiku-4-5; }
.coding { model: claude-sonnet-4-5; }
#review { model: gpt-5.4; }
```

A node with `id="review"` and `class="coding"` gets `gpt-5.4` because `#id` (specificity 3) beats `.class` (specificity 2).

If two rules have the same specificity, the **last one** in the stylesheet wins.

## Explicit attributes override stylesheets

A model set directly on a node attribute always takes precedence over stylesheets, regardless of specificity:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
implement [label="Implement", class="coding", model="claude-opus-4-6"]
```

Even if `.coding` sets `model: claude-sonnet-4-5`, this node uses Opus because the explicit attribute wins.

## Syntax reference

The stylesheet syntax is a simplified subset of CSS:

```
selector { property: value; property: value; }
```

* Selectors: `*`, `shape`, `.class`, `#id`
* Properties and values are separated by `:`
* Declarations are separated by `;`
* Whitespace is flexible — newlines and indentation are ignored
* CSS block comments (`/* ... */`) can appear between tokens and are ignored
* Comments close at the first `*/` and do not nest; an unterminated comment is a syntax error
* `//` starts a comment in the surrounding workflow file, but not inside a stylesheet

### Full example

```
/* Use a fast model by default. */
*            { model: claude-haiku-4-5;reasoning_effort: low; }
box          { reasoning_effort: high; }
tab          { reasoning_effort: low; }
.coding      { model: claude-sonnet-4-5;reasoning_effort: high; }
.review      { model: gemini-3.1-pro-preview;}
#final_check { model: claude-opus-4-6;reasoning_effort: high; }
```

This stylesheet:

* Defaults everything to Haiku with low reasoning
* Overrides all agent nodes (`box` shape) to high reasoning
* Keeps prompt nodes (`tab` shape) at low reasoning
* Routes `.coding` nodes to Sonnet
* Routes `.review` nodes to Gemini for independent critique
* Routes the `final_check` node to Opus for maximum quality
