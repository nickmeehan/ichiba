#!/bin/bash

# sync-impeccable.sh
# Syncs skills from pbakaus/impeccable into plugins/impeccable/.
# Compares upstream source/skills/ against local copy and updates if changed.
#
# Usage:
#   bin/sync-impeccable.sh              # check and sync
#   bin/sync-impeccable.sh --check      # check only, exit 1 if out of date

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }
print_info()    { echo -e "${YELLOW}→${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

UPSTREAM_REPO="https://github.com/pbakaus/impeccable.git"
UPSTREAM_BRANCH="main"
PLUGIN_DIR="$REPO_ROOT/plugins/impeccable"
SKILLS_DIR="$PLUGIN_DIR/skills"
MARKETPLACE_FILE="$REPO_ROOT/.claude-plugin/marketplace.json"
PLUGIN_MANIFEST="$PLUGIN_DIR/.claude-plugin/plugin.json"

CHECK_ONLY=false
if [ "$1" = "--check" ]; then
    CHECK_ONLY=true
fi

# Clone upstream into a temp directory (shallow, single branch)
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

print_info "Fetching upstream impeccable..."
git clone --depth 1 --branch "$UPSTREAM_BRANCH" --single-branch "$UPSTREAM_REPO" "$TMPDIR/impeccable" 2>/dev/null

UPSTREAM_SKILLS="$TMPDIR/impeccable/source/skills"
UPSTREAM_PLUGIN_JSON="$TMPDIR/impeccable/.claude-plugin/plugin.json"

if [ ! -d "$UPSTREAM_SKILLS" ]; then
    print_error "Upstream source/skills/ directory not found"
    exit 1
fi

# Compare upstream vs local
CHANGES=false
ADDED_SKILLS=()
UPDATED_SKILLS=()
REMOVED_SKILLS=()

# Check for new or updated skills
for skill_dir in "$UPSTREAM_SKILLS"/*/; do
    skill_name="$(basename "$skill_dir")"
    local_skill="$SKILLS_DIR/$skill_name"

    if [ ! -d "$local_skill" ]; then
        CHANGES=true
        ADDED_SKILLS+=("$skill_name")
    else
        if ! diff -rq "$skill_dir" "$local_skill" >/dev/null 2>&1; then
            CHANGES=true
            UPDATED_SKILLS+=("$skill_name")
        fi
    fi
done

# Check for removed skills
for skill_dir in "$SKILLS_DIR"/*/; do
    [ ! -d "$skill_dir" ] && continue
    skill_name="$(basename "$skill_dir")"
    if [ ! -d "$UPSTREAM_SKILLS/$skill_name" ]; then
        CHANGES=true
        REMOVED_SKILLS+=("$skill_name")
    fi
done

if [ "$CHANGES" = false ]; then
    print_success "Skills are up to date with upstream."
    exit 0
fi

# Report changes
echo
print_info "Changes detected:"
for s in "${ADDED_SKILLS[@]}"; do echo "  + $s (new)"; done
for s in "${UPDATED_SKILLS[@]}"; do echo "  ~ $s (updated)"; done
for s in "${REMOVED_SKILLS[@]}"; do echo "  - $s (removed upstream)"; done
echo

if [ "$CHECK_ONLY" = true ]; then
    print_error "Local skills are out of date with upstream."
    exit 1
fi

# Sync skills
print_info "Syncing skills..."

# Copy new and updated skills
for skill_dir in "$UPSTREAM_SKILLS"/*/; do
    skill_name="$(basename "$skill_dir")"
    rm -rf "$SKILLS_DIR/$skill_name"
    cp -r "$skill_dir" "$SKILLS_DIR/$skill_name"
done

# Remove skills that no longer exist upstream
for s in "${REMOVED_SKILLS[@]}"; do
    rm -rf "$SKILLS_DIR/$s"
done

# Update LICENSE and NOTICE.md if changed
for file in LICENSE NOTICE.md; do
    upstream_file="$TMPDIR/impeccable/$file"
    local_file="$PLUGIN_DIR/$file"
    if [ -f "$upstream_file" ]; then
        cp "$upstream_file" "$local_file"
    fi
done

# Read upstream version
UPSTREAM_VERSION=$(jq -r '.version' "$UPSTREAM_PLUGIN_JSON" 2>/dev/null)
if [ -z "$UPSTREAM_VERSION" ] || [ "$UPSTREAM_VERSION" = "null" ]; then
    print_error "Could not read upstream version from plugin.json"
    exit 1
fi

# Update plugin.json version
print_info "Updating plugin version to $UPSTREAM_VERSION..."
jq --arg v "$UPSTREAM_VERSION" '.version = $v' "$PLUGIN_MANIFEST" > "$PLUGIN_MANIFEST.tmp"
mv "$PLUGIN_MANIFEST.tmp" "$PLUGIN_MANIFEST"

# Update marketplace.json plugin entry version
print_info "Updating marketplace.json plugin entry..."
jq --arg v "$UPSTREAM_VERSION" '(.plugins[] | select(.name == "impeccable")).version = $v' \
    "$MARKETPLACE_FILE" > "$MARKETPLACE_FILE.tmp"
mv "$MARKETPLACE_FILE.tmp" "$MARKETPLACE_FILE"

# Bump marketplace top-level version (patch)
CURRENT_MARKETPLACE_VERSION=$(jq -r '.metadata.version' "$MARKETPLACE_FILE")
IFS='.' read -r major minor patch <<< "$CURRENT_MARKETPLACE_VERSION"
NEW_MARKETPLACE_VERSION="$major.$minor.$((patch + 1))"
print_info "Bumping marketplace version: $CURRENT_MARKETPLACE_VERSION → $NEW_MARKETPLACE_VERSION"
jq --arg v "$NEW_MARKETPLACE_VERSION" '.metadata.version = $v' "$MARKETPLACE_FILE" > "$MARKETPLACE_FILE.tmp"
mv "$MARKETPLACE_FILE.tmp" "$MARKETPLACE_FILE"

echo
print_success "Sync complete."
print_info "Plugin version: $UPSTREAM_VERSION"
print_info "Marketplace version: $NEW_MARKETPLACE_VERSION"
echo
print_info "Changes summary:"
[ ${#ADDED_SKILLS[@]} -gt 0 ] && echo "  Added: ${ADDED_SKILLS[*]}"
[ ${#UPDATED_SKILLS[@]} -gt 0 ] && echo "  Updated: ${UPDATED_SKILLS[*]}"
[ ${#REMOVED_SKILLS[@]} -gt 0 ] && echo "  Removed: ${REMOVED_SKILLS[*]}"
echo
print_info "Next steps: review changes, run validation, commit, and push."
