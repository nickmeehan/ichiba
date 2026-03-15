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

## Updating in Consuming Projects

After pushing a version bump, users in consuming projects must run:
```
/plugin update dev-workflow@ichiba
```

If the plugin appears stale despite updating, clear the local cache:
```bash
rm -rf ~/.claude/plugins/cache
```
