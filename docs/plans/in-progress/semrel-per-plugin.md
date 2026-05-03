# Plan — Per-plugin semantic-release ("bump everything")

Status: in progress

## Goal

Replace manual version bumps with automated releases driven by Conventional
Commits. Every change to a plugin produces a release that updates **all three**
version locations required by `CLAUDE.md`:

1. `plugins/<plugin-name>/.claude-plugin/plugin.json` — the plugin's own version
2. The matching plugin entry in `.claude-plugin/marketplace.json`
3. The top-level `version` in `.claude-plugin/marketplace.json`

A single conventional commit on `main` is enough; no humans editing version
strings.

## Commit convention

Use scoped Conventional Commits where the scope is the plugin directory name:

```
feat(docs-kb): add docs-bootstrap skill          → minor bump for docs-kb
fix(maven): handle missing pom.xml gracefully    → patch bump for maven
refactor(dev-workflow)!: rename /commit command  → major bump for dev-workflow
chore(deps): bump prettier                       → no plugin release
ci: tweak validate workflow                      → no plugin release
```

Rules:
- Commits **without** a plugin scope do not produce a release.
- A commit must touch only one plugin's files. Cross-plugin changes are split
  into separate commits, each with its own scope. Enforced in CI by
  `bin/check-plugin-scope.sh`.
- Shared/infra changes (`bin/`, `.github/`, top-level docs) use unscoped types
  (`ci:`, `chore:`, `docs:`) and never trigger a release.
- Scope must match an existing plugin directory name. Enforced by `commitlint`
  via `scope-enum` (read dynamically from `plugins/`).

## Tooling

- **`semantic-release`** — release engine, driven once per plugin via a
  `PLUGIN` env var.
- **`@semantic-release/commit-analyzer`** + **`@semantic-release/release-notes-generator`**
  — determine bump type and write notes. Scoped via a `parserOpts.headerPattern`
  that only parses commits matching the current plugin's scope, so each
  invocation considers only that plugin's commits.
- **`@semantic-release/exec`** — shell out to `bin/release-bump.sh` to update
  the three version locations.
- **`@semantic-release/git`** — commit the version changes back to `main`.
- **`@semantic-release/github`** — create the GitHub Release per plugin.
- **`commitlint`** + **`@commitlint/config-conventional`** — validate commit
  messages on PRs (catches unknown scopes, missing types, etc.).

A `package.json` is added at the repo root solely to host these dev
dependencies. `pnpm` is the package manager (`packageManager` field). No
runtime JavaScript.

## Per-plugin release pipeline

For each plugin directory we run a separate `semantic-release` invocation with
`PLUGIN=<name>`. The release config narrows the commit parser to that plugin's
scope, so commits scoped to other plugins are ignored. Each plugin maintains
its own tag namespace (`<plugin>-v<semver>`).

Steps inside one plugin's pipeline:

1. **Analyze commits** scoped to `<plugin>` since the last `<plugin>-v*` tag.
2. **Determine next version** (skip if no releasable commits).
3. **`@semantic-release/exec` prepareCmd** — invoke
   `bin/release-bump.sh <plugin> <next-version>`:
   - Write `version` into `plugins/<plugin>/.claude-plugin/plugin.json`.
   - Write the same `version` into the matching `plugins[]` entry in
     `.claude-plugin/marketplace.json`.
   - Bump the **top-level** `version` field in `marketplace.json`:
     - **Minor** if no prior `<plugin>-v*` tag exists (this is the plugin's
       first release / a new plugin coming online).
     - **Patch** otherwise.
4. **`@semantic-release/git`** commits those three files with
   `chore(release): <plugin> <version> [skip ci]`.
5. **`@semantic-release/github`** creates a GitHub Release tagged
   `<plugin>-v<version>`.

When several plugins have releasable commits in the same CI run, pipelines run
sequentially (`max-parallel: 1`) so the marketplace top-level version
increments cleanly without write conflicts.

## CI workflow

New workflow `.github/workflows/release.yml`:

- Triggers on `push` to `main`.
- Job 1: discover plugins (`ls -d plugins/*/`) → matrix output.
- Job 2 (per plugin, sequential, `max-parallel: 1`):
  - Checkout with full history (`fetch-depth: 0`) and `RELEASE_TOKEN` (a
    fine-grained PAT scoped to this repo) so the bot can push back to `main`.
  - Install Node 24, install root dev deps with `pnpm install --frozen-lockfile`.
  - Run `pnpm exec semantic-release` with `PLUGIN=<name>` so the config knows
    which plugin to release.

The release commits go **directly** to `main` (no PR). Branch protection on
`main` must allow `RELEASE_TOKEN`'s identity to bypass any "require PR" rule.

The validate workflow runs `commitlint` and `bin/check-plugin-scope.sh` on PRs
so unknown scopes and cross-plugin commits never reach `main`.

## Decisions (resolved open questions)

- **Marketplace top-level bump strategy.** Patch on every plugin release;
  minor when a plugin's first release happens (no prior `<plugin>-v*` tag).
  Preserves the field for `extraKnownMarketplaces` cache invalidation and
  signals "new plugin came online" without overloading semver.
- **Multi-plugin commit enforcement.** Commitlint in CI enforces scope-enum
  (catches typos like `feat(maevn):`). A separate CI step
  (`bin/check-plugin-scope.sh`) rejects commits whose file diff spans more
  than one `plugins/<name>/` subtree. The `dev-workflow:commit` skill stays
  generic — it ships to other repos and must not contain ichiba-specific
  logic.
- **Push-back authentication.** Fine-grained PAT stored as repo secret
  `RELEASE_TOKEN`, with permissions `contents: write` and
  `pull-requests: write`. Migrate to a GitHub App later if PAT expiry becomes
  annoying.
- **Failure mode for unrecognized scopes.** Commitlint blocks the PR before
  merge. Belt-and-braces: the release workflow's matrix is built from
  `plugins/*`, so a scope referring to a nonexistent plugin is simply never
  released.

## Initial setup (one-time)

1. Tag every existing plugin at its current version so semrel has a baseline:
   - `dev-workflow-v1.2.2`
   - `docs-kb-v1.0.4`
   - `maven-v1.0.5`
2. Tag the marketplace at its current top-level version: `marketplace-v1.7.5`.
3. Add `package.json`, `release.config.js`, `commitlint.config.js`,
   `bin/release-bump.sh`, `bin/check-plugin-scope.sh`,
   `.github/workflows/release.yml`. Update `.github/workflows/validate.yml`
   to also run commitlint.
4. Update `CLAUDE.md`:
   - Replace the manual "Plugin Version Rules" section with a pointer to this
     plan and a short note that versions are bumped automatically by CI from
     scoped Conventional Commits.
   - Document the scope-per-plugin commit rule.
5. Create the `RELEASE_TOKEN` repo secret and configure branch protection
   bypass for that identity.

## Out of scope

- Publishing to a registry (this repo is consumed via
  `extraKnownMarketplaces`, not npm).
- Changelog files inside each plugin directory — release notes live on the
  GitHub Release.
- Pre-release / beta channels.
- Modifying the `dev-workflow:commit` skill — it's distributed to other repos
  and stays project-agnostic.
