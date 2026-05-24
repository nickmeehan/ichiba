# Upstream bug report — copy-pastable by section

> **How to use this file:** the bug template at
> <https://github.com/anthropics/claude-code/issues/new?template=bug_report.yml>
> has separate fields. Each `---` block below maps to **one** field.
> Copy the content under each "Field:" heading directly into the
> matching form field. Dropdown answers are given inline; just pick
> them from the menu.

---

## Field: **Title** (text input at the very top of the form)

```
Plugin install race: enabledPlugins sync runs before extraKnownMarketplaces clone — plugin-namespaced skills missing in first session of every fresh container
```

---

## Field: **Preflight Checklist** (checkboxes)

Tick all three: searched existing issues, filing a single bug, using the latest version.

---

## Field: **What's Wrong?** (required textarea)

On a fresh Claude Code on the web container, the auto-sync that materializes `enabledPlugins` into `~/.claude/plugins/installed_plugins.json` (`vDA` in the bundled CLI) fires before `installPluginsForHeadless` clones the `extraKnownMarketplaces` repositories. Every plugin lookup returns "Plugin <name>@<marketplace> not found in any marketplace, skipping", an empty `installed_plugins.json` is written, and the sync never retries during the session.

Result: **plugin-namespaced skills, agents, commands, and hooks are unavailable for the first session in every fresh container.** `claude plugin list` shows "No plugins installed". The user must restart Claude inside the same container before any plugin functionality becomes available, because the cached marketplaces from session 1 let session 2's vDA succeed.

A SessionStart-hook workaround cannot fix this from user-space — Claude serializes `installPluginsForHeadless` to run **after** all SessionStart hooks return (verified: 12ms after our hook exited, regardless of how long the hook ran). A container-level setup script can pre-clone public marketplaces, but the session's GitHub credentials are not exposed to user-space, so private marketplaces require the user to mint and stash their own PAT.

---

## Field: **What Should Happen?** (required textarea)

A fresh container's first session should have plugin-namespaced skills, agents, commands, and hooks available, with `~/.claude/plugins/installed_plugins.json` correctly populated to reflect `enabledPlugins`, **without** requiring the user to:

- restart Claude in the same container to get to a "session 2" state, or
- configure a container-level setup script that pre-clones marketplaces, or
- mint and manage a PAT for cloning private marketplaces.

Concretely, any one of these upstream fixes would resolve it:

1. Re-run vDA after `installPluginsForHeadless` completes in the same session, and re-register skills/agents/commands so the just-installed plugins are picked up.
2. Move vDA to run *after* `installPluginsForHeadless` instead of before it.
3. Run `installPluginsForHeadless` before (or in parallel with) SessionStart hooks, combined with (1) or (2), so user-land workarounds become viable.
4. Expose a git credential helper or `GH_TOKEN` to user-space inside the container so setup scripts can clone private marketplaces using the session's already-authorized GitHub credential. (Doesn't fix the race but makes the workaround self-serve.)

---

## Field: **Is this a regression?** (dropdown)

Select: **Don't know** — we don't have a record of a prior version where it worked. The repo's `extraKnownMarketplaces` setup has always required a SessionStart-hook workaround across the versions we've tested (2.1.150 and earlier in the 2.1.x line).

---

## Field: **Claude Code Version** (text input)

```
2.1.150 (Claude Code)
```

---

## Field: **Platform** (dropdown)

Select: **Other** — this is Claude Code on the web (Anthropic-managed cloud sandbox).

---

## Field: **Operating System** (dropdown)

Select: **Ubuntu/Debian** — the cloud container is Ubuntu 24.04.

---

## Field: **Terminal/Shell** (dropdown)

Select: **Other** — initiated from the Claude Code on the web UI at claude.ai/code; the in-container shell is bash.

---

## Field: **Steps to Reproduce** (required textarea)

1. Create a Claude Code on the web environment (no environment cache yet) with **Trusted** network access and no setup script.
2. Use a repo with `.claude/settings.json` declaring `extraKnownMarketplaces` plus `enabledPlugins`:

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

3. Start a fresh session against that repo and let the container provision.
4. Once Claude is ready, in the **first** session run:

   ```bash
   cat ~/.claude/plugins/installed_plugins.json
   claude plugin list
   ```

   Observe `{"version": 2, "plugins": {}}` and "No plugins installed".

5. Inspect the SessionStart system reminder's `available-skills` list. Plugin-namespaced skills (`dev-workflow:commit`, `docs-kb:docs-add`, `plugin-dev:*`, `skill-creator:*`) are **absent**. Only Claude Code built-in skills appear.
6. Restart Claude inside the **same** container (do not destroy the container).
7. In the second session, re-run the same checks. `installed_plugins.json` is now populated with all four plugins and plugin-namespaced skills are exposed.

---

## Field: **Error Output / Logs** (optional textarea)

Relevant lines from `/tmp/claude-code.log` on container `container_01G6VD6emFjz7Ke48ETpDdoE--claude_code_remote--a719bd`:

```
2026-05-24T05:42:52.963Z [DEBUG] Loaded 0 installed plugins from /root/.claude/plugins/installed_plugins.json
2026-05-24T05:42:53.078Z [DEBUG] Syncing installed_plugins.json with enabledPlugins from all settings.json files
2026-05-24T05:42:53.225Z [DEBUG] Plugin dev-workflow@ichiba not found in any marketplace, skipping
2026-05-24T05:42:53.264Z [DEBUG] Plugin docs-kb@ichiba not found in any marketplace, skipping
2026-05-24T05:42:53.277Z [DEBUG] Plugin skill-creator@claude-plugins-official not found in any marketplace, skipping
2026-05-24T05:42:53.287Z [DEBUG] Plugin plugin-dev@claude-plugins-official not found in any marketplace, skipping
2026-05-24T05:43:58.712Z [DEBUG] Hook SessionStart … success
2026-05-24T05:43:58.726Z [DEBUG] installPluginsForHeadless: starting          ← 12ms AFTER SessionStart hook returned
2026-05-24T05:43:59.395Z (mtime)  claude-plugins-official/.claude-plugin/marketplace.json written
2026-05-24T05:43:59.672Z [DEBUG] installPluginsForHeadless: installed marketplace claude-plugins-official
2026-05-24T05:44:00.028Z (mtime)  ichiba/.claude-plugin/marketplace.json written
2026-05-24T05:44:00.031Z [DEBUG] installPluginsForHeadless: installed marketplace ichiba
2026-05-24T05:44:00.088Z [DEBUG] Read hooks.json for plugin docs-kb (enabled=true)
                                  ← session 1 ends; installed_plugins.json still {"plugins": {}}
2026-05-24T05:55:05.035Z [DEBUG] Loaded 0 installed plugins from installed_plugins.json    ← session 2 start
2026-05-24T05:55:05.163Z [DEBUG] Syncing installed_plugins.json with enabledPlugins        ← vDA runs again
2026-05-24T05:55:05.467Z [DEBUG] Saved 4 installed plugins to installed_plugins.json
2026-05-24T05:55:05.467Z [DEBUG] Sync completed: 4 added, 0 updated in installed_plugins.json
```

Key timing:
- vDA fires at `T+0.115s`, ~65 seconds before marketplaces land on disk.
- `installPluginsForHeadless` does not start until the SessionStart hook returns (12ms gap).
- The marketplace clones complete at `T+66.3s` and `T+67.0s`, but vDA does not re-run.
- Session 2's vDA finally succeeds because the marketplaces were cached by session 1's `installPluginsForHeadless`.

---

## Field: **Model** (optional dropdown)

Not applicable — this is an infrastructure/startup bug, not model behavior. Leave blank or select whatever's most recent.

---

## Field: **Last Working Version** (optional text input)

Unknown. The race appears to have existed for the entire 2.1.x line we've tested against.

---

## Field: **Additional Context** (optional textarea)

### Why no user-side workaround is sufficient

We exhausted SessionStart-hook approaches in [nickmeehan/ichiba](https://github.com/nickmeehan/ichiba). The full investigation is at <https://github.com/nickmeehan/ichiba/blob/main/docs/known-issues/plugin-install-race.md>.

- A SessionStart hook that polls for marketplace files with backoff (`0/1/2/4/8s` plus a `known_marketplaces.json` `lastUpdated` secondary check) **never observes the files** — the parent does not start `installPluginsForHeadless` until the hook returns.
- A SessionStart hook that calls `claude plugin install <plugin>@<marketplace>` directly **always fails** for the same reason.
- The plugin's `hooks.json` files DO get read at `T+67s` (per `[DEBUG] Read hooks.json for plugin docs-kb (enabled=true)`), but skill registration appears to be frozen earlier — the session's `available-skills` list never picks up the plugin-namespaced skills regardless.

### Container-level setup script: works for public marketplaces, breaks down for private ones

The Claude Code on the web environment's **setup script** mechanism (which runs before Claude launches) can pre-clone marketplaces and pre-populate `~/.claude/plugins/known_marketplaces.json`. We've implemented this at <https://github.com/nickmeehan/ichiba/blob/main/bin/prefetch-marketplaces.sh>. It works for public marketplaces.

For **private** marketplaces, however:

- The session's GitHub auth (whatever credential the platform uses to clone the user's project repo into the container) is **not exposed to user-space**. Inside the container: no `credential.helper` configured, no `~/.netrc`, no `GH_TOKEN`/`GITHUB_TOKEN` env var, no `gh` CLI installed by default. The only Claude-managed tokens (`/root/.claude/remote/.oauth_token`, `.session_ingress_token`) are Anthropic OAuth tokens, not GitHub credentials.
- So the setup script must clone with **its own** credentials — typically a fine-grained PAT stashed in `GH_TOKEN`, which is then visible to anyone who can edit the environment (per [the docs](https://code.claude.com/docs/en/claude-code-on-the-web#the-cloud-environment): *"environment variables and setup scripts are stored in the environment configuration, visible to anyone who can edit that environment"*).
- For a single-user environment this is acceptable; for a shared team environment it's a real exposure.

### Suggested fixes (any one of these resolves it)

1. **Re-run vDA after `installPluginsForHeadless`.** Cheapest fix. When `installPluginsForHeadless` finishes its reconcile, re-invoke vDA so the just-cloned marketplaces are used, and re-register skills/agents/commands for the current session.
2. **Move vDA after `installPluginsForHeadless`.** Sync `enabledPlugins` → `installed_plugins.json` only once marketplaces are guaranteed to be on disk. Removes the race entirely.
3. **Run `installPluginsForHeadless` before SessionStart hooks** (or in parallel with them). Combined with (1) or (2), would also let user-land workarounds at least be possible.
4. **Expose a git credential helper / `GH_TOKEN`-equivalent to user-space** inside the container. Doesn't fix the race but makes the setup-script workaround self-serve for private marketplaces. Even a documented `claude plugin marketplace add github:org/private-repo` command that runs from a setup script and inherits session credentials would be sufficient.

### Related issues

- **#61866** *(open)* — "[BUG] Project-scoped plugins not automatically enabled in git worktrees despite being configured in `.claude/settings.json`". **Surface symptom overlaps** ("Plugin is enabled in project settings but isn't installed here"), but the mechanism is different: cache lock contention between parallel sessions sharing the same cache dir, not a startup race against the marketplace clone. Cross-linking so triage doesn't dedupe.
- **#61222** *(open)* — `extraKnownMarketplaces` local entry regenerated without `source` discriminator on session start. Adjacent area, different defect.
- **#61854** *(open)* — `autoUpdate: true` on `extraKnownMarketplaces` doesn't re-install plugins. Same subsystem, different lifecycle stage.

A search of the issue tracker on `installPluginsForHeadless`, `installed_plugins.json`, `enabledPlugins`, "not found in marketplace, skipping", "fresh container", and "first session" returned no existing report of this specific startup race.

### Observed in

- <https://github.com/nickmeehan/ichiba/blob/main/docs/known-issues/plugin-install-race.md> — full investigation, per-session log, dead-end approaches.
- <https://github.com/nickmeehan/ichiba/blob/main/bin/prefetch-marketplaces.sh> — the env-level setup-script mitigation we use today.
