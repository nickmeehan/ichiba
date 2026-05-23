# Known issue — `enabledPlugins` auto-sync races marketplace fetches

Status: **active workaround** (Claude Code 2.1.150)

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

## Workaround in this repo

A SessionStart hook reinstalls anything that the auto-sync skipped:

- **Script:** `bin/install-enabled-plugins.sh`
- **Wired in:** `.claude/settings.json` → `hooks.SessionStart[].hooks[]`
- **Behavior:** reads `enabledPlugins` from `.claude/settings.json`, compares
  to `~/.claude/plugins/installed_plugins.json`, runs `claude plugin install`
  for anything missing, and emits a `SessionStart` `additionalContext`
  message reporting which plugins were installed this session vs. already
  present.
- **Side effect:** appends one line per session to
  `~/.claude/plugin-race-workaround.log`.

The hook is dynamic — adding a plugin to `enabledPlugins` is enough; no
change to the script is required.

## Open question — does the workaround itself race? (verify on next fresh container)

**Unverified assumption:** `bin/install-enabled-plugins.sh` is wired as a
SessionStart hook. The workaround only works if SessionStart hooks fire
*after* the `extraKnownMarketplaces` clones finish. If they don't, the hook
will race the same way `vDA` does — `claude plugin install` will fail
because the marketplaces aren't on disk yet.

We could not prove ordering from `/tmp/claude-code.log` because the CLI does
not log SessionStart hook execution timestamps. The workaround was tested
manually post-boot (marketplaces already cached), which doesn't exercise the
race.

**Instructions for the next agent running in this repo:**

1. After session start, read `~/.claude/plugin-race-workaround.log` and
   `/tmp/claude-code.log`. Compare:
   - First line of the workaround log for *this* container — note the
     `installed=` and `failed=` counts.
   - In `/tmp/claude-code.log`, find the timestamps of:
     - `vDA` / `Creating installed_plugins.json from settings.json files`
     - the SessionStart hook entry (if logged) or the first `Looking up
       plugin … in marketplace` from the workaround's `claude plugin
       install` calls
     - `lastUpdated` in `~/.claude/plugins/known_marketplaces.json`
2. Decide which scenario fits:
   - **Workaround works (`installed=N, failed=0` with N == enabled count):**
     no action; record the verification in the Session log below.
   - **Workaround races too (`failed>0`, especially "Plugin not found in
     any marketplace, skipping"):** patch
     `bin/install-enabled-plugins.sh` to retry with backoff before each
     `claude plugin install`. Suggested logic: try → sleep 1s → sleep 2s
     → sleep 4s (cap at ~10s total). Only proceed past the wait once
     `~/.claude/plugins/marketplaces/<marketplace>/` exists *and*
     `known_marketplaces.json` has a `lastUpdated` newer than session
     start. Commit on the same branch and update the Session log row to
     reflect the patch.
   - **Inconclusive (mixed results, container was warm):** add a row noting
     it was a warm container and revisit on the next genuinely fresh one.

3. If the workaround works reliably across fresh containers, the retry loop
   is not needed and the assumption section above can be marked verified.

## Testing whether the upstream fix has landed

The `additionalContext` emitted by the workaround tells you, every session,
whether the race fired:

- **"Installed this session (race fired): …"** — the upstream bug is still
  present.
- **"Race did NOT fire this session."** — either (a) the upstream bug is
  fixed, or (b) you resumed an existing container where the plugins were
  already installed by an earlier session.

To distinguish (a) from (b), look at the **fresh-container** sessions only.
The `~/.claude/plugin-race-workaround.log` records every session; lines with
`race_fired=no` from sessions starting in fresh containers are the signal.

If `race_fired=no` for 3+ consecutive fresh containers after a Claude Code
upgrade, run the removal procedure below.

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

## References

- `bin/install-enabled-plugins.sh` — the workaround
- `.claude/settings.json` — `enabledPlugins` and SessionStart wiring
- `/tmp/claude-code.log` — runtime evidence (per-container, not committed)
- `~/.claude/plugins/known_marketplaces.json` — marketplace fetch timestamps
- `~/.claude/plugins/installed_plugins.json` — what the sync produced
