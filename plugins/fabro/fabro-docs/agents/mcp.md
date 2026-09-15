> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# MCP

> Connect MCP tools to agents and expose Fabro runs to MCP clients

MCP ([Model Context Protocol](https://modelcontextprotocol.io/)) lets you connect external tool servers to Fabro agents. An MCP server exposes tools over a standardized protocol — databases, APIs, file systems, custom services — and Fabro discovers and registers them automatically. Agents call MCP tools the same way they call built-in tools.

Fabro can also run as an MCP server. MCP clients can register reusable workflow versions and use Fabro's run-management tools to create, inspect, control, wait for, and read events from workflow runs through the authenticated `fabro` CLI.

Workflow agents can opt in to that same run-management tool catalog with `[run.agent] fabro_tools = true`. This is not the same as configuring external MCP servers for the agent. When a workflow agent calls `fabro_run_create`, created runs are always [child runs](/execution/child-runs) of the current run; an explicit `parent_id` must match the current run ID.

## Fabro as an MCP server

Use `fabro mcp init` to configure an MCP client to launch Fabro:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro mcp init claude
```

Supported client targets are `claude`, `cursor`, and `windsurf`. The generated configuration launches `fabro mcp start` over stdio and reuses the CLI's normal server selection, OAuth refresh, dev-token handling, proxy behavior, and local storage.

You can also print the MCP configuration JSON or start the server directly:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro mcp config
fabro mcp start
```

Pass `--server` when the MCP client should connect to a specific Fabro server, or `--storage-dir` when it should use a non-default CLI storage directory.

Both commands register the entry under the `mcpServers` key `fabro` by default. Pass `--name` to choose a different key. Each named entry launches its own single-target `fabro mcp start` process, so you can register more than one Fabro server in the same MCP client:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro mcp init claude --name fabro-production --server https://fabro.example.com
fabro mcp init claude --name fabro-testing --server https://fabro-testing.example.com
```

`fabro mcp init` keeps entries with other names and replaces only the entry that matches `--name`.

| Tool                            | Purpose                                                                                                                                    |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `fabro_workflow_version_create` | Register supplied workflow contents and local dependencies as an immutable version ID, without creating a run.                             |
| `fabro_run_create`              | Create one or more workflow runs, optionally under a parent run, starting them by default.                                                 |
| `fabro_run_search`              | Search runs by ID, parent, workflow, labels, status, archive state, and creation time.                                                     |
| `fabro_run_get`                 | Read-only inspection of a run: returns its summary, projection, and pending questions without mutating state.                              |
| `fabro_run_interact`            | Control a run: start, approve, deny, message, interrupt, cancel, archive, unarchive, link or unlink a parent, inspect or answer questions. |
| `fabro_run_gather`              | Wait for runs to reach terminal states, returning current state on timeout.                                                                |
| `fabro_run_pair`                | Inspect, start, message, end, or read transcript for a live run pairing session.                                                           |
| `fabro_run_events`              | List, inspect, or search stored events for a run.                                                                                          |

### Register workflow contents from a sandbox

Use shell and read tools in your sandbox to acquire the workflow and all its local
config, graph, prompt, script, import, and child-workflow files. For example, clone
a repository with your sandbox's shell tool, then read `workflow.fabro` and its
referenced `prompt.md`. Submit the actual contents:

```json theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
{
  "entrypoint": "workflow.fabro",
  "files": {
    "workflow.fabro": "digraph W { start [shape=Mdiamond] work [prompt=\"@prompt.md\"] exit [shape=Msquare] start -> work -> exit }",
    "prompt.md": "Review the implementation."
  }
}
```

Call `fabro_workflow_version_create` with this object and keep the returned
`workflow_version_id`. You can reuse it in a `RunIntent` submitted through the
[Create Run API](/api-reference/runs/create-run). Registration packages and uploads
child workflows before their parents; callers do not calculate dependency IDs.

`entrypoint` is an exact supplied key, including when it has no extension. File
values are text, never host paths or URLs to fetch. Missing references and paths
that escape the supplied tree fail. The source tree is limited to 512 files,
512 KiB per file, and 2 MiB of text; each resulting serialized version must also
fit the existing 2 MiB API limit. Case-insensitive file and ancestor collisions
are rejected before staging. Graph nesting through child workflows and imports
is limited to 64 levels, including the entrypoint. A supplied sibling
`workflow.toml` must be valid even when a graph is the entrypoint; a valid config
that selects another graph is omitted. Collection follows declared file references; command
`script` values remain literal text, and paths embedded in shell commands are not
inspected or acquired.

Registration resolves no runtime secrets, selects no environment, and starts no
execution. It requires a user credential or a worker token with `agent:run_tools`;
ordinary worker tokens and same-run Ask Fabro sessions cannot register versions.
If an upload fails, retry the same contents: previously registered immutable
versions remain reusable. Use the returned ID with `fabro_run_create`.

### Create runs

Call `fabro_run_create` with a registered workflow version ID and an independent
workspace target. You can reuse the same ID for multiple runs without uploading
again:

```json theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
{
  "runs": [{
    "workflow_version_id": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "target": { "kind": "git", "repo": "acme/widgets", "branch": "main" },
    "environment_id": "production",
    "goal": "Review the checkout implementation.",
    "args": {
      "inputs": { "component": "checkout" },
      "labels": { "source": "mcp" },
      "auto_approve": false
    },
    "start": false
  }]
}
```

Standalone MCP calls require an explicit `target`: Git coordinates, `kind: none`
for an empty workspace, or a server-local folder for a compatible Local environment.
A folder path refers to the server's filesystem, not the MCP client's filesystem.
Workflow content does not determine the target. Native workflow-agent calls may
omit `target` to inherit the parent's execution target; see [Child Runs](/execution/child-runs).
Supplying `parent_id` in standalone MCP does not enable that inheritance.

`args` uses the same fields as RunIntent: `inputs`, `labels`, `model`, `provider`,
`dry_run`, `auto_approve`, and `preserve_sandbox`. Omitted boolean overrides stay
omitted; explicit `false` is preserved. `environment_id` selects a server environment;
omission uses the server default. `title`, literal `goal`, and an exact `parent_id`
are optional. Caller/project/machine run settings are not read by the tool.
Workflow-owned settings remain in the registered `workflow.toml`.

<Note>
  Run creation accepts registered IDs only. Replace workflow strings and inline
  sources with a preceding `fabro_workflow_version_create` call. Move flat run
  options into `args`, use `environment_id` instead of `environment`, and send goal
  text instead of `goal_file`. Obtain local or remote files using the caller's own
  shell/read tools. Neither Fabro tool fetches remote sources or reads a caller path.
</Note>

Creation persists a submitted run. A separate start request follows by default;
set `start: false` to start later. Batches contain 1–50 items and stop at the first
failure. If creation succeeded before a start, summary lookup, or later item
failed, the error includes the already-created run IDs. Inspect those runs before
retrying to avoid creating duplicates.

Run summaries returned by the MCP server include parent metadata. Use `parent_id` on `fabro_run_create` to create a child run, `parent_id` on `fabro_run_search` to list direct children, and the `link_parent` or `unlink_parent` actions on `fabro_run_interact` to change an existing run's parent. See [Child Runs](/execution/child-runs) for the orchestration model.

Pending runs can be approved or denied through `fabro_run_interact`:

```json theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
{ "run_id": "nightly", "action": "approve" }
```

```json theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
{
  "run_id": "nightly",
  "action": "deny",
  "reason": "Not approved for execution"
}
```

Use `fabro_run_pair` when an MCP client needs to pair with an active API-mode agent stage. The tool can inspect current pair status, start a pair session for a selected stage, send messages, end the session, and read transcript entries.

```json theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
{
  "action": "start",
  "run_id": "01K...",
  "stage_id": "implement@1"
}
```

## Fabro agents as MCP clients

When an agent session starts with MCP servers configured, Fabro:

1. **Connects** to each server using the configured transport (stdio, HTTP, or sandbox)
2. **Performs the MCP handshake** — exchanging protocol versions and capabilities
3. **Discovers tools** — calls `tools/list` to get every tool the server exposes
4. **Registers tools** — each MCP tool is added to the agent's tool registry with a qualified name

Once registered, MCP tools are indistinguishable from built-in tools to the LLM. The agent sees them in its tool list and can call them during its session.

## Tool naming

MCP tools are registered with a qualified name that combines the server name and original tool name:

```
mcp__{server}__{tool}
```

For example, a server named `filesystem` exposing a `read_file` tool becomes `mcp__filesystem__read_file`. Special characters in server or tool names (hyphens, dots, etc.) are replaced with underscores.

## Agent MCP configuration

MCP servers available to Fabro agents can be configured in two places:

* **User configuration** — `~/.fabro/settings.toml` can define shared workflow MCP servers under `[run.agent.mcps.<name>]`, or `fabro exec`-only servers under `[cli.exec.agent.mcps.<name>]`. See [User Configuration](/reference/user-configuration).
* **Run config TOML** — workflow config can define run-specific MCP servers under `[run.agent.mcps.<name>]`. See [Run Configuration](/execution/run-configuration#runagentmcps).

Each server entry specifies a transport type and optional timeouts. The server name is the TOML table key and is used in qualified tool names.

### Server-managed catalog

Fabro servers can also manage a shared MCP catalog from **Settings → MCP servers** in the web UI or through the MCP servers REST API. Workflows reference a catalog definition by id instead of repeating its transport configuration:

```toml theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
[run.agent.mcps.sentry]
id = "sentry"
```

Server-managed definitions are stored in the server's shared SQLite database. Read APIs return configured env/header names but never their values.

When upgrading an installation that stored definitions as `mcps/*.toml` next to the active `settings.toml`, Fabro validates and imports the directory during startup. Existing SQLite rows win on id conflicts. After a successful transaction, Fabro renames the source directory to a timestamped backup such as `mcps.imported-20260711T120000000000Z.bak`.

Transport env/header values preserve their existing plaintext-at-rest behavior in SQLite. Prefer `{{ secrets.NAME }}` interpolation over literal credentials where possible.

Set `enabled = false` to keep an inline server or catalog reference in configuration without connecting to it:

```toml theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
[run.agent.mcps.sentry]
id = "sentry"
enabled = false
```

## Runtime interpolation

Inline transport fields can interpolate values at the run boundary:

| Syntax               | Resolution time                                                                        |
| -------------------- | -------------------------------------------------------------------------------------- |
| `{{ vars.NAME }}`    | When the server creates the run, using that run's variable snapshot                    |
| `{{ secrets.NAME }}` | When the worker launches the MCP transport, using a token secret from the server vault |

Interpolation applies to stdio and sandbox commands and env values, plus HTTP URLs and headers. Variable tokens are replaced in the created run configuration. Secret expressions remain in persisted configuration, while resolved secret values do not. A missing or non-token secret fails MCP startup instead of passing an unresolved token to the transport. `{{ env.* }}` is unsupported and also fails before launch.

Standalone `fabro exec` has no server vault, so a `{{ secrets.* }}` reference fails with an explicit error in standalone execution.

## Transports

### Stdio

The most common transport. Fabro spawns a child process on the host and communicates over stdin/stdout:

```toml theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
[run.agent.mcps.filesystem]
type = "stdio"
command = ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
startup_timeout = "15s"
tool_timeout = "90s"

[run.agent.mcps.filesystem.env]
NODE_ENV = "production"
```

| Field             | Description                                                              | Default |
| ----------------- | ------------------------------------------------------------------------ | ------- |
| `enabled`         | Whether to connect to this server.                                       | `true`  |
| `type`            | Must be `"stdio"`.                                                       | —       |
| `command`         | Array: the executable followed by its arguments.                         | —       |
| `script`          | Shell script alternative to `command`. Runs on the host through `sh -c`. | —       |
| `env`             | Additional environment variables for the child process.                  | `{}`    |
| `startup_timeout` | Max duration to wait for the MCP handshake.                              | `"10s"` |
| `tool_timeout`    | Max duration for a single tool call.                                     | `"60s"` |

### HTTP

For remote MCP servers accessible over Streamable HTTP:

```toml theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
[run.agent.mcps.sentry]
type = "http"
url = "https://mcp.sentry.dev/mcp"

[run.agent.mcps.sentry.headers]
Authorization = "Bearer sk-xxx"
```

| Field             | Description                                               | Default             |
| ----------------- | --------------------------------------------------------- | ------------------- |
| `enabled`         | Whether to connect to this server.                        | `true`              |
| `type`            | Must be `"http"`.                                         | —                   |
| `protocol`        | HTTP MCP protocol: `"streamable_http"` or legacy `"sse"`. | `"streamable_http"` |
| `url`             | The MCP server endpoint URL.                              | —                   |
| `headers`         | Optional HTTP headers (e.g., for authentication).         | `{}`                |
| `startup_timeout` | Max duration to wait for the MCP handshake.               | `"10s"`             |
| `tool_timeout`    | Max duration for a single tool call.                      | `"60s"`             |

### Sandbox

Runs the MCP server inside the workflow's sandbox (e.g., a [Daytona](/integrations/daytona) cloud VM). Fabro starts the server as a background process, waits for it to listen on the specified port, obtains an authenticated preview URL, and connects via HTTP. This is the right transport for MCP servers that need access to the sandbox environment — for example, [Playwright](https://github.com/microsoft/playwright-mcp) for browser automation.

```toml theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
[run.agent.mcps.playwright]
type = "sandbox"
protocol = "sse"
command = ["npx", "@playwright/mcp@latest", "--port", "3100", "--headless", "--browser", "chromium"]
port = 3100
startup_timeout = "60s"
tool_timeout = "2m"
```

| Field             | Description                                                                                                                          | Default             |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------- |
| `enabled`         | Whether to connect to this server.                                                                                                   | `true`              |
| `type`            | Must be `"sandbox"`.                                                                                                                 | —                   |
| `protocol`        | HTTP MCP protocol exposed by the sandbox server: `"streamable_http"` or legacy `"sse"`.                                              | `"streamable_http"` |
| `command`         | Array: the command to run inside the sandbox. Must include a flag that makes the server listen on `port`.                            | —                   |
| `script`          | Shell script alternative to `command`. Evaluated inside the sandbox by non-login Bash (`bash -c`), like every other sandbox command. | —                   |
| `port`            | The port the MCP server listens on inside the sandbox.                                                                               | —                   |
| `env`             | Additional environment variables for the server process.                                                                             | `{}`                |
| `startup_timeout` | Max duration to wait for the server to start listening and complete the MCP handshake.                                               | `"10s"`             |
| `tool_timeout`    | Max duration for a single tool call.                                                                                                 | `"60s"`             |

The sandbox transport requires a remote sandbox provider (Daytona) that supports preview URLs. During session initialization, Fabro:

1. Launches the server inside the sandbox with `setsid "$BASH" -c` to fully detach the process while reusing the provider-selected Bash
2. Polls until the server is listening on the configured port (up to 30 seconds)
3. Obtains an authenticated preview URL from the sandbox provider
4. Connects to the server over HTTP using the preview URL

## Lifecycle

### Startup

Each MCP server is started sequentially during session initialization. The startup sequence for each server is:

1. **Spawn / connect** — For stdio, spawn the child process. For HTTP, create the HTTP client. For sandbox, start the server inside the sandbox and connect via preview URL.
2. **Handshake** — Perform the MCP protocol handshake within the `startup_timeout` window.
3. **Tool discovery** — Call `tools/list` to enumerate available tools.
4. **Registration** — Add each tool to the agent's registry with its qualified name.

If a server fails to start (process crash, timeout, handshake error), it is logged and skipped. Other servers continue starting normally. The agent session proceeds with whatever tools were successfully registered.

### Tool execution

When the LLM calls an MCP tool:

1. Fabro looks up the qualified name in the connection manager
2. The call is routed to the correct server using the original (unqualified) tool name
3. The server executes the tool and returns a result
4. The result is converted to text and returned to the LLM as a tool result

Tool calls are subject to the `tool_timeout` configured on the server. If a call exceeds the timeout, it fails with a timeout error.

### Content handling

MCP tool results can contain multiple content blocks. Fabro converts them to text:

| Content type | Conversion                         |
| ------------ | ---------------------------------- |
| Text         | Used as-is                         |
| Image        | Replaced with `[image content]`    |
| Audio        | Replaced with `[audio content]`    |
| Resource     | Replaced with `[resource content]` |

If the server marks the result as an error (`is_error: true`), the tool result is returned to the LLM as an error.

## Example: Playwright browser automation

A workflow that uses Playwright MCP to automate a browser inside a Daytona sandbox:

```toml title="run.toml" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
_version = 1

[workflow]
graph = "workflow.fabro"

[run]
goal = "Test the login page"

[run.environment]
id = "cloud"

[environments.cloud]
provider = "daytona"

[run.artifacts]
include = ["screenshots/**"]

[run.agent.mcps.playwright]
type = "sandbox"
protocol = "sse"
command = ["npx", "@playwright/mcp@latest", "--port", "3100", "--headless", "--browser", "chromium"]
port = 3100
startup_timeout = "60s"
tool_timeout = "2m"
```

After startup, the agent sees 22 Playwright tools including:

* `mcp__playwright__browser_navigate`
* `mcp__playwright__browser_click`
* `mcp__playwright__browser_snapshot`
* `mcp__playwright__browser_take_screenshot`
* `mcp__playwright__browser_type`
* `mcp__playwright__browser_fill_form`

The agent uses `browser_snapshot` (accessibility tree) for structured page understanding and `browser_take_screenshot` to save visual captures. Screenshots saved to `screenshots/` can be collected as [artifacts](/execution/run-configuration#runartifacts) by including `screenshots/**`.

<Note>
  When using Playwright MCP with the sandbox transport, call the `browser_install` tool first to ensure the Playwright browser binaries are available inside the sandbox.
</Note>

<Note>
  MCP servers that fail to start do not block the agent session. The agent proceeds with its built-in tools plus any MCP tools from servers that started successfully.
</Note>

## Protocol details

For agent-side MCP connections, Fabro implements the MCP client side using the `rmcp` SDK (protocol version `2025-03-26`). The client identifies itself as `fabro-mcp` and supports:

* Tool listing and invocation
* Server logging notifications (routed to Fabro's tracing system)
* Progress notifications
* Resource update notifications
* Cancellation notifications
