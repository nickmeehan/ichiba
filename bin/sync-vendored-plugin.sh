#!/usr/bin/env bash
set -euo pipefail

# Sync a vendored plugin from its upstream repo's latest release tag.
#
# Usage: sync-vendored-plugin.sh <plugin-name> <github-owner/repo>
#
# Vendored plugins (.github/vendored-plugins) are versioned by their
# upstream repo, not by this marketplace's semantic-release. This script
# adopts the newest upstream `vX.Y.Z` tag as-is and reuses
# bin/release-bump.sh for the marketplace bookkeeping (plugin entry version
# plus the top-level marketplace version bump). It only mutates the working
# tree; committing, tagging, and pushing are the calling workflow's job.
#
# Upstream states without a release tag never sync: if the newest tag
# already matches the marketplace entry, this is a no-op even when upstream
# main has newer commits.
#
# Outputs (stdout, and $GITHUB_OUTPUT when set):
#   synced=true|false
#   version=<X.Y.Z>          (when synced)
#   upstream_tag=<vX.Y.Z>    (when synced)
#   upstream_sha=<sha>       (when synced)

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <plugin-name> <github-owner/repo>" >&2
  exit 64
fi

plugin="$1"
upstream="$2"
upstream_url="https://github.com/${upstream}"

repo_root="$(git rev-parse --show-toplevel)"
marketplace_json="${repo_root}/.claude-plugin/marketplace.json"
dest="${repo_root}/plugins/${plugin}"

emit() {
  echo "$1"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "$1" >> "$GITHUB_OUTPUT"
  fi
}

latest_tag="$(git ls-remote --tags "$upstream_url" \
  | awk '{ print $2 }' \
  | sed -e 's|^refs/tags/||' -e 's|\^{}$||' \
  | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort -u | sort -V | tail -n 1 || true)"

if [[ -z "$latest_tag" ]]; then
  echo "sync: no vX.Y.Z release tags found in ${upstream}" >&2
  exit 1
fi
version="${latest_tag#v}"

current="$(jq -r --arg name "$plugin" \
  '[.plugins[] | select(.name == $name) | .version] | first // ""' \
  "$marketplace_json")"

if [[ "$current" == "$version" ]]; then
  echo "sync: ${plugin} already at ${version}; nothing to do"
  emit "synced=false"
  exit 0
fi

if [[ -n "$(git -C "$repo_root" tag -l "${plugin}-v${version}")" ]]; then
  echo "sync: tag ${plugin}-v${version} already exists but the marketplace entry is at '${current:-none}' — refusing to re-release; resolve by hand" >&2
  exit 1
fi

src_dir="$(mktemp -d)"
trap 'rm -rf "$src_dir"' EXIT

git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$latest_tag" "$upstream_url" "$src_dir"
upstream_sha="$(git -C "$src_dir" rev-parse HEAD)"

src_manifest="${src_dir}/.claude-plugin/plugin.json"
if [[ ! -f "$src_manifest" ]]; then
  echo "sync: upstream has no .claude-plugin/plugin.json at ${latest_tag}" >&2
  exit 1
fi

manifest_name="$(jq -r '.name // ""' "$src_manifest")"
if [[ -n "$manifest_name" && "$manifest_name" != "$plugin" ]]; then
  echo "sync: upstream plugin.json name '${manifest_name}' does not match '${plugin}'" >&2
  exit 1
fi

manifest_version="$(jq -r '.version // ""' "$src_manifest")"
if [[ "$manifest_version" != "$version" ]]; then
  echo "sync: upstream plugin.json version '${manifest_version}' does not match tag ${latest_tag}" >&2
  exit 1
fi

# Mirror the upstream release verbatim, minus repo housekeeping that is not
# plugin content.
rm -rf \
  "${src_dir}/.git" \
  "${src_dir}/.github" \
  "${src_dir}/.claude" \
  "${src_dir}/.gitignore" \
  "${src_dir}/.DS_Store" \
  "${src_dir}/node_modules"

rm -rf "$dest"
mkdir -p "$(dirname "$dest")"
cp -a "$src_dir" "$dest"

write_json() {
  local file="$1" tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  mv "$tmp" "$file"
}

description="$(jq -r '.description // ""' "$src_manifest")"
if [[ -z "$current" ]]; then
  jq --arg name "$plugin" --arg desc "$description" --arg source "./plugins/${plugin}" \
    '.plugins += [{ name: $name, version: "0.0.0", description: $desc, source: $source }] | .plugins |= sort_by(.name)' \
    "$marketplace_json" | write_json "$marketplace_json"
else
  jq --arg name "$plugin" --arg desc "$description" \
    '(.plugins[] | select(.name == $name) | .description) = $desc' \
    "$marketplace_json" | write_json "$marketplace_json"
fi

bash "${repo_root}/bin/release-bump.sh" "$plugin" "$version"

emit "synced=true"
emit "version=${version}"
emit "upstream_tag=${latest_tag}"
emit "upstream_sha=${upstream_sha}"
