> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Variables

> Using templates in workflows

Fabro renders full MiniJinja templates in three workflow attributes: the graph `goal`, the root graph's `model_stylesheet`, and node `prompt`s. A command node's `script` gets narrower treatment — [simple value substitution](#command-node-scripts), not templating. Every other attribute is literal text.

## Template context

Goal templates can reference inputs and server-managed variables. Prompt templates receive those values plus the rendered workflow goal:

| Expression          | Resolves to                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| `{{ goal }}`        | The rendered workflow goal (prompts only; a goal cannot reference itself) |
| `{{ inputs.name }}` | A value from `[run.inputs]`, optionally overridden by CLI input flags     |
| `{{ vars.NAME }}`   | A server-managed variable snapshotted when the run is created             |

The root `model_stylesheet` receives only `inputs` and `vars`. It does not receive `goal`. See [Model Stylesheets](/workflows/stylesheets#template-stylesheets) for examples and output safety guidance.

Secrets are **not** available in goal, prompt, or model stylesheet templates. Use `{{ secrets.NAME }}` only in the configuration fields that support run-boundary interpolation.

## Run config inputs

Define typed inputs in `[run.inputs]`:

```toml title="run.toml" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
_version = 1

[workflow]
graph = "check.fabro"

[run]
goal = "Run repository checks"

[run.inputs]
repo_name = "fabro"
repo_url = "https://github.com/fabro-sh/fabro"
language = "rust"
```

These values are available in the graph `goal`, root `model_stylesheet`, and node `prompt` attributes:

```dot title="check.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Check {
    graph [goal="Run tests for {{ inputs.repo_name }}"]

    start [shape=Mdiamond, label="Start"]
    exit  [shape=Msquare, label="Exit"]

    test [label="Test", prompt="Clone {{ inputs.repo_url }} and run the {{ inputs.language }} test suite."]

    start -> test -> exit
}
```

Other attributes — `label`, `model`, `provider`, `condition`, and all edge attributes — do not render templates. If one of them contains `{{ … }}` or `{% … %}`, the syntax is treated as literal text and Fabro records a `detemplated_attribute` warning suggesting you move the dynamic value into a `prompt`, `goal`, or `model_stylesheet`.

Override individual inputs at run time with repeatable `-I` / `--input` flags:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro run .fabro/workflows/check/workflow.toml -I repo_name=fabro-2 --input language=rust
```

CLI input values use TOML scalar parsing when possible. Quoted strings, booleans, integers, and floats keep their typed values; unquoted bare text falls back to a string. Empty values such as `foo=` are accepted as empty strings. Arrays, inline tables, and datetimes are rejected.

## Command node scripts

A [command node](/workflows/stages-and-nodes#command) `script` substitutes `{{ goal }}`, `{{ inputs.NAME }}`, and `{{ vars.NAME }}`:

```dot title="check.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Check {
    test [shape=parallelogram, script="cargo test -p {{ inputs.crate }} --profile {{ vars.PROFILE }}"]
    pr   [shape=parallelogram, script="gh pr create --title {{ goal }}"]
}
```

This is value substitution, not templating. Only those three forms are recognized; every other brace sequence reaches the shell untouched, so `jq` filters, `awk` programs, Go templates, and brace expansion all keep working:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
report [shape=parallelogram, script="kubectl get pod -o go-template='{{ .status.phase }}' | jq '{phase: .}'"]
```

There is no `{% if %}`, no filters, and no loops, and `{{ goal }}` has no dotted form — `{{ goal.title }}` stays literal. Put branching in a [conditional node](/workflows/stages-and-nodes#conditional) or in the shell itself.

In a shell script, Fabro quotes each substituted value as one shell argument. Put the token where one shell word is valid. Do not add quotes around the token, and do not use a token to inject multiple flags or shell syntax:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
build [shape=parallelogram, script="docker build -t {{ inputs.image }} ."]
```

For `language="python"`, Fabro inserts each value as a quoted string literal. Put the token where a Python expression is valid:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
report [shape=parallelogram, language="python", script="print({{ goal }})"]
```

Substituted text is never scanned again, so a goal or input containing `{{ ... }}` reaches the command as literal characters rather than being interpolated a second time.

### `env` and `secrets` are not substituted

`{{ env.NAME }}` and `{{ secrets.NAME }}` are rejected in a `script` with a validation error. Read environment variables with `$NAME` in a shell script:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
deploy [shape=parallelogram, script="deploy --token $DEPLOY_TOKEN"]
```

In a Python script, read them with `os.environ["NAME"]`.

To make a secret available that way, put it in the [environment's env map](/execution/run-configuration#run-environment-and-environments-slug), where `{{ secrets.* }}` does resolve — at run start, into the sandbox environment rather than into the script text:

```toml title="run.toml" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
[environments.ci.env]
DEPLOY_TOKEN = "{{ secrets.DEPLOY_TOKEN }}"
```

This keeps secret values out of the `command.started` event, which records the script verbatim.

### When values resolve

Inputs and variables are substituted when the run is created, at the same time as goals and prompts — the persisted workflow already contains the final script. An unbound input or variable is a warning from `fabro validate` and an error at run creation, so a run never executes a partially substituted command.

## Server-managed run config variables

Use server-managed variables for non-sensitive values that should be shared across runs, such as deployment environments, default branches, regions, or image tags:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro variable set DEPLOY_ENV staging --description "Deployment target"
```

Run configuration strings, graph goals, root model stylesheets, and node prompts can reference these values with `{{ vars.NAME }}`:

```toml title="workflow.toml" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
_version = 1

[run]
goal = "Deploy {{ vars.DEPLOY_ENV }}"
```

```dot title="deploy.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Deploy {
    graph [goal="Deploy to {{ vars.DEPLOY_ENV }}"]
    deploy [prompt="Deploy the requested release to {{ vars.DEPLOY_ENV }}."]
}
```

Variables are intentionally readable: `fabro variable list` and `fabro variable get DEPLOY_ENV` show stored values. Do not store tokens, API keys, or credentials as variables; use `fabro secret set` for sensitive values.

Server-managed variables are stored in the shared SQLite database. When upgrading from file-backed storage, Fabro imports `<storage_root>/variables.json` once; existing SQLite rows win on name conflicts. After a successful import, the source file is renamed to `variables.json.imported-<timestamp>.bak`.

The server snapshots the variable store when it creates the run. Changing a variable later does not rewrite that run's rendered goal, imported prompts, or `@file` prompt and goal contents.

## `goal`

Agent and prompt nodes also receive the workflow goal at runtime:

```dot title="example.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Example {
    graph [goal="Implement the login feature"]

    plan [label="Plan", prompt="Create a plan for: {{ goal }}"]
}
```

That prompt becomes `Create a plan for: Implement the login feature`.

A graph goal cannot contain `{{ goal }}` because that would reference itself. `fabro validate` reports `goal_self_reference` as an error; put the reusable text in an input or server-managed variable instead.

## Expansion timing

Fabro keeps workflow structure static and renders workflow templates once:

1. Fabro parses the root DOT and imported `.fabro` files without rendering them.
2. Literal `import`, `@file`, graph-goal file, and child-workflow references are resolved.
3. The graph `goal` is rendered with the `{ inputs, vars }` context.
4. Node `prompt` attributes are rendered with the `{ goal, inputs, vars }` context.
5. The root `model_stylesheet` is rendered with the `{ inputs, vars }` context, then parsed and applied.
6. Node `script` attributes have their `{{ goal }}`, `{{ inputs.* }}`, and `{{ vars.* }}` values substituted.

Templates are not supported in graph syntax, node IDs, edge structure, `import` paths, `@file` paths, child workflow paths, other file references, or any attribute besides `prompt`, `goal`, and the root `model_stylesheet` — and `script`, which takes value substitution rather than templates.

Command `stdin_source` values are literal context keys. Fabro resolves them at
stage execution time, after upstream nodes have updated the workflow context.

Fabro renders the graph `goal` first and stores the rendered value back onto the graph. Prompts that use `{{ goal }}` receive that rendered value.

## Undefined variables

Fabro renders undefined workflow variables as empty text and records a `template_undefined_variable` diagnostic. `fabro validate` reports that diagnostic as a warning so you can validate workflow structure before all inputs are known. Offline validation does not read a server's variable store, so `{{ vars.* }}` references also warn there. Run-style commands such as `fabro run`, `fabro create`, and preflight use the server snapshot and promote any still-undefined reference to an error before proceeding.

In a `script`, an undefined value records the same diagnostic but leaves the token in place rather than emptying it, so validation output shows what is unbound.

## Template includes

Prompt, goal, and root model stylesheet templates support static MiniJinja loader dependencies such as `{% include "partial.md" %}`. Includes are resolved relative to the template file being rendered and can be nested.

Fabro discovers those static dependencies while building the run manifest so sandbox providers receive every required template file. Dynamic loader expressions such as `{% include inputs.partial %}` are rejected; use a literal include path and choose content with normal template conditionals instead.

## Escaping

To emit literal template syntax, use MiniJinja escaping:

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
test [prompt="{% raw %}{{ goal }}{% endraw %}"]
```

You can also emit literal braces with expressions such as `{{ '{{' }}` when needed.

## Input merging

TOML `[run.inputs]` tables intentionally replace the inherited map wholesale rather than merging by key. Whichever TOML layer has the highest precedence and sets `[run.inputs]` wins its entire map.

CLI input flags are different: they are sparse per-key overrides applied after config resolution, so unrelated inherited inputs remain available. If a key is repeated on the CLI, the last value wins.

| Source                                                                    | Priority |
| ------------------------------------------------------------------------- | -------- |
| CLI flags (`-I key=value` / `--input key=value`, repeated; per-key merge) | Highest  |
| `workflow.toml` `[run.inputs]`                                            |          |
| `.fabro/project.toml` `[run.inputs]`                                      |          |
| `~/.fabro/settings.toml` `[run.inputs]`                                   | Lowest   |
