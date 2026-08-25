#!/usr/bin/env bash
# Mirror the Fabro docs (docs.fabro.sh) into fabro-docs/ as raw markdown.
# Re-run any time to refresh; git diff shows what changed upstream.
#
# llms.txt is the authority on what the mirror should hold. A page missing from
# it was retired upstream and gets pruned; a page listed in it that won't fetch
# is a bad request, so the existing copy is carried forward rather than dropped.
# Never prune on "didn't download" — that would delete the mirror on a bad day.
#
# The fetch stages into a temp tree and lands in one go, so a run that gives up
# leaves fabro-docs/ exactly as it was instead of half-written.
#
# Two tolerances, both percentages of the mirror, both overridable:
#   FAIL_LIMIT   pages allowed to fail and keep their existing copy (default 5)
#   PRUNE_LIMIT  pages allowed to disappear in one run (default 10)
set -euo pipefail
cd "$(dirname "$0")/.."

FAIL_LIMIT=${FAIL_LIMIT:-5}
PRUNE_LIMIT=${PRUNE_LIMIT:-10}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
stage="$work/stage"
mkdir -p "$stage"

curl -fsSL https://docs.fabro.sh/llms.txt -o "$stage/llms.txt"
grep -oE 'https://docs\.fabro\.sh/[^ )]+\.(md|yaml)' "$stage/llms.txt" | sort -u >"$work/index"

: >"$work/failed"
STAGE="$stage" FAILED="$work/failed" xargs -P 8 -I{} sh -c '
  url="{}"
  rel="${url#https://docs.fabro.sh/}"
  path="$STAGE/$rel"
  mkdir -p "${path%/*}"
  # curl -f still creates the output file before it learns the response was an
  # error, so an unwritten page has to be cleaned up, not just reported.
  if curl -fsSL --retry 3 --retry-delay 2 "$url" -o "$path" && [ -s "$path" ]; then
    echo "$rel"
  else
    rm -f "$path"
    echo "$rel" >>"$FAILED"
  fi
' <"$work/index"

want=$(grep -c . "$work/index" || true)
sort -u -o "$work/failed" "$work/failed"
failed=$(grep -c . "$work/failed" || true)

if [ "$failed" -gt $(((want * FAIL_LIMIT + 99) / 100)) ]; then
  echo "sync-docs: $failed of $want pages failed to fetch (limit ${FAIL_LIMIT}%)." >&2
  echo "  That is an upstream or network problem, not a docs change. Aborting" >&2
  echo "  with fabro-docs/ untouched; re-run when docs.fabro.sh is healthy." >&2
  sed 's|^|  |' "$work/failed" >&2
  exit 1
fi

# A page that would not fetch keeps whatever the mirror already had, so one bad
# request costs that page's freshness rather than the whole sync.
carried=0
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  if [ -f "fabro-docs/$rel" ]; then
    mkdir -p "$stage/${rel%/*}"
    cp -a "fabro-docs/$rel" "$stage/$rel"
    carried=$((carried + 1))
    echo "sync-docs: $rel would not fetch, keeping the copy already in the mirror" >&2
  else
    echo "sync-docs: $rel would not fetch and is not in the mirror yet, skipping" >&2
  fi
done <"$work/failed"

# Prune against the index, never against what happened to download.
{ echo llms.txt; sed 's|^https://docs\.fabro\.sh/||' "$work/index"; } | sort -u >"$work/expected"
: >"$work/old"
if [ -d fabro-docs ]; then
  (cd fabro-docs && find . -type f | sed 's|^\./||' | sort) >"$work/old"
fi
comm -23 "$work/old" "$work/expected" >"$work/gone"

old_count=$(grep -c . "$work/old" || true)
gone_count=$(grep -c . "$work/gone" || true)
if [ "$old_count" -gt 0 ] && [ "$gone_count" -gt $((old_count * PRUNE_LIMIT / 100)) ]; then
  echo "sync-docs: $gone_count of $old_count pages are missing from llms.txt (limit ${PRUNE_LIMIT}%)," >&2
  echo "  which looks like a bad upstream index rather than real retirements. Aborting." >&2
  echo "  Re-run with PRUNE_LIMIT=100 if the removals are genuine." >&2
  sed 's|^|  |' "$work/gone" >&2
  exit 1
fi

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  rm -f "fabro-docs/$rel"
done <"$work/gone"

mkdir -p fabro-docs
cp -a "$stage/." fabro-docs/
find fabro-docs -mindepth 1 -type d -empty -delete

echo "Synced $(find fabro-docs -name '*.md' | wc -l | tr -d ' ') pages, pruned $gone_count, carried $carried stale."
