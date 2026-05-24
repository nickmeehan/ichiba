#!/bin/bash

# prefetch-marketplaces.sh
#
# Pre-clone the marketplaces listed under .claude/settings.json
# extraKnownMarketplaces so Claude Code's startup `enabledPlugins` sync
# finds them on disk and populates ~/.claude/plugins/installed_plugins.json
# on the FIRST session in a fresh cloud container.
#
# Intended to be invoked from a Claude Code on the web environment's
# Setup script field (Settings -> Setup script). The setup script runs
# as root before Claude launches.
#
# See docs/known-issues/plugin-install-race.md for the background and
# docs/known-issues/plugin-install-race-upstream-issue.md for the
# upstream bug report.
#
# Public marketplaces clone without auth. For PRIVATE marketplaces, set
# GH_TOKEN in the environment's variables (fine-grained PAT with
# Contents:Read on the marketplace repos); this script uses
# https://x-access-token:$GH_TOKEN@github.com for the clone URL and
# strips the token from .git/config afterwards.

set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${1:-$PWD}}"
SETTINGS="$PROJECT_DIR/.claude/settings.json"

if [ ! -f "$SETTINGS" ]; then
    echo "prefetch-marketplaces: no $SETTINGS, skipping" >&2
    exit 0
fi

command -v jq  >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq jq;  }
command -v git >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq git; }

MP_ROOT="$HOME/.claude/plugins/marketplaces"
KNOWN_MP="$HOME/.claude/plugins/known_marketplaces.json"
mkdir -p "$MP_ROOT"
[ -f "$KNOWN_MP" ] || echo '{}' > "$KNOWN_MP"

ts="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"

clone_url() {
    local repo="$1"
    if [ -n "${GH_TOKEN:-}" ]; then
        printf 'https://x-access-token:%s@github.com/%s.git' "$GH_TOKEN" "$repo"
    else
        printf 'https://github.com/%s.git' "$repo"
    fi
}

jq -r '.extraKnownMarketplaces // {}
       | to_entries[]
       | select(.value.source.source == "github")
       | "\(.key)\t\(.value.source.repo)"' "$SETTINGS" |
while IFS=$'\t' read -r name repo; do
    [ -z "$name" ] && continue
    dir="$MP_ROOT/$name"

    if [ -d "$dir/.git" ]; then
        echo "prefetch-marketplaces: $name already present at $dir" >&2
    else
        echo "prefetch-marketplaces: cloning $repo -> $dir" >&2
        git clone --depth 1 "$(clone_url "$repo")" "$dir" >&2
        if [ -n "${GH_TOKEN:-}" ]; then
            git -C "$dir" remote set-url origin "https://github.com/$repo.git"
        fi
    fi

    tmp=$(mktemp)
    jq --arg n "$name" --arg r "$repo" --arg loc "$dir" --arg t "$ts" \
        '. + {($n): {source: {source: "github", repo: $r}, installLocation: $loc, lastUpdated: $t}}' \
        "$KNOWN_MP" > "$tmp" && mv "$tmp" "$KNOWN_MP"
done

echo "prefetch-marketplaces: done" >&2
