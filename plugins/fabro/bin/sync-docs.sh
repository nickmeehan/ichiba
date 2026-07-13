#!/usr/bin/env bash
# Mirror the Fabro docs (docs.fabro.sh) into fabro-docs/ as raw markdown.
# Re-run any time to refresh; git diff shows what changed upstream.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p fabro-docs
curl -fsSL https://docs.fabro.sh/llms.txt -o fabro-docs/llms.txt

grep -oE 'https://docs\.fabro\.sh/[^ )]+\.(md|yaml)' fabro-docs/llms.txt | sort -u |
  xargs -P 8 -I{} sh -c '
    url="{}"
    path="fabro-docs/${url#https://docs.fabro.sh/}"
    mkdir -p "${path%/*}"
    curl -fsSL --retry 2 "$url" -o "$path" && echo "$path"
  '

echo "Synced $(find fabro-docs -name '*.md' | wc -l | tr -d ' ') pages."
