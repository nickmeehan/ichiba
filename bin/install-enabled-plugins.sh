#!/bin/bash

# install-enabled-plugins.sh
#
# Workaround for an upstream Claude Code race condition:
# `extraKnownMarketplaces` fetches finish AFTER the `enabledPlugins` auto-sync
# runs at session start, so the sync silently skips every plugin and
# `installed_plugins.json` is left empty on fresh containers.
#
# This hook reads `enabledPlugins` from .claude/settings.json and installs any
# that are missing from `~/.claude/plugins/installed_plugins.json`. The check is
# done BEFORE installing, so the report tells future agents whether the upstream
# race actually fired this session — useful for deciding when the workaround can
# be removed.
#
# See docs/known-issues/plugin-install-race.md for the full investigation, the
# removal procedure, and the per-session status log.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS="$REPO_ROOT/.claude/settings.json"
INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
LOG_FILE="$HOME/.claude/plugin-race-workaround.log"

emit_context() {
    local msg="$1"
    local json
    json=$(printf "%s" "$msg" | jq -Rs .)
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$json"
}

log_line() {
    mkdir -p "$(dirname "$LOG_FILE")"
    printf "%s  %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >> "$LOG_FILE"
}

# Bail quietly if prerequisites are missing — we never want this hook to break
# a session.
command -v claude >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ -f "$SETTINGS" ] || exit 0

enabled=$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$SETTINGS" 2>/dev/null || true)
if [ -z "$enabled" ]; then
    exit 0
fi

is_installed() {
    [ -f "$INSTALLED" ] && jq -e --arg p "$1" '(.plugins[$p] // []) | length > 0' "$INSTALLED" >/dev/null 2>&1
}

# The hook itself can race the marketplace fetch (observed on fresh containers:
# SessionStart fires ~1s before the extraKnownMarketplaces clone lands on disk).
# Block until <plugin>@<marketplace>'s marketplace.json is present, with backoff
# capped at ~7s. Returns 0 if the file appears, 1 if the wait gave up.
wait_for_marketplace() {
    local marketplace="$1"
    local mp_json="$HOME/.claude/plugins/marketplaces/$marketplace/.claude-plugin/marketplace.json"
    local delay
    for delay in 0 1 2 4; do
        [ "$delay" -gt 0 ] && sleep "$delay"
        [ -f "$mp_json" ] && return 0
    done
    return 1
}

missing=()
already=()
for plugin in $enabled; do
    if is_installed "$plugin"; then
        already+=("$plugin")
    else
        missing+=("$plugin")
    fi
done

try_install() {
    local plugin="$1"
    local marketplace="${plugin##*@}"
    wait_for_marketplace "$marketplace" || true
    claude plugin install "$plugin" >/dev/null 2>&1
}

installed_now=()
failed=()
for plugin in "${missing[@]+"${missing[@]}"}"; do
    if try_install "$plugin"; then
        installed_now+=("$plugin")
    else
        failed+=("$plugin")
    fi
done

# Second pass: anything that failed the first attempt gets one more shot, in
# case the marketplace fetch was still in flight when the wait gave up.
if [ ${#failed[@]} -gt 0 ]; then
    retry=("${failed[@]}")
    failed=()
    for plugin in "${retry[@]}"; do
        if claude plugin install "$plugin" >/dev/null 2>&1; then
            installed_now+=("$plugin")
        else
            failed+=("$plugin")
        fi
    done
fi

join() { local IFS=", "; echo "$*"; }

total_enabled=$(echo "$enabled" | wc -l | tr -d ' ')
n_already=${#already[@]}
n_installed=${#installed_now[@]}
n_failed=${#failed[@]}

log_line "enabled=$total_enabled already=$n_already installed=$n_installed failed=$n_failed race_fired=$([ $n_installed -gt 0 ] && echo yes || echo no)"

report="[Plugin install race workaround — see docs/known-issues/plugin-install-race.md]"
report="$report"$'\n'"Enabled plugins ($total_enabled total): $(join $enabled)"

if [ $n_installed -gt 0 ]; then
    report="$report"$'\n'"Installed this session (race fired): $(join "${installed_now[@]}")"
fi
if [ $n_already -gt 0 ]; then
    report="$report"$'\n'"Already installed before hook ran: $(join "${already[@]+"${already[@]}"}")"
fi
if [ $n_failed -gt 0 ]; then
    report="$report"$'\n'"FAILED to install: $(join "${failed[@]+"${failed[@]}"}")"
fi

if [ $n_installed -eq 0 ] && [ $n_failed -eq 0 ]; then
    report="$report"$'\n'"Race did NOT fire this session. If this is a fresh container (not a resumed session) and the race has not fired across several consecutive fresh containers, the upstream bug may be fixed — see docs/known-issues/plugin-install-race.md § 'Testing whether the upstream fix has landed' for the removal procedure."
fi

emit_context "$report"
