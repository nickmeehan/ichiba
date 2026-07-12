#!/usr/bin/env bash
set -euo pipefail

# Bump the top-level marketplace version (.metadata.version) for a plugin
# release: patch normally, minor when this is the plugin's first-ever
# release (no <plugin>-v* tag exists yet — requires full tag history).
#
# Shared by bin/release-bump.sh (semantic-release prepare step for native
# plugins) and bin/finalize-vendored-releases.sh (vendored plugins), so the
# marketplace version moves identically no matter who cut the release.

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <plugin-name>" >&2
  exit 64
fi

plugin="$1"

repo_root="$(git rev-parse --show-toplevel)"
marketplace_json="${repo_root}/.claude-plugin/marketplace.json"

if [[ ! -f "$marketplace_json" ]]; then
  echo "marketplace-bump: marketplace manifest not found: $marketplace_json" >&2
  exit 1
fi

if git tag -l "${plugin}-v*" | grep -q .; then
  bump="patch"
else
  bump="minor"
fi

current="$(jq -r '.metadata.version' "$marketplace_json")"
if [[ ! "$current" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "marketplace-bump: invalid current marketplace version: $current" >&2
  exit 1
fi
major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

case "$bump" in
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac
new="${major}.${minor}.${patch}"

tmp="$(mktemp)"
jq --arg v "$new" '.metadata.version = $v' "$marketplace_json" > "$tmp"
mv "$tmp" "$marketplace_json"

echo "marketplace-bump: ${current} -> ${new} (${bump}; ${plugin})"
