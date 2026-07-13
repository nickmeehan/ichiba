#!/usr/bin/env bash
set -euo pipefail

# Print the plugin directory names eligible for semantic-release, one per
# line. Vendored plugins (see .github/vendored-plugins) are excluded: their
# versions are adopted from upstream releases by a sync workflow, so the
# release pipeline must never re-bump them.

repo_root="$(git rev-parse --show-toplevel)"
vendored_file="${repo_root}/.github/vendored-plugins"

vendored=""
if [[ -f "$vendored_file" ]]; then
  vendored="$(awk '!/^[[:space:]]*#/ && NF { print $1 }' "$vendored_file")"
fi

for dir in "$repo_root"/plugins/*/; do
  name="$(basename "$dir")"
  if grep -qxF "$name" <<< "$vendored"; then
    continue
  fi
  echo "$name"
done
