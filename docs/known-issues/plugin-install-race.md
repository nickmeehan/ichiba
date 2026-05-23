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

## Workaround backoff (verified racing on 2026-05-23, patched)

The SessionStart hook *does* race the `extraKnownMarketplaces` fetch on
fresh containers. Verified evidence: on container
`container_019QnAXkDBpBEebNTnWghf4w--claude_code_remote--ee4383`, the hook
ran at 20:56:53.6Z but `known_marketplaces.json` `lastUpdated` was
20:56:54.4Z / 54.7Z. All four `claude plugin install` calls fired before
the marketplace JSON existed on disk and failed silently.

`bin/install-enabled-plugins.sh` now wraps each install in a wait loop:

- Extract `<marketplace>` from each `<plugin>@<marketplace>` string.
- Poll `~/.claude/plugins/marketplaces/<marketplace>/.claude-plugin/marketplace.json`
  with backoff `0s → 1s → 2s → 4s` (≤7s total, ~10s budget).
- Attempt `claude plugin install`; if it still fails after the wait, do
  one final retry pass for whatever's still in `failed=`.

Do not remove this backoff unless the upstream race is fixed (see the
removal procedure below). The script is safe on warm containers — the file
exists immediately, no waiting happens.

### Reading the workaround log line

Each session appends one line to `~/.claude/plugin-race-workaround.log`:

```
2026-05-23T20:58:48Z  enabled=4 already=0 installed=4 failed=0 race_fired=yes
```

| Field | Meaning |
|---|---|
| `enabled=` | Plugins in `.claude/settings.json` → `enabledPlugins` set to `true`. |
| `already=` | Already in `installed_plugins.json` when the hook started (vDA succeeded, or this is a warm container). |
| `installed=` | Newly installed by the hook this session. |
| `failed=` | Hook attempted install but `claude plugin install` returned non-zero. **A non-zero value here means the hook's backoff was insufficient — escalate.** |
| `race_fired=` | **Misleading flag — reads as `yes` iff `installed>0`, not iff the upstream race fired.** True meaning of "race fired" is `already < enabled`. If `installed=0 failed=N`, the race fired *and* the workaround failed; the flag still reads `no`. |

**Expected shape on a fresh container with the patch working:**

- Either `already=0 installed=N failed=0 race_fired=yes` (race fired, backoff covered it), or
- `already=N installed=0 failed=0 race_fired=no` (upstream race didn't fire — note in the log).

Anything with `failed>0` means the backoff in the hook needs widening.

### Instructions for the next agent

1. Confirm this is a **fresh** container — the first line of
   `~/.claude/plugin-race-workaround.log` should have a timestamp within
   ~1 minute of the current session start. If the log already has older
   lines from previous sessions, the container is warm and the test is
   inconclusive; record that in the Session log and stop.
2. Read the first line of the log for this session and the full
   `installed_plugins.json`. The success criterion is `failed=0` *and*
   `installed_plugins.json` contains every enabled plugin.
3. In `/tmp/claude-code.log`, also note the vDA sync timestamp (`Syncing
   installed_plugins.json with enabledPlugins`) and the
   `known_marketplaces.json` `lastUpdated` values — if the marketplace
   timestamps are now *before* the SessionStart hook entry, Claude Code
   upstream has changed its ordering and the workaround may no longer be
   needed (see "Testing whether the upstream fix has landed" below).
4. If `failed>0`, widen the backoff in `wait_for_marketplace()` in
   `bin/install-enabled-plugins.sh` (e.g., add an `8s` step) and re-test.
5. Append a row to the Session log with date, Claude Code version,
   container ID, the literal `race_fired=` value, and a note.

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
