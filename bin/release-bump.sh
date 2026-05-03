#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <plugin-name> <new-version>" >&2
  exit 64
fi

plugin="$1"
new_version="$2"

repo_root="$(git rev-parse --show-toplevel)"
plugin_json="${repo_root}/plugins/${plugin}/.claude-plugin/plugin.json"
marketplace_json="${repo_root}/.claude-plugin/marketplace.json"

if [[ ! -f "$plugin_json" ]]; then
  echo "release-bump: plugin manifest not found: $plugin_json" >&2
  exit 1
fi
if [[ ! -f "$marketplace_json" ]]; then
  echo "release-bump: marketplace manifest not found: $marketplace_json" >&2
  exit 1
fi
if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "release-bump: version must be MAJOR.MINOR.PATCH, got: $new_version" >&2
  exit 1
fi

write_json() {
  local file="$1" tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  mv "$tmp" "$file"
}

jq --arg v "$new_version" '.version = $v' "$plugin_json" | write_json "$plugin_json"

jq --arg name "$plugin" --arg v "$new_version" \
  '(.plugins[] | select(.name == $name) | .version) = $v' \
  "$marketplace_json" | write_json "$marketplace_json"

if git tag -l "${plugin}-v*" | grep -q .; then
  marketplace_bump="patch"
else
  marketplace_bump="minor"
fi

current_marketplace="$(jq -r '.metadata.version' "$marketplace_json")"
if [[ ! "$current_marketplace" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "release-bump: invalid current marketplace version: $current_marketplace" >&2
  exit 1
fi
major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

case "$marketplace_bump" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac
new_marketplace="${major}.${minor}.${patch}"

jq --arg v "$new_marketplace" '.metadata.version = $v' "$marketplace_json" \
  | write_json "$marketplace_json"

echo "release-bump: ${plugin} ${new_version}; marketplace ${current_marketplace} -> ${new_marketplace} (${marketplace_bump})"
