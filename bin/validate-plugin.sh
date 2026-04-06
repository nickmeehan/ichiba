#!/bin/bash

# validate-plugin.sh
# Checks for leftover scaffold files and version mismatches.
# Schema validation is handled by `claude plugin validate`.
#
# Usage:
#   bin/validate-plugin.sh plugins/my-plugin   # check one plugin
#   bin/validate-plugin.sh                      # check all plugins

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }
print_info()    { echo -e "${YELLOW}→${NC} $1"; }

SCAFFOLD_FILES=(
    "commands/example.md"
    "agents/example.md"
    "skills/example/SKILL.md"
    "hooks/README.md"
    ".mcp.json.example"
    "MCP_README.md"
)

check_scaffold_files() {
    local plugin_dir="$1"
    local plugin_name
    plugin_name="$(basename "$plugin_dir")"
    local found=0

    for file in "${SCAFFOLD_FILES[@]}"; do
        if [ -f "$plugin_dir/$file" ]; then
            print_error "$plugin_name: scaffold file found — $file"
            found=1
        fi
    done

    if [ -f "$plugin_dir/hooks/hooks.json" ] && \
       grep -q "echo 'File modified" "$plugin_dir/hooks/hooks.json" 2>/dev/null; then
        print_error "$plugin_name: scaffold file found — hooks/hooks.json (contains placeholder content)"
        found=1
    fi

    return $found
}

check_version_sync() {
    local plugin_dir="$1"
    local marketplace_file="$2"
    local plugin_name
    plugin_name="$(basename "$plugin_dir")"
    local manifest="$plugin_dir/.claude-plugin/plugin.json"

    if [ ! -f "$manifest" ]; then
        return 0
    fi

    local plugin_version marketplace_version
    plugin_version=$(jq -r '.version // empty' "$manifest" 2>/dev/null)
    marketplace_version=$(jq -r --arg name "$plugin_name" '.plugins[] | select(.name == $name) | .version // empty' "$marketplace_file" 2>/dev/null)

    if [ -n "$plugin_version" ] && [ -n "$marketplace_version" ] && [ "$plugin_version" != "$marketplace_version" ]; then
        print_error "$plugin_name: version mismatch — plugin.json has '$plugin_version' but marketplace.json has '$marketplace_version'"
        return 1
    fi

    return 0
}

main() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

    local dirs=()
    if [ -n "$1" ]; then
        if [[ "$1" = /* ]]; then
            dirs+=("$1")
        else
            dirs+=("$REPO_ROOT/$1")
        fi
    else
        for d in "$REPO_ROOT"/plugins/*/; do
            [ -d "$d/.claude-plugin" ] && dirs+=("$d")
        done
    fi

    if [ ${#dirs[@]} -eq 0 ]; then
        print_info "No plugin directories found to validate."
        exit 0
    fi

    local any_failed=0
    local marketplace_file="$REPO_ROOT/.claude-plugin/marketplace.json"

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_error "Directory not found: $dir"
            any_failed=1
            continue
        fi

        local pname
        pname="$(basename "$dir")"
        print_info "Checking $pname..."

        if ! check_scaffold_files "$dir"; then
            any_failed=1
        fi
        if ! check_version_sync "$dir" "$marketplace_file"; then
            any_failed=1
        fi
    done

    echo
    if [ $any_failed -ne 0 ]; then
        print_error "Validation failed. Fix the errors above before committing."
        exit 1
    else
        print_success "All checks passed."
        exit 0
    fi
}

main "$@"
