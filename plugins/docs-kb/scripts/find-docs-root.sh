#!/bin/bash
# find-docs-root.sh — Locate the root _index.md in the repo.
# Breadth-first search: finds the shallowest _index.md starting from repo root.
# Short-circuits at first match. Returns its containing directory.
# Usage: DOCS_DIR="$(bash find-docs-root.sh)"

set -euo pipefail

for depth in 0 1 2 3 4 5; do
    result=$(find . -mindepth "$depth" -maxdepth "$depth" -name "_index.md" \
             -not -path "./.git/*" -not -path "./.claude/*" -not -path "./node_modules/*" \
             -print -quit 2>/dev/null)
    if [ -n "$result" ]; then
        dirname "$result"
        exit 0
    fi
done

# Not found
echo "Docs not initialized: no _index.md found within 5 levels of repo root." >&2
exit 1
