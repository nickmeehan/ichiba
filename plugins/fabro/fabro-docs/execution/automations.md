> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Automations

> Named, repeatable run configurations with API and schedule triggers

An **automation** is a saved run configuration — a Git repository, working branch, optional tag or exact commit, workflow, and server-managed environment — plus the triggers that may start it. When a trigger fires, Fabro packages the selected workflow as an immutable workflow version and admits it through the same `RunIntent` pipeline as `POST /api/v1/runs`. Automation runs therefore get the same lifecycle, events, and observability as manually created runs. Each run records the automation and trigger that created it.

## Defining automations

The server stores automations in its SQLite database. Manage them in the web UI at `/automations` or through the `/api/v1/automations` REST API.

New definitions use Fabro's canonical Git run target. The working branch is always required. An optional tag selects that tag when no exact commit is present, and an optional 40-character commit SHA pins the run exactly. The exact commit wins when both a tag and SHA are present; the branch is retained as the run's working branch in every case.

```json title="Create automation request" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
{
  "id": "nightly-release",
  "name": "Nightly release",
  "description": "Cut a nightly build from main",
  "environment_id": "ci",
  "target": {
    "kind": "git",
    "repo": "fabro-sh/fabro",
    "branch": "main",
    "tag": "v1.2.3",
    "sha": "0123456789abcdef0123456789abcdef01234567"
  },
  "workflow": "release",
  "triggers": [
    { "type": "api", "id": "manual", "enabled": true }
  ]
}
```

Automations currently support Git targets only. Folder and empty run targets are rejected during validation.

### Environment selection

Every new or edited automation must select a server-managed Docker or Daytona environment. Local environments are intentionally unavailable because automation Git targets require a clone-based provider. Fabro validates that the selected environment exists, uses a compatible provider, and is enabled and ready on the server.

The automation stores the environment ID rather than a copy of its settings. Each trigger fire resolves the current environment definition and snapshots those settings into the new run. Deleting an environment that an automation still references returns a conflict; edit or delete the automation first.

### Workflow resolution

An extensionless workflow such as `"release"` resolves directly to `.fabro/workflows/release/workflow.toml` in the selected repository checkout. You may also provide an explicit repository-relative workflow path.

Automation admission does not read `.fabro/project.toml`. Put settings needed by the run in the workflow configuration or the selected server environment. Fabro packages the workflow and its runnable dependencies into immutable workflow versions before creating the run.

### Upgrading legacy targets

When upgrading from file-backed automation storage, startup imports every valid `automations/*.toml` file next to the active `settings.toml`. Existing SQLite definitions win on ID conflicts. After a successful import, Fabro renames the directory to a timestamped backup such as `automations.imported-20260711T180000000000Z.bak`. Invalid TOML or an invalid target leaves the original directory untouched for operator repair.

The legacy files use this shape:

```toml title="automations/nightly-release.toml" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
name = "Nightly release"
description = "Cut a nightly build from main"

[target]
repository = "fabro-sh/fabro"
ref = "main"
workflow = "release"

[[triggers]]
type = "api"
id = "manual"
enabled = true

[[triggers]]
type = "schedule"
id = "nightly"
enabled = true
expression = "0 0 * * *"
```

Fabro converts legacy refs deterministically:

* A 40-character hexadecimal SHA becomes an exact commit on working branch `main`.
* `refs/tags/<name>` and `tags/<name>` become a tag on working branch `main`.
* `refs/heads/<name>` and `heads/<name>` become a working branch.
* `HEAD` becomes working branch `main`.
* Any other bare value becomes a working branch.

The `main` default is only a migration assumption. If the repository uses another working branch, edit the imported automation before running it.

The same conversion runs transactionally for automations already in SQLite. An unsupported `refs/*` selector or an invalid branch or tag name aborts startup with an actionable error instead of guessing. The database remains on its previous schema and data, and the migration snapshot remains available. Edit the unsupported legacy `target_ref` to a branch, head selector, tag selector, `HEAD`, or exact SHA, then restart Fabro.

Automations created before environment selection was introduced are backfilled conservatively. Fabro selects a compatible environment named `default` when one exists, or the sole Docker or Daytona environment when there is exactly one. With no compatible environment or multiple ambiguous choices, the automation remains incomplete until an operator selects one in the web UI. An incomplete automation cannot run.

When a trigger fires, Fabro prepares the repository at the selected branch, tag, or exact commit, packages the workflow, and creates and starts the run. The created run records the exact checked-out commit in its canonical target, so later inspection and automation creation preserve the revision that actually ran. Repositories are cached server-side as bare clones, so repeat fires fetch only what changed.

## Triggers

Each trigger has an `id` and its own `enabled` flag. Trigger-level `enabled` is the sole activation control — there is no automation-level master switch.

### API triggers

`POST /api/v1/automations/{id}/runs` creates and starts a run through the automation's API trigger. The request is rejected with a conflict when the automation has no enabled API trigger. The Run button on automation cards and detail pages in the web UI uses the same endpoint.

### Schedule triggers

`expression` is a five-field cron expression evaluated in UTC:

```toml theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
[[triggers]]
type = "schedule"
id = "weekday-mornings"
enabled = true
expression = "0 9 * * 1-5"
```

The server fires each enabled schedule trigger at its next occurrence and creates and starts a run. Creating, editing, or deleting an automation takes effect immediately — no restart needed. If a fire fails (for example, because its environment is unavailable or workflow packaging fails), Fabro stores the failure on the automation as `last_error`, logs it, and waits for the next occurrence rather than retrying. The error is cleared after a later scheduled run is queued successfully.

## Web UI

The `/automations` area lists automations with create, edit, delete, and Run actions. The create and edit forms require a Docker or Daytona environment. Migrated automations without an environment are shown as incomplete and cannot run until edited. Saves are revision-checked, so concurrent edits fail loudly instead of silently overwriting each other. The detail page shows the automation's configuration, its most recent schedule error, and its run history with status, time, and repo filters.

To bootstrap an automation from work you have already run, open a run's actions menu and choose **Create automation from run** — the new-automation form is pre-filled from that run's repository and workflow. Runs that were created by an automation show **View automation** instead.

## API

`/api/v1/automations` provides full CRUD: list, create, fetch, replace, and delete. `environment_id` is required in create and replace requests. Automation responses may return a null environment only for an incomplete migrated definition, and expose the latest scheduled-run failure through `last_error`. Responses carry an `ETag` revision; `PUT` and `DELETE` require a matching `If-Match` header. `GET /api/v1/automations/{id}/runs` lists the automation's runs newest-first with standard pagination.
