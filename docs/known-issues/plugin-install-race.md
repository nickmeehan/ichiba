# Known issue — `enabledPlugins` auto-sync races marketplace fetches

Status: **upstream bug; cloud-session mitigation moved to env-level setup script** (Claude Code 2.1.150)

> **Update (2026-05-24):** the in-repo SessionStart-hook workaround
> (`bin/install-enabled-plugins.sh`) has been removed — it could never
> win because Claude serializes `installPluginsForHeadless` to run
> *after* SessionStart hooks return. The current mitigation for cloud
> sessions is an env-level **setup script** that calls
> [`bin/prefetch-marketplaces.sh`](../../bin/prefetch-marketplaces.sh)
> before Claude launches. See *Current mitigation (env-level setup
> script)* below.
>
> The full timeline, evidence, and proposed fixes are in
> [`plugin-install-race-upstream-issue.md`](plugin-install-race-upstream-issue.md),
> which is the body filed (or to be filed) at
> <https://github.com/anthropics/claude-code/issues>. The rest of this
> document is preserved as a historical record of the investigation and
> the dead-end SessionStart-hook approach.

## Current mitigation (env-level setup script)

For Claude Code on the web sessions, configure your environment's
**Setup script** (Settings dialog in claude.ai/code) to invoke
`bin/prefetch-marketplaces.sh` before Claude launches:

```bash
#!/bin/bash
set -e
"$CLAUDE_PROJECT_DIR"/bin/prefetch-marketplaces.sh
```

(If `$CLAUDE_PROJECT_DIR` isn't set at setup-script time, hard-code the
container's repo path, e.g. `/home/user/<repo>/bin/prefetch-marketplaces.sh`.)

The setup script's filesystem snapshot is cached across sessions in the
same environment, so the clone happens once. Subsequent sessions start
with the marketplaces already on disk and `vDA`'s sync succeeds in
session 1.

**Private marketplaces:** set `GH_TOKEN` (fine-grained PAT, Contents:Read
on the marketplace repos) in the same environment-variables block.
`prefetch-marketplaces.sh` picks it up automatically.
See *Why the setup-script approach is needed for private marketplaces*
in [`plugin-install-race-upstream-issue.md`](plugin-install-race-upstream-issue.md).

---

## Symptom

On a fresh Claude Code container (any `extraKnownMarketplaces` setup, including
this repo's `.claude/settings.json`), plugins listed under `enabledPlugins` are
silently *not* installed. The session boots without any of the configured
plugins' skills, commands, agents, or hooks. `claude plugin list` shows
"No plugins installed" even though `enabledPlugins` is correctly populated.

## Root cause

Verified against `/tmp/claude-code.log` from the 2026-05-23 session:

```
20:05:25.250  installed_plugins.json doesn't exist, returning empty V2 object
20:05:25.526  Creating installed_plugins.json from settings.json files
20:05:25.526  Looking up plugin dev-workflow@ichiba in marketplace ichiba
20:05:25.585  Plugin dev-workflow@ichiba not found in any marketplace, skipping
20:05:25.598  Plugin docs-kb@ichiba not found in any marketplace, skipping
20:05:25.610  Plugin skill-creator@claude-plugins-official not found in any marketplace, skipping
20:05:25.610  Plugin plugin-dev@claude-plugins-official not found in any marketplace, skipping
```

`known_marketplaces.json` shows the marketplaces only finished cloning at:

```
claude-plugins-official  lastUpdated: 20:05:26.928Z
ichiba                   lastUpdated: 20:05:27.346Z
```

The CLI function responsible for syncing `enabledPlugins` →
`installed_plugins.json` (`vDA` in the bundled `cli.js`) runs at ~T+0.5s, but
the marketplaces aren't on disk until ~T+1.5–2s. Every plugin lookup returns
`plugin-not-found`, the empty `installed_plugins.json` is written, and the
sync never retries.

Manually invoking `claude plugin install <plugin>` *after* startup works
instantly because the marketplaces are by then cached. So the race is purely
in the auto-sync's ordering relative to the fetch.

## Workaround in this repo (monitoring-only as of 2026-05-24)

A SessionStart hook records per-session race status:

- **Script:** `bin/install-enabled-plugins.sh`
- **Wired in:** `.claude/settings.json` → `hooks.SessionStart[].hooks[]`
- **Behavior:** reads `enabledPlugins` from `.claude/settings.json`,
  compares to `~/.claude/plugins/installed_plugins.json`, logs one line
  per session to `~/.claude/plugin-race-workaround.log`, and emits a
  `SessionStart` `additionalContext` message describing whether the
  upstream race fired this session.
- **Does NOT install anything.** Earlier versions of this hook tried
  to install missing plugins themselves; this serialized them behind
  the parent's own clone and could not win (see *Why the hook no
  longer installs* below). The post-hook `installPluginsForHeadless`
  reconcile caches the marketplaces and the *next* session's vDA
  populates `installed_plugins.json`. The first session in a fresh
  container does NOT get plugin-namespaced skills (see *Session-1
  limitation*); fixing that requires a pre-Claude marketplace clone,
  not a SessionStart hook.

The hook is dynamic — adding a plugin to `enabledPlugins` is enough; no
change to the script is required.

## Why the hook no longer installs

Earlier iterations of this workaround wrapped each `claude plugin install`
in a wait loop (`wait_for_marketplace`, backoff
`0s → 1s → 2s → 4s → 8s` plus a `known_marketplaces.json` secondary
check). On a fresh container the wait never observed the marketplace
files because the parent had not yet cloned them.

The 2026-05-24 fresh-container session
(`container_01G6VD6emFjz7Ke48ETpDdoE--claude_code_remote--a719bd`,
Claude Code 2.1.150) made the ordering unambiguous:

| Time (UTC) | Event |
|---|---|
| 05:42:53.078Z | `Syncing installed_plugins.json with enabledPlugins` (vDA) — fires *very* early, before marketplaces exist |
| 05:42:53.225–.287Z | All 4 enabled plugins "not found in any marketplace, skipping" |
| 05:43:58.712Z | `Hook SessionStart …install-enabled-plugins.sh success` (our hook returned) |
| 05:43:58.726Z | `installPluginsForHeadless: starting` — **12ms after the hook returned** |
| 05:43:59.395Z | `claude-plugins-official/.claude-plugin/marketplace.json` written |
| 05:43:59.672Z | `installPluginsForHeadless: installed marketplace claude-plugins-official` |
| 05:44:00.028Z | `nickmeehan-ichiba/.claude-plugin/marketplace.json` written |
| 05:44:00.031Z | `installPluginsForHeadless: installed marketplace ichiba` |
| 05:44:00.088Z | Plugin `hooks.json` files read (docs-kb etc.) — hooks loaded but **plugin-namespaced skills were NOT exposed to the session** (see *Session-1 limitation*) |

The parent's `installPluginsForHeadless` runs strictly after
`SessionStart` hooks complete. Anything the hook waits for, the parent
will not start until the hook returns. So `claude plugin install` inside
the hook cannot succeed on a fresh container.

### Session-1 limitation (the hook cannot fix this)

The first session in a fresh container does **not** get plugin skills,
regardless of what this hook does. Verified in the 2026-05-24
session-pair on container `…--a719bd` / `…--5d9917`:

- Session 1 (`05:42`): vDA failed → `installed_plugins.json` left empty
  → `installPluginsForHeadless` cloned the **marketplaces** but did
  NOT populate `installed_plugins.json`. The session's
  `available-skills` list contained only Claude Code built-ins
  (`verify`, `code-review`, `loop`, …) — no plugin-namespaced skills
  like `dev-workflow:commit` or `docs-kb:docs-add`.
- Session 2 (`05:55`, same container): vDA ran **again** at session
  start (`05:55:05.163Z`), this time succeeded because the marketplaces
  were cached on disk from session 1, wrote `installed_plugins.json` at
  `05:55:05.467Z`, and plugin-namespaced skills appeared in the
  `available-skills` list.

So `installPluginsForHeadless` is a **two-session fix**: session 1
caches marketplaces as a side effect, session 2+ gets the plugins.
A hook running inside session 1 cannot move the install earlier without
the marketplaces, and the marketplaces are not on disk until after the
hook returns.

The only way to fix session 1 is to clone the marketplaces *before*
Claude Code starts (e.g. a container setup script that runs
`claude plugin marketplace add` or just `git clone`s the marketplace
repos into `~/.claude/plugins/marketplaces/`). That is out of scope
for this hook; the hook remains as the lightest possible monitoring
shim while we wait for the upstream race to be fixed.

### Reading the workaround log line

Each session appends one line to `~/.claude/plugin-race-workaround.log`:

```
2026-05-24T05:44:01Z  enabled=4 already=0 missing=4 race_fired=yes
```

| Field | Meaning |
|---|---|
| `enabled=` | Plugins in `.claude/settings.json` → `enabledPlugins` set to `true`. |
| `already=` | Already in `installed_plugins.json` when the hook ran. |
| `missing=` | Not in `installed_plugins.json` when the hook ran. These will be installed by the parent's post-hook `installPluginsForHeadless` reconcile. |
| `race_fired=` | `yes` iff `missing>0` — i.e. vDA's pre-hook sync missed at least one enabled plugin. |

**Expected shapes:**

- `already=0 missing=N race_fired=yes` — fresh container, race fired
  (the common case on 2.1.150). The parent's reconcile will populate
  the session immediately after the hook returns; the next session in
  the same container should see `already=N missing=0 race_fired=no`.
- `already=N missing=0 race_fired=no` — either a warm container (the
  previous session left `installed_plugins.json` populated) or upstream
  has been fixed and vDA now runs after the marketplaces land.

Historical log rows used `installed=N failed=N` instead of `missing=N`
(when the hook still tried to install plugins itself). Those fields are
no longer emitted.

### Instructions for the next agent

1. Confirm this is a **fresh** container — the first line of
   `~/.claude/plugin-race-workaround.log` should have a timestamp within
   ~1 minute of the current session start. If the log already has older
   lines from previous sessions, the container is warm and the test is
   inconclusive; record that in the Session log and stop.
2. Read the first line of the log for this session. On a fresh container
   the expected shape is `already=0 missing=N race_fired=yes`. If you
   instead see `already=N missing=0 race_fired=no` on a fresh container,
   the upstream race may have been fixed — see *Testing whether the
   upstream fix has landed* below.
3. In `/tmp/claude-code.log`, confirm the parent's
   `installPluginsForHeadless: starting` line appears AFTER the
   `"Hook SessionStart … install-enabled-plugins.sh" success` line
   (post-hook serialization). Confirm the marketplace `lastUpdated`
   values in `~/.claude/plugins/known_marketplaces.json` are AFTER the
   hook returned. If either is no longer true, the parent's ordering has
   changed — record it in the Session log.
4. Confirm whether the session itself has the plugins'
   skills/agents available — look in the `available-skills` list for
   **plugin-namespaced** entries (e.g. `dev-workflow:commit`,
   `docs-kb:docs-add`, `plugin-dev:*`, `skill-creator:*`). Skills like
   `verify`, `code-review`, `loop`, `claude-api`, `update-config`,
   `init`, `review`, `security-review`, `session-start-hook`,
   `keybindings-help`, `fewer-permission-prompts`, `run` are Claude
   Code **built-ins** — their presence does NOT prove that plugins
   loaded. On the very first session in a fresh container, expect
   plugin-namespaced skills to be **absent** even though the hook ran
   successfully.
5. Append a row to the Session log with date, Claude Code version,
   container ID, the literal `race_fired=` value, and a note.

## Testing whether the upstream fix has landed

The `additionalContext` emitted by the hook tells you whether vDA's
pre-hook sync missed plugins this session:

- **"Not yet in installed_plugins.json …"** — the upstream race fired.
- **"Race did NOT fire this session."** — either (a) the upstream bug
  is fixed, or (b) you resumed an existing container where a previous
  session's post-hook reconcile already populated
  `installed_plugins.json`.

To distinguish (a) from (b), look at the **fresh-container** sessions
only. The `~/.claude/plugin-race-workaround.log` records every session;
lines with `race_fired=no` from sessions starting in fresh containers
are the signal.

If `race_fired=no` for 3+ consecutive fresh containers after a Claude
Code upgrade, run the removal procedure below.

## Removal procedure (when upstream is fixed)

1. Delete the second hook entry in `.claude/settings.json` →
   `hooks.SessionStart[0].hooks[]` (the one calling `./bin/install-enabled-plugins.sh`).
2. Delete `bin/install-enabled-plugins.sh`.
3. Delete `~/.claude/plugin-race-workaround.log` from any active container.
4. Update this file: change Status to `resolved in <claude version>`, keep
   the rest as a historical record.

## Session log

Append a row whenever you (or a future agent) verify the workaround status.

| Date (UTC) | Claude Code version | Container | Race fired? | Notes |
|---|---|---|---|---|
| 2026-05-23 | 2.1.150 | `container_01XUwnAuw84Q8ao2oxVXtPLs--claude_code_remote--45d2be` | yes | Initial investigation; 4 plugins skipped at boot, manual install of `dev-workflow@ichiba` succeeded |
| 2026-05-23 | 2.1.150 | `container_019QnAXkDBpBEebNTnWghf4w--claude_code_remote--ee4383` | no (per log; misleading) | Workaround itself raced — hook ran at 20:56:53Z but `known_marketplaces.json` lastUpdated 20:56:54.4Z/54.7Z, so all 4 installs failed (`failed=4`, empty `installed_plugins.json`). Patched `bin/install-enabled-plugins.sh` with a `wait_for_marketplace` backoff (0/1/2/4s) plus a one-shot retry of failed installs; manual rerun then yielded `installed=4 failed=0 race_fired=yes`. |
| 2026-05-23 | 2.1.150 | `container_01WCmjySw9GbtgfGMtjWxjxg--claude_code_remote--c28ed3` | yes (literal `race_fired=no`, but `failed=4` so the race fired and the backoff lost it again) | Fresh container — first log line `2026-05-23T21:09:58Z enabled=4 already=0 installed=0 failed=4`. **New finding:** the parent process now serializes the marketplace clone *after* the SessionStart hooks complete (`installPluginsForHeadless: starting` at 21:09:58.701Z, 8ms after our hook exited; marketplaces lastUpdated 21:09:59.4Z / 21:09:59.8Z). vDA `Syncing installed_plugins.json with enabledPlugins` fired at 21:09:24.741Z, ~35s before marketplaces landed. Plugin skills still loaded *this* session via the post-hook headless reconcile, but `installed_plugins.json` stayed empty until a manual rerun. Widened `wait_for_marketplace` cadence from `0 1 2 4` (7s) to `0 1 2 4 8` (15s) and added a `marketplace_fetched_since_session_start` secondary check (one extra 4s grace period if `known_marketplaces.json[m].lastUpdated >= session_start`). Manual rerun yields `installed=4 failed=0`. **Caveat:** if the parent really does block marketplace fetch on SessionStart hook completion, more waiting in the hook just delays the parent's clone by the same amount; the next fresh-container observation should tell us whether the wider wait actually helps. |
| 2026-05-24 | 2.1.150 | `container_01G6VD6emFjz7Ke48ETpDdoE--claude_code_remote--a719bd` (session 1, fresh) | yes (literal `race_fired=no`, `failed=4`) | Fresh container — first log line `2026-05-24T05:43:58Z enabled=4 already=0 installed=0 failed=4 race_fired=no`. Widened `0 1 2 4 8` backoff + `known_marketplaces.json` secondary check did **not** help. Post-hook serialization confirmed: hook returned 05:43:58.714Z, `installPluginsForHeadless: starting` 05:43:58.726Z (12ms later), marketplaces written 05:43:59.395Z / 05:44:00.028Z. vDA ran at 05:42:53.078Z, ~65s before marketplaces landed. Plugin **hooks.json files** were read at 05:44:00.088Z+ but **plugin-namespaced skills were NOT exposed to the session** (the system-reminder `available-skills` list contained only Claude Code built-ins). `installed_plugins.json` stayed empty for the whole session. **Strategy change:** reduced `bin/install-enabled-plugins.sh` to monitoring-only — no waits, no `claude plugin install`. The futile install attempts were dead weight; removing them doesn't change session-1 outcome but avoids ~15s of pointless waiting. |
| 2026-05-24 | 2.1.150 | `container_01G6VD6emFjz7Ke48ETpDdoE--claude_code_remote--5d9917` (session 2, same container as `--a719bd`) | no (genuine — vDA succeeded) | Resumed session in the same container. Log line `2026-05-24T05:55:05Z enabled=4 already=4 missing=0 race_fired=no` (first run of the new monitoring-only hook). `/tmp/claude-code.log` shows vDA ran again at session start (`05:55:05.163Z`), succeeded because marketplaces were cached from session 1, and wrote `installed_plugins.json` at `05:55:05.467Z`. Plugin-namespaced skills (`dev-workflow:commit`, `docs-kb:docs-add`, `plugin-dev:*`, `skill-creator:*`) are now exposed to the session. **Confirms `installPluginsForHeadless` is a two-session fix on a fresh container** — session 1 caches marketplaces as a side effect, session 2's vDA does the actual sync. To rescue session 1 we would need a pre-Claude marketplace clone (out of scope for this hook). Earlier note in this row's predecessor claiming "skills still loaded this session" was wrong — those were Claude Code built-ins, not plugin skills. |

## References

- `bin/install-enabled-plugins.sh` — the workaround
- `.claude/settings.json` — `enabledPlugins` and SessionStart wiring
- `/tmp/claude-code.log` — runtime evidence (per-container, not committed)
- `~/.claude/plugins/known_marketplaces.json` — marketplace fetch timestamps
- `~/.claude/plugins/installed_plugins.json` — what the sync produced
