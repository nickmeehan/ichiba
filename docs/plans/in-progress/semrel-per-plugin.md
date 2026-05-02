# Plan — Per-plugin semantic-release ("bump everything")

Status: proposed (not implemented)

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
  into separate commits, each with its own scope.
- Shared/infra changes (`bin/`, `.github/`, top-level docs) use unscoped types
  (`ci:`, `chore:`, `docs:`) and never trigger a release.

## Tooling

- **`semantic-release`** — release engine.
- **`semantic-release-monorepo`** — filters commits by path so each plugin gets
  its own analyzer/notes scope.
- **`@semantic-release/commit-analyzer`** + **`@semantic-release/release-notes-generator`**
  — determine bump type and write notes.
- **`@semantic-release/exec`** — shell out to a small script that updates the
  three version locations.
- **`@semantic-release/git`** — commit the version changes back to `main`.
- **`@semantic-release/github`** — create the GitHub Release per plugin.

A `package.json` is added at the repo root solely to host these dev
dependencies. No runtime JavaScript.

## Per-plugin release pipeline

For each plugin directory we run a separate `semantic-release` invocation with
`semantic-release-monorepo` filtering commits to that plugin's path. Each plugin
maintains its own tag namespace (`<plugin>-v<semver>`).

Steps inside one plugin's pipeline:

1. **Analyze commits** scoped to `<plugin>` since the last `<plugin>-v*` tag.
2. **Determine next version** (skip if no releasable commits).
3. **`@semantic-release/exec` prepareCmd** — invoke
   `bin/release-bump.sh <plugin> <next-version>`:
   - Write `version` into `plugins/<plugin>/.claude-plugin/plugin.json`.
   - Write the same `version` into the matching `plugins[]` entry in
     `.claude-plugin/marketplace.json`.
   - Bump the **top-level** `version` field in `marketplace.json` by the same
     bump type (or always patch — see open question below).
4. **`@semantic-release/git`** commits those three files with
   `chore(release): <plugin> <version> [skip ci]`.
5. **`@semantic-release/github`** creates a GitHub Release tagged
   `<plugin>-v<version>`.

When several plugins have releasable commits in the same CI run, pipelines run
sequentially so the marketplace top-level version increments cleanly without
write conflicts.

## CI workflow

New workflow `.github/workflows/release.yml`:

- Triggers on `push` to `main`.
- Job 1: discover plugins (`ls -d plugins/*/`) → matrix output.
- Job 2 (per plugin, sequential, `max-parallel: 1`):
  - Checkout with full history (`fetch-depth: 0`) and a token that can push
    back to `main` (GitHub App token preferred over a PAT).
  - Install Node, install root dev deps.
  - Run `npx semantic-release --extends ./release.config.js` with
    `PLUGIN=<name>` so the config knows which plugin to release.

Branch protection on `main` must allow the release bot's pushes (either via
exempting an app or by signing commits with a GitHub App token).

## Initial migration

1. Tag every existing plugin at its current version so semrel has a baseline:
   `docs-kb-v1.0.0`, `dev-workflow-v1.0.0`, `maven-v1.0.0`, `claude-components-v1.0.0`
   (use the actual current versions from each `plugin.json`).
2. Tag the marketplace at its current top-level version: `marketplace-v<x.y.z>`.
3. Add `package.json`, `release.config.js`, `bin/release-bump.sh`, and
   `.github/workflows/release.yml`.
4. Update `CLAUDE.md`:
   - Replace the manual "Plugin Version Rules" section with a pointer to this
     plan and a short note that versions are bumped automatically by CI from
     scoped Conventional Commits.
   - Document the scope-per-plugin commit rule.
5. Update the `dev-workflow:commit` skill to require a plugin scope when any
   `plugins/<name>/**` file is staged, and to forbid cross-plugin commits.

## Open questions

- **Marketplace top-level bump strategy.** Three options:
  1. Always patch-bump on any plugin release. Simplest, but the marketplace
     version stops carrying semver meaning.
  2. Mirror the maximum plugin bump in the same CI run (major > minor > patch).
     Closer to today's intent, more code.
  3. Drop the top-level marketplace version concept entirely and rely on
     per-plugin tags only. Cleanest but a rules change.

  Recommendation: start with (1) — it preserves the field for
  `extraKnownMarketplaces` cache invalidation without overloading it.

- **Multi-plugin commits.** Enforced by lint (`commitlint` with a custom rule
  that rejects commits touching more than one `plugins/<name>/` subtree), or
  enforced socially via the commit skill. Recommendation: lint, because human
  habits drift.

- **Push-back authentication.** GitHub App token is the standard answer; a
  fine-grained PAT scoped to this repo is the fallback.

- **Failure mode for unrecognized scopes.** If a commit uses
  `feat(unknown-plugin):`, the release should fail loudly rather than silently
  skipping.

## Out of scope

- Publishing to a registry (this repo is consumed via
  `extraKnownMarketplaces`, not npm).
- Changelog files inside each plugin directory — release notes live on the
  GitHub Release.
- Pre-release / beta channels.
