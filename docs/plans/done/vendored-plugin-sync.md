# Plan — Vendored plugin sync (fabro from nickmeehan/dark-factory)

Status: done

## Goal

Distribute plugins that live in their own repos through this marketplace
without giving them a second, competing version series. The upstream repo
owns the plugin version (dark-factory runs its own semantic-release and tags
`vX.Y.Z`); this repo adopts that version verbatim. The top-level marketplace
version still bumps through the same `bin/marketplace-bump.sh` bookkeeping
that per-plugin semantic-release uses (via `bin/release-bump.sh`), so
consumers see a marketplace release exactly as they would for a native
plugin — and `release.yml` stays the only workflow that writes release
state (tags, GitHub Releases, the marketplace version).

First (and currently only) vendored plugin: `fabro`, developed in
[nickmeehan/dark-factory](https://github.com/nickmeehan/dark-factory).

## Why not semantic-release

semantic-release computes the next version from this repo's commit history;
it cannot adopt an externally chosen version. If sync commits were scoped
conventional commits (`feat(fabro): sync upstream`), fabro would get an
ichiba-local version series that diverges from upstream's — exactly the
double-bump this design avoids. (Mapping the upstream version delta to a
commit type so semantic-release re-derives the same number breaks as soon
as upstream cuts two patch releases between syncs.) So the vendored path
splits in two: the sync workflow *proposes* (adopts upstream content and
version onto main), and `release.yml` *finalizes* (marketplace bump, tag,
GitHub Release) — mirroring the merge-then-release shape native plugins
already have.

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
`workflow_dispatch`) is the *proposer* — it gets upstream content onto
`main` and nothing else, all via `bin/sync-vendored-plugin.sh`:

1. Find the newest upstream `vX.Y.Z` tag. If it already matches the
   marketplace entry version, exit as a no-op. Upstream commits without a
   release tag deliberately never sync — unreleased states don't ship.
2. Clone the tag; sanity-check `plugin.json` (name matches, version matches
   the tag).
3. Mirror the release into `plugins/fabro/` (wholesale replace, so upstream
   deletions propagate; `.git`, `.github`, `.claude`, `.gitignore`, and
   `node_modules` are pruned).
4. Upsert the `marketplace.json` entry: version adopted verbatim from the
   upstream tag, description kept in sync with upstream. The top-level
   marketplace version is **not** touched.
5. Workflow validates (`claude plugin validate`) and pushes a plain
   `chore(vendor): fabro <version>` commit to `main` — no `[skip ci]`, no
   tag, no GitHub Release. The push is made with `RELEASE_TOKEN`, so it
   triggers workflows like any human push.

Release finalization is the *finalizer* leg of `release.yml`, reached via
that push like any other push to `main`. The `finalize-vendored` job runs
`bin/finalize-vendored-releases.sh`: for every vendored plugin whose
marketplace entry version has no matching `<plugin>-v<version>` tag, it
bumps the top-level marketplace version via the shared
`bin/marketplace-bump.sh` (patch; minor on the plugin's first-ever
release — the same script `bin/release-bump.sh` calls for native
plugins), commits `chore(release): fabro <version> [skip ci]`, tags
`fabro-v<version>`, pushes, and creates a GitHub Release — the same shape
semantic-release produces for native plugins. The finalize job runs after
the semantic-release matrix (`needs: release`) so pushes to `main` within
a run are serialized, but with `if: !cancelled()` so a native release
failure never blocks a vendored release, or vice versa.

Finalize detection is state-based (entry version vs tags), not
commit-based: a finalize run that fails halfway self-heals on the next
push to `main`. The sync workflow still shares the `release` concurrency
group with release.yml, so its content push never races a release run.

## Failure modes

- Tag `fabro-v<version>` already exists here but the marketplace entry says
  otherwise (upstream rollback or re-tag): the sync script refuses; a human
  resolves it.
- Upstream `plugin.json` disagreeing with its own release tag: refused.
- Sync commit lands but finalization fails (or the runner dies between the
  two): main briefly has content without a tag or marketplace bump; the
  next push to main re-runs `finalize-vendored` and completes it.
- dark-factory is public, so the upstream clone is unauthenticated. If it
  ever goes private, the sync step needs a token with read access (e.g.
  `gh auth setup-git` with `RELEASE_TOKEN` before the sync step).
