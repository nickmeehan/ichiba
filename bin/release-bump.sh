#!/usr/bin/env bash
set -euo pipefail

# Set a native plugin's version in both manifests (plugin.json and the
# marketplace.json entry), then bump the top-level marketplace version via
# bin/marketplace-bump.sh. Called by semantic-release's prepare step
# (release.config.js). Vendored plugins never come through here — their
# version is adopted by bin/sync-vendored-plugin.sh and the marketplace
# bump happens in bin/finalize-vendored-releases.sh.

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

echo "release-bump: ${plugin} -> ${new_version}"

bash "${repo_root}/bin/marketplace-bump.sh" "$plugin"
