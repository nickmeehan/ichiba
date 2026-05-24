# Plugin install race: `enabledPlugins` sync runs before `extraKnownMarketplaces` clone — plugin-namespaced skills missing in first session of every fresh container

## Environment

- Claude Code version: **2.1.150**
- Platform: Claude Code on the web (cloud sandbox, Ubuntu 24.04 container)
- Reproduced consistently across multiple fresh containers over several days

## Summary

On a fresh cloud container, the auto-sync that materializes `enabledPlugins` into `~/.claude/plugins/installed_plugins.json` (`vDA` in the bundled CLI) fires before `installPluginsForHeadless` clones the `extraKnownMarketplaces` repositories. Every plugin lookup returns "plugin not found in any marketplace, skipping", the empty `installed_plugins.json` is written, and the sync never retries. **Plugin-namespaced skills, agents, commands, and hooks are unavailable for the first session in every fresh container.** The user must restart Claude inside the same container before any plugin functionality becomes available.

There is no SessionStart-hook-based fix because the parent serializes `installPluginsForHeadless` to run *after* all SessionStart hooks return. A container-level setup script can pre-clone marketplaces for **public** repos, but the session's GitHub credentials are not exposed to user-space, so a setup-script fix for **private** marketplaces requires the user to manage their own PAT.

## Symptom

Given a repo's `.claude/settings.json` with:

```json
{
  "extraKnownMarketplaces": {
    "ichiba":                  { "source": { "source": "github", "repo": "nickmeehan/ichiba" } },
    "claude-plugins-official": { "source": { "source": "github", "repo": "anthropics/claude-plugins-official" } }
  },
  "enabledPlugins": {
    "dev-workflow@ichiba": true,
    "docs-kb@ichiba": true,
    "skill-creator@claude-plugins-official": true,
    "plugin-dev@claude-plugins-official": true
  }
}
```

…the first session in a fresh container:

- `~/.claude/plugins/installed_plugins.json` is `{"version": 2, "plugins": {}}`.
- `available-skills` (from the SessionStart system reminder) contains only Claude Code built-ins (`verify`, `code-review`, `loop`, `claude-api`, `update-config`, etc.) — no plugin-namespaced skills like `dev-workflow:commit`, `docs-kb:docs-add`, `plugin-dev:*`, `skill-creator:*`.
- `claude plugin list` shows "No plugins installed".
- The plugins' `hooks.json` files DO get read during the session (per `[DEBUG] Read hooks.json for plugin docs-kb (enabled=true)`), but skill registration appears to be frozen at an earlier point.

The second session in the same container works correctly because `installPluginsForHeadless` cached the marketplaces in session 1, and session 2's vDA succeeds against the cache.

## Root cause — verified timeline

From `/tmp/claude-code.log` on container `container_01G6VD6emFjz7Ke48ETpDdoE--claude_code_remote--a719bd` (Claude Code 2.1.150):

| Time (UTC)      | Event |
|-----------------|---|
| `05:42:52.963Z` | `[DEBUG] Loaded 0 installed plugins from /root/.claude/plugins/installed_plugins.json` |
| `05:42:53.078Z` | `[DEBUG] Syncing installed_plugins.json with enabledPlugins from all settings.json files` *(vDA fires)* |
| `05:42:53.225–.287Z` | `[DEBUG] Plugin <name> not found in any marketplace, skipping` *(×4, one per `enabledPlugins` entry)* |
| `05:43:58.712Z` | `[DEBUG] Hook SessionStart (./bin/install-enabled-plugins.sh) success` *(our SessionStart hook returned)* |
| `05:43:58.726Z` | `[DEBUG] installPluginsForHeadless: starting` *(12ms after SessionStart hook returned)* |
| `05:43:59.395Z` | `claude-plugins-official/.claude-plugin/marketplace.json` written to disk |
| `05:43:59.672Z` | `[DEBUG] installPluginsForHeadless: installed marketplace claude-plugins-official` |
| `05:44:00.028Z` | `ichiba/.claude-plugin/marketplace.json` written to disk |
| `05:44:00.031Z` | `[DEBUG] installPluginsForHeadless: installed marketplace ichiba` |
| `05:44:00.088Z+` | `[DEBUG] Read hooks.json for plugin docs-kb (enabled=true)` *(plugin hooks load, but skill list already frozen)* |
| *(session 1 ends)* | `installed_plugins.json` still `{"plugins": {}}` |
| `05:55:05.035Z` | *(session 2 start)* `[DEBUG] Loaded 0 installed plugins from installed_plugins.json` |
| `05:55:05.163Z` | `[DEBUG] Syncing installed_plugins.json with enabledPlugins from all settings.json files` *(vDA fires again; succeeds because marketplaces are cached)* |
| `05:55:05.467Z` | `[DEBUG] Saved 4 installed plugins to installed_plugins.json` / `Sync completed: 4 added` |

Three independent ordering problems combine here:

1. **vDA runs ~65 seconds before `installPluginsForHeadless`** at session start.
2. **`installPluginsForHeadless` is serialized to run after all SessionStart hooks return** (12ms after our hook exited, regardless of how long the hook ran). This is independently observable and means no SessionStart-hook workaround can win the race — anything the hook waits for, the parent will not start until the hook returns.
3. **vDA does not re-run after `installPluginsForHeadless` completes.** Even though `installPluginsForHeadless` successfully clones the marketplaces during session 1, the empty `installed_plugins.json` written by vDA is not refreshed. The sync only re-succeeds on the *next* session because vDA is re-invoked at startup.

## Why no user-side workaround is sufficient

We exhausted the SessionStart-hook approach in [this repo](https://github.com/nickmeehan/ichiba/blob/main/bin/install-enabled-plugins.sh) and [its known-issues doc](https://github.com/nickmeehan/ichiba/blob/main/docs/known-issues/plugin-install-race.md):

- A SessionStart hook that polls for the marketplace files with backoff (`0/1/2/4/8s` plus a `known_marketplaces.json` lastUpdated secondary check) **never observes the files** because the parent does not start `installPluginsForHeadless` until the hook returns.
- A SessionStart hook that calls `claude plugin install <plugin>@<marketplace>` directly **always fails** for the same reason.

The container-level **setup script** mechanism (which runs before Claude Code launches) *can* pre-clone marketplaces and pre-populate `~/.claude/plugins/known_marketplaces.json`, which makes vDA succeed on session 1. However:

- The session's GitHub auth (whatever credential the platform uses to clone the user's project repo into the container) **is not exposed to user-space**. There is no git credential helper configured, no `GH_TOKEN`/`GITHUB_TOKEN` env var, no `.netrc`. The only Claude-managed tokens in the container (`/root/.claude/remote/.oauth_token`, `.session_ingress_token`) are Anthropic OAuth tokens, not GitHub credentials.
- Public marketplaces work because `git clone` succeeds without auth.
- **Private marketplaces require the user to mint and stash their own PAT** in the environment's `GH_TOKEN` env var. That secret is then visible to anyone who can edit the environment (per [the docs](https://code.claude.com/docs/en/claude-code-on-the-web#the-cloud-environment): *"environment variables and setup scripts are stored in the environment configuration, visible to anyone who can edit that environment"*).

## Suggested fixes (any one of these would resolve it)

In rough order of how invasive they are:

1. **Re-run vDA after `installPluginsForHeadless` completes in the same session.** Cheapest fix. When `installPluginsForHeadless` finishes its reconcile, invalidate `installed_plugins.json` and re-invoke vDA so the just-cloned marketplaces are used. Also requires re-registering skills/agents/commands for the current session after vDA writes the file — currently skill registration appears to happen too early to pick up plugins installed by `installPluginsForHeadless`.

2. **Move vDA after `installPluginsForHeadless`.** Run the `enabledPlugins` → `installed_plugins.json` sync only once marketplaces are guaranteed to be on disk. Removes the race entirely.

3. **Run `installPluginsForHeadless` before SessionStart hooks (or in parallel with them).** Breaks the "hook completion gates marketplace clone" dependency. Combined with (1) or (2), would let user-land workarounds at least be possible.

4. **Expose a git credential helper / `GH_TOKEN` to user-space inside the container** so setup scripts can clone private marketplaces using the session's already-authorized GitHub credential. This wouldn't fix the underlying race but would let users self-serve for private marketplaces without managing their own PAT. Even a documented `claude plugin marketplace add github:org/private-repo` command that inherits session credentials and runs from a setup script would be sufficient.

## Reproduction

1. Set up `extraKnownMarketplaces` + `enabledPlugins` in `.claude/settings.json` (use the example above, or any public marketplace + enabled plugin combination).
2. Start a **fresh** cloud container (no environment cache).
3. In the first session, check:
   - `cat ~/.claude/plugins/installed_plugins.json` → `{"version": 2, "plugins": {}}`
   - `claude plugin list` → "No plugins installed"
   - Inspect the SessionStart system reminder's `available-skills` list → no plugin-namespaced skills
4. Restart Claude in the same container (don't destroy the container).
5. In the second session, the same checks now show plugins installed and skills available.

## Observed in this repo

The full investigation and per-session log lives at:

- <https://github.com/nickmeehan/ichiba/blob/main/docs/known-issues/plugin-install-race.md>
- <https://github.com/nickmeehan/ichiba/blob/main/bin/install-enabled-plugins.sh>

The repo's SessionStart hook has been reduced to monitoring-only (it just logs `enabled/already/missing/race_fired` per session) because no in-hook install strategy can succeed against the post-hook serialization.

## What we would consider "fixed"

A fresh container's first session has plugin-namespaced skills, agents, commands, and hooks available, with `installed_plugins.json` correctly populated, without the user having to configure a container-level setup script or mint a PAT.
