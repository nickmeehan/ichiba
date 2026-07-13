#!/usr/bin/env bash
# Writes the released version into .claude-plugin/plugin.json.
# Called by semantic-release (see release.config.js).
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: $0 MAJOR.MINOR.PATCH" >&2
  exit 64
fi

manifest="$(git rev-parse --show-toplevel)/.claude-plugin/plugin.json"
# ruby instead of jq — jq isn't guaranteed locally, ruby is the repo's scripting language
ruby -rjson -e '
  path, version = ARGV
  j = JSON.parse(File.read(path))
  j["version"] = version
  File.write(path, JSON.pretty_generate(j) + "\n")
' "$manifest" "$1"

echo "release-bump: fabro $1"
