#!/bin/bash

# install-enabled-plugins.sh
#
# Monitoring-only hook for the plugin install race
# (see docs/known-issues/plugin-install-race.md).
#
# Earlier versions waited for the extraKnownMarketplaces clone and then
# ran `claude plugin install` for anything `vDA` had skipped. Verified
# evidence on Claude Code 2.1.150 (2026-05-24 fresh-container session)
# shows the parent serializes `installPluginsForHeadless` AFTER the
# SessionStart hook completes — the headless reconcile started 12ms after
# this hook exited and the marketplace clones landed ~1s later. So any
# wait or install inside this hook just delays the parent by the same
# amount and `claude plugin install` keeps failing.
#
# Note: on a TRULY fresh container the first session does NOT get
# plugin-namespaced skills regardless of this hook — installPluginsForHeadless
# only caches the marketplaces in session 1, and the next session's vDA
# populates installed_plugins.json. This hook is intentionally a no-op
# install-wise; it just logs session status so we can tell when the
# upstream race can be considered fixed.

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

command -v jq >/dev/null 2>&1 || exit 0
[ -f "$SETTINGS" ] || exit 0

enabled=$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$SETTINGS" 2>/dev/null || true)
if [ -z "$enabled" ]; then
    exit 0
fi

is_installed() {
    [ -f "$INSTALLED" ] && jq -e --arg p "$1" '(.plugins[$p] // []) | length > 0' "$INSTALLED" >/dev/null 2>&1
}

already=()
missing=()
for plugin in $enabled; do
    if is_installed "$plugin"; then
        already+=("$plugin")
    else
        missing+=("$plugin")
    fi
done

join() { local IFS=", "; echo "$*"; }

total_enabled=$(echo "$enabled" | wc -l | tr -d ' ')
n_already=${#already[@]}
n_missing=${#missing[@]}

# race_fired=yes iff vDA's pre-hook sync missed at least one enabled plugin
# (i.e. `installed_plugins.json` is incomplete when the hook runs). The
# parent's post-hook headless reconcile will fill it in.
race_fired=$([ $n_missing -gt 0 ] && echo yes || echo no)
log_line "enabled=$total_enabled already=$n_already missing=$n_missing race_fired=$race_fired"

report="[Plugin install race workaround — monitoring-only; see docs/known-issues/plugin-install-race.md]"
report="$report"$'\n'"Enabled plugins ($total_enabled total): $(join $enabled)"
if [ $n_already -gt 0 ]; then
    report="$report"$'\n'"Already in installed_plugins.json: $(join "${already[@]+"${already[@]}"}")"
fi
if [ $n_missing -gt 0 ]; then
    report="$report"$'\n'"Not yet in installed_plugins.json (vDA's pre-hook sync missed them): $(join "${missing[@]+"${missing[@]}"}")"
    report="$report"$'\n'"On the first session in a fresh container, plugin-namespaced skills (dev-workflow:*, docs-kb:*, plugin-dev:*, skill-creator:*) will NOT be available this session — installPluginsForHeadless only caches the marketplaces. Restart Claude in the same container to get the plugin skills."
fi
if [ $n_missing -eq 0 ]; then
    report="$report"$'\n'"Race did NOT fire this session. If this holds across 3+ consecutive fresh containers, see docs/known-issues/plugin-install-race.md § 'Removal procedure'."
fi

emit_context "$report"
