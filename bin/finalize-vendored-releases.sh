#!/usr/bin/env bash
set -euo pipefail

# Cut the release for any vendored plugin whose marketplace entry version
# has no matching <plugin>-v<version> tag yet. The sync workflow adopts
# upstream content and the entry version (a `chore(vendor)` commit to
# main); this script does what semantic-release does for native plugins:
# bump the top-level marketplace version (bin/marketplace-bump.sh), commit
# `chore(release): <plugin> <version> [skip ci]`, tag, push, and create a
# GitHub Release.
#
# Detection is state-based (entry version vs tags), not commit-based, so a
# run that failed halfway self-heals on the next push to main. Requires
# full tag history, push access to origin/main, and `gh` with GH_TOKEN.

repo_root="$(git rev-parse --show-toplevel)"
vendored_file="${repo_root}/.github/vendored-plugins"
marketplace_json="${repo_root}/.claude-plugin/marketplace.json"

if [[ ! -f "$vendored_file" ]]; then
  echo "finalize: no ${vendored_file}; nothing to do"
  exit 0
fi

while read -r plugin upstream; do
  version="$(jq -r --arg name "$plugin" \
    '[.plugins[] | select(.name == $name) | .version] | first // ""' \
    "$marketplace_json")"

  if [[ -z "$version" ]]; then
    echo "finalize: ${plugin} has no marketplace entry yet; skipping"
    continue
  fi
  if [[ -n "$(git -C "$repo_root" tag -l "${plugin}-v${version}")" ]]; then
    echo "finalize: ${plugin} ${version} already released; nothing to do"
    continue
  fi

  bash "${repo_root}/bin/marketplace-bump.sh" "$plugin"

  git -C "$repo_root" add "$marketplace_json"
  git -C "$repo_root" commit \
    -m "chore(release): ${plugin} ${version} [skip ci]" \
    -m "Marketplace release for the vendored ${plugin} sync (chore(vendor) commit)."
  git -C "$repo_root" tag "${plugin}-v${version}"
  git -C "$repo_root" push origin HEAD:main "refs/tags/${plugin}-v${version}"
  gh release create "${plugin}-v${version}" \
    --title "${plugin}-v${version}" \
    --notes "Vendored from [${upstream} v${version}](https://github.com/${upstream}/releases/tag/v${version})."
done < <(awk '!/^[[:space:]]*#/ && NF { print $1, $2 }' "$vendored_file")
