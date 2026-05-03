#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-origin/main}"
head_ref="${2:-HEAD}"

failed=0
while IFS= read -r commit; do
  [[ -z "$commit" ]] && continue
  scopes="$(git show --name-only --pretty=format: "$commit" \
    | grep '^plugins/' \
    | sed -E 's|^plugins/([^/]+)/.*|\1|' \
    | sort -u || true)"
  if [[ -z "$scopes" ]]; then
    continue
  fi
  count="$(printf '%s\n' "$scopes" | wc -l | tr -d ' ')"
  if [[ "$count" -gt 1 ]]; then
    short="$(git log -1 --format='%h %s' "$commit")"
    echo "::error::Commit ${short} touches multiple plugins:" >&2
    printf '  - %s\n' $scopes >&2
    echo "  Split into one commit per plugin." >&2
    failed=1
  fi
done < <(git rev-list "${base_ref}..${head_ref}")

exit "$failed"
