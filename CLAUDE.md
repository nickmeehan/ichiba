# ichiba Plugin Marketplace

This repo is a Claude Code plugin marketplace distributed via `extraKnownMarketplaces` in consuming projects' `settings.json`.

## Plugin Version Rules

**Whenever you change anything in a plugin** (skills, prompts, hooks, MCP config, or any other file), you MUST bump the version in **all three** of these places:

1. `plugins/<plugin-name>/.claude-plugin/plugin.json` — the plugin's own version
2. `.claude-plugin/marketplace.json` — the matching version in the plugin's entry under `"plugins"`
3. `.claude-plugin/marketplace.json` — the top-level `"version"` field for the marketplace itself

The plugin version (items 1 and 2) must stay in sync. The marketplace version (item 3) must also be bumped whenever any plugin is added, removed, or updated.

Use semantic versioning (`MAJOR.MINOR.PATCH`):
- Patch bump (`1.0.0` → `1.0.1`): bug fixes, wording changes, minor skill tweaks
- Minor bump (`1.0.0` → `1.1.0`): new skills, commands, or agents added; new plugin added to marketplace
- Major bump (`1.0.0` → `2.0.0`): breaking changes or complete rewrites

## Docs

Scan the index below on every turn. If an entry is relevant, read the file before responding.
Do not guess — retrieve first. For deeper topics, use the docs-kb:doc-traversal agent starting at `docs/_index.md`.

<!-- DOCS-INDEX-START -->
<!-- DO NOT REMOVE THESE MARKERS — used by the docs progressive disclosure plugin -->
- `docs/getting-started.md|desc: onboarding, setup, first steps — read when setting up Nimbus locally or onboarding a new developer`
- `docs/project-overview.md|desc: architecture overview, system boundaries — read when needing high-level understanding of the Nimbus platform`
- `docs/glossary.md|desc: terminology, domain terms — read when encountering unfamiliar Nimbus-specific terms`
- `docs/architecture/|desc: system design, services, infrastructure — read when modifying core architecture or adding new services`
- `docs/api/|desc: REST API, GraphQL, endpoints, contracts — read when implementing or modifying API endpoints`
- `docs/guides/|desc: developer guides, deployment, security — read when following operational procedures`
- `docs/testing/|desc: test strategy, test types, CI — read when writing or modifying tests`
- `docs/conventions/|desc: coding standards, patterns, workflows — read when unsure about project conventions`
- `docs/frontend/|desc: React, components, state, UI — read when working on frontend code`
- `docs/data/|desc: data models, validation, ETL — read when working with data layer`
- `docs/ops/|desc: operations, alerting, runbooks — read when handling incidents or operational tasks`
<!-- DOCS-INDEX-END -->

## Updating in Consuming Projects

After pushing a version bump, users in consuming projects must run:
```
/plugin update dev-workflow@ichiba
```

If the plugin appears stale despite updating, clear the local cache:
```bash
rm -rf ~/.claude/plugins/cache
```
