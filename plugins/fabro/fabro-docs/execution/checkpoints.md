> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Checkpoints

> How Fabro uses Git to checkpoint and resume workflow runs

Fabro records every workflow run in the durable run store. With run branches enabled, it also commits file changes inside the run workspace after each node completes. GitHub targets push those commits to the run branch; local runs keep them in their workspace. A local-folder run works in a clone of the folder's committed `HEAD`, so uncommitted changes are not included, and a folder that is not a Git repository starts as an empty workspace.

## Code and execution history

Fabro stores code and execution state separately:

| Storage | Contains |
| - | - |
| **Run branch** (`fabro/run/{run_id}`) | File changes made by agents and commands |
| **Durable run store** | Events and event-derived projections for checkpoints, stages, configuration, and conclusions |
| **Content-addressed store (CAS)** | Artifact and offloaded context payloads referenced by events and checkpoints |

The run branch is a regular Git branch. Checkpoint events record its commit SHAs, which link execution state to the corresponding code.

### Run branch commits

After each node finishes, Fabro stages file changes and creates a commit on the run branch. Files matching `[run.checkpoint] exclude_globs` patterns (configured in [run.toml](/execution/run-configuration#runcheckpoint) or [settings.toml](/administration/server-configuration#runcheckpoint-section)) are excluded from staging:

```
fabro(01JKXYZ...): plan (succeeded)

Fabro-Run: 01JKXYZ...
Fabro-Completed: 2
```

The commit message follows a structured format:

| Part | Description |
| - | - |
| Subject line | `fabro({run_id}): {node_id} ({status})` |
| `Fabro-Run` trailer | The run ID |
| `Fabro-Completed` trailer | Number of completed nodes so far |

The `git_commit_sha` in a `checkpoint.completed` event identifies the run branch commit. New commits do not include a `Fabro-Checkpoint` trailer.

Fabro disables Git commit and tag signing for checkpoint commits created inside a sandbox. Your personal or repository-level signing settings can stay enabled, but sandbox bookkeeping does not need access to your signing key.

Checkpoint commits and any commit a workflow command or agent creates all carry the run's one resolved Git identity. Fabro derives it from the run's GitHub App bot account or token user, or from the generic `Fabro <noreply@fabro.sh>` identity when the run has no GitHub credential, and `[run.git.author]` overrides it. See [`[run.git.author]`](/administration/server-configuration#rungitauthor-section).

### Durable execution state

Fabro derives run state from persisted events. The projection includes the run spec, start and status records, checkpoints, stage results, conclusion, and sandbox information. Artifact payloads live in CAS.

Use `fabro dump` to export a run as files, including `run.json`, `graph.fabro`, and per-stage artifacts.

### Metadata branch

Fabro no longer creates or pushes `fabro/meta/{run_id}` branches. Existing metadata branches remain untouched. Historical metadata snapshot events remain readable.

## What's in a checkpoint

The checkpoint projection captures the execution state needed to resume a run:

| Field | Description |
| - | - |
| `timestamp` | When the checkpoint was created |
| `current_node` | The node that just completed |
| `next_node_id` | The next node the engine would execute |
| `completed_nodes` | Ordered list of all completed node IDs |
| `node_retries` | How many retry attempts each node has used |
| `node_outcomes` | Full outcome (status, context updates, usage) for each completed node |
| `context_values` | Snapshot of the entire [run context](/execution/context) |
| `git_commit_sha` | SHA of the run branch commit at this checkpoint |
| `loop_failure_signatures` | Failure signature counts for loop detection |
| `restart_failure_signatures` | Failure signature counts across loop-restart edges |

The durable run store also keeps the current checkpoint so `resume`, `inspect`, and API reads do not need to rely on scratch files.

## Run workspaces

A GitHub target is checked out inside the run workspace. For Docker and Daytona, checkout, checkpoint commits, diffs, and pushes execute inside the sandbox. The host provider performs those operations in its local run workspace. Fabro keeps no second checkout, bare snapshot repository, or Git checkpoint bundle on the server for a remote sandbox.

When pushing is configured, Fabro pushes `fabro/run/{run_id}` after each checkpoint and again before successful completion. Execution records and artifact payloads remain in the run store and CAS.

Ordinary resume requires the original workspace to survive. Git-backed workspaces reset to their recorded checkpoint; non-Git workspaces continue with their surviving files. Losing the workspace does not trigger automatic reconstruction or sandbox replacement.

A GitHub-backed fork or rewind fetches the source run's published branch inside a fresh workspace and checks out the selected checkpoint. This requires run-branch pushes to be enabled and the commit to be available on origin. Select a checkpoint with remaining work: the final terminal checkpoint is refused because no stage remains to acquire a workspace. A retry starts the workflow from the beginning using its saved specification, without requiring the previous workspace or any Git checkpoint.

## Resuming a run

Resume an interrupted run from its durable checkpoint:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro resume 01JKXYZ
```

Fabro resolves the run by ID prefix, validates that durable state contains a checkpoint, and asks the server to continue execution. No workflow file or override flags are needed — all configuration is restored from persisted state.

<Accordion title="What happens during resume">
  1. Fabro looks up the run directory by ID prefix
  2. Validates that a checkpoint exists in durable state and no engine process is already running
  3. Cleans stale local artifacts from the previous execution
  4. Resets status to `Submitted` and spawns a new engine subprocess with `--resume`
  5. The engine restores the full context, completed node list, retry counts, and failure signatures from durable state
  6. If the checkpointed node used `full` fidelity, downgrades the first resumed node to `summary:high` (since the original conversation thread no longer exists in memory)
  7. Continues execution from `next_node_id`
</Accordion>

### Resuming an in-flight stage

If the latest checkpoint captured a stage that was still running, resume allocates a new stage execution ID instead of rewriting the original history. For example, a resumed `work@1` stage continues as `work@2`, and the new record sets `resumed_from_stage_id = "work@1"`. The earlier stage remains immutable.

The number after `@` is the stage execution ordinal. It is separate from the graph visit count and from a handler's retry attempt, so loops, retries, and resume ancestry can be inspected independently.

## The checkpoint cycle

After a node completes, Fabro:

1. Stores offloaded context payloads in CAS.
2. Creates a code checkpoint commit when Git checkpointing is enabled.
3. Collects the code diff.
4. Emits a checkpoint event with execution state and the code commit SHA. The run store persists this event and updates the projection.

A checkpoint commit failure stops execution. A stage diff failure emits a warning notice. An intermediate push failure warns and is retried at later checkpoints and final publication. Failure to prepare required final publication, push the final commit, or open the pull request marks an otherwise successful run as failed with `publish_failed`.

## Inspecting run history

Because checkpoints are plain Git commits, you can inspect them with standard Git tools:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
# View the commit log for a run
git log fabro/run/01JKXYZ... --oneline

# See what an agent changed at a specific node
git show fabro/run/01JKXYZ...

# Diff the full run against the starting point
git diff main..fabro/run/01JKXYZ...

# Inspect execution state and events
fabro inspect 01JKXYZ
fabro events 01JKXYZ

# Export the run projection and artifacts
fabro dump 01JKXYZ --output ./run-dump
```

## When checkpointing is active

Git checkpointing activates automatically when run branches are enabled and either:

* The run targets a GitHub repository with cloning enabled, or
* The run's workspace is on the host: a Local environment, or any `--dry-run`

It is skipped when:

* Run branches are disabled
* A Docker or Daytona run has no GitHub target, or its cloning is disabled


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.