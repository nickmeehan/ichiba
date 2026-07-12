# ichiba Plugin Marketplace

This repo is a Claude Code plugin marketplace distributed via `extraKnownMarketplaces` in consuming projects' `settings.json`.

## Versioning is automated

Plugin versions are bumped automatically by CI from scoped Conventional
Commits — **do not edit `version` fields by hand**. See
[`docs/plans/done/semrel-per-plugin.md`](docs/plans/done/semrel-per-plugin.md)
for the full design.

### Commit messages

Use Conventional Commits with the **plugin directory name** as the scope:

```
feat(docs-kb): add docs-bootstrap skill          → minor bump for docs-kb
fix(maven): handle missing pom.xml gracefully    → patch bump for maven
refactor(dev-workflow)!: rename /commit command  → major bump for dev-workflow
chore(deps): bump prettier                       → no plugin release
ci: tweak validate workflow                      → no plugin release
```

Rules enforced in CI:
- Scope must match an existing `plugins/<name>/` directory (`commitlint`).
- One commit must not touch more than one `plugins/<name>/` subtree
  (`bin/check-plugin-scope.sh`). Split cross-plugin changes into separate
  commits.
- Shared/infra changes (`bin/`, `.github/`, top-level docs) use unscoped
  types (`ci:`, `chore:`, `docs:`) and never trigger a release.

### What gets bumped

When a scoped commit lands on `main`, `release.yml` runs `semantic-release` for
that plugin and updates all three version locations in one commit:

1. `plugins/<plugin-name>/.claude-plugin/plugin.json`
2. The matching entry in `.claude-plugin/marketplace.json` `plugins[]`
3. The top-level `version` in `.claude-plugin/marketplace.json` (patch on
   normal release; minor when the plugin's first-ever release runs)

Each plugin gets its own tag namespace (`<plugin>-v<semver>`) and a GitHub
Release.

### Vendored plugins

Plugins listed in `.github/vendored-plugins` are developed in their own
repos and synced here by a scheduled workflow — they are **not** released
by semantic-release:

- `fabro` — synced daily from
  [nickmeehan/dark-factory](https://github.com/nickmeehan/dark-factory) by
  `.github/workflows/sync-fabro.yml`.

The upstream repo owns the version: the sync workflow vendors the latest
upstream release tag, adopts its version into `marketplace.json`, and bumps
the top-level marketplace version via the same `bin/release-bump.sh`
(patch; minor on first release), then commits straight to `main`, tags
`<plugin>-v<version>`, and creates a GitHub Release.

**Never edit vendored plugin files in this repo** — the next sync
overwrites them; changes belong upstream. Scoped commits (e.g.
`feat(fabro): …`) are rejected by commitlint, and vendored plugins are
excluded from the release matrix (`bin/list-releasable-plugins.sh`) so
semantic-release never re-bumps a version the sync job set. See
[`docs/plans/done/vendored-plugin-sync.md`](docs/plans/done/vendored-plugin-sync.md).

## Schema Validation

**After editing any `plugin.json` or `marketplace.json`**, run:
```bash
claude plugin validate .
claude plugin validate plugins/<plugin-name>
```

A pre-commit hook runs `claude plugin validate` automatically when manifest files are staged. The same validation runs in CI via `.github/workflows/validate.yml`.

## Updating in Consuming Projects

After pushing a version bump, users in consuming projects must run:
```
/plugin update dev-workflow@ichiba
```

If the plugin appears stale despite updating, clear the local cache:
```bash
rm -rf ~/.claude/plugins/cache
```
