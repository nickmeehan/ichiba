# ichiba Plugin Marketplace

This repo is a Claude Code plugin marketplace distributed via `extraKnownMarketplaces` in consuming projects' `settings.json`.

## Plugin Version Rules

**Whenever you change anything in a plugin** (skills, prompts, hooks, MCP config, or any other file), you MUST bump the version in **both** of these files:

1. `plugins/<plugin-name>/.claude-plugin/plugin.json` — the plugin's own version
2. `.claude-plugin/marketplace.json` — the matching version in the plugin's entry under `"plugins"`

Both versions must stay in sync. Claude Code compares version strings to detect updates — if the version doesn't change, consuming projects will never receive the update regardless of what was pushed.

Use semantic versioning (`MAJOR.MINOR.PATCH`):
- Patch bump (`1.0.0` → `1.0.1`): bug fixes, wording changes, minor skill tweaks
- Minor bump (`1.0.0` → `1.1.0`): new skills, commands, or agents added
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
