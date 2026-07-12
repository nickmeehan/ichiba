# Plan — Vendored plugin sync (fabro from nickmeehan/dark-factory)

Status: done

## Goal

Distribute plugins that live in their own repos through this marketplace
without giving them a second, competing version series. The upstream repo
owns the plugin version (dark-factory runs its own semantic-release and tags
`vX.Y.Z`); this repo adopts that version verbatim. The top-level marketplace
version still bumps through the same `bin/release-bump.sh` bookkeeping that
per-plugin semantic-release uses, so consumers see a marketplace release
exactly as they would for a native plugin.

First (and currently only) vendored plugin: `fabro`, developed in
[nickmeehan/dark-factory](https://github.com/nickmeehan/dark-factory).

## Why not semantic-release

semantic-release computes the next version from this repo's commit history;
it cannot adopt an externally chosen version. If sync commits were scoped
conventional commits (`feat(fabro): sync upstream`), fabro would get an
ichiba-local version series that diverges from upstream's — exactly the
double-bump this design avoids.

## Design

`.github/vendored-plugins` (`<plugin-name> <owner/repo>` per line) is the
single source of truth, consumed by:

- `bin/list-releasable-plugins.sh` — feeds release.yml's discover step;
  vendored plugins never enter the semantic-release matrix.
- `commitlint.config.js` — vendored plugin names are removed from
  `scope-enum`; changes to a vendored plugin belong upstream.
- The per-plugin sync workflow (by convention; the workflow names the
  plugin and upstream repo explicitly).

Sync pipeline (`.github/workflows/sync-fabro.yml`, daily cron + manual
`workflow_dispatch`), all via `bin/sync-vendored-plugin.sh`:

1. Find the newest upstream `vX.Y.Z` tag. If it already matches the
   marketplace entry version, exit as a no-op. Upstream commits without a
   release tag deliberately never sync — unreleased states don't ship.
2. Clone the tag; sanity-check `plugin.json` (name matches, version matches
   the tag).
3. Mirror the release into `plugins/fabro/` (wholesale replace, so upstream
   deletions propagate; `.git`, `.github`, `.claude`, `.gitignore`, and
   `node_modules` are pruned).
4. Upsert the `marketplace.json` entry (description kept in sync with
   upstream), then run `bin/release-bump.sh fabro <version>`: entry version
   set to the upstream version, top-level marketplace version bumped —
   patch, or minor on the plugin's first-ever release.
5. Workflow validates (`claude plugin validate`), commits directly to
   `main` as `chore(release): fabro <version> [skip ci]`, tags
   `fabro-v<version>`, pushes, and creates a GitHub Release — the same
   shape semantic-release produces for native plugins.

The sync workflow shares the `release` concurrency group with release.yml,
so version-bumping pushes to `main` are serialized.

## Failure modes

- Tag `fabro-v<version>` already exists here but the marketplace entry says
  otherwise (upstream rollback or re-tag): the script refuses; a human
  resolves it.
- Upstream `plugin.json` disagreeing with its own release tag: refused.
- dark-factory is public, so the upstream clone is unauthenticated. If it
  ever goes private, the sync step needs a token with read access (e.g.
  `gh auth setup-git` with `RELEASE_TOKEN` before the sync step).
