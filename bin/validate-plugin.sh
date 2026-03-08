#!/bin/bash

# validate-plugin.sh
# Checks a plugin directory for leftover scaffold/placeholder files
# that should be removed before committing.
#
# Usage:
#   bin/validate-plugin.sh plugins/my-plugin   # check one plugin
#   bin/validate-plugin.sh                      # check all plugins

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }
print_info()    { echo -e "${YELLOW}→${NC} $1"; }

# Known scaffold files that should be replaced or removed
SCAFFOLD_FILES=(
    "commands/example.md"
    "agents/example.md"
    "skills/example/SKILL.md"
    "hooks/README.md"
    ".mcp.json.example"
    "MCP_README.md"
)

# Check a single plugin directory for scaffold files
# Returns 0 if clean, 1 if scaffold files found
check_plugin() {
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

    # Special check for hooks/hooks.json — only flag if it contains
    # the scaffold placeholder content, not a real config
    if [ -f "$plugin_dir/hooks/hooks.json" ] && \
       grep -q "echo 'File modified" "$plugin_dir/hooks/hooks.json" 2>/dev/null; then
        print_error "$plugin_name: scaffold file found — hooks/hooks.json (contains placeholder content)"
        found=1
    fi

    return $found
}

main() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

    local dirs=()
    if [ -n "$1" ]; then
        # Resolve relative to repo root if not absolute
        if [[ "$1" = /* ]]; then
            dirs+=("$1")
        else
            dirs+=("$REPO_ROOT/$1")
        fi
    else
        # Scan all plugin directories
        for d in "$REPO_ROOT"/plugins/*/; do
            [ -d "$d" ] && dirs+=("$d")
        done
    fi

    if [ ${#dirs[@]} -eq 0 ]; then
        print_info "No plugin directories found to validate."
        exit 0
    fi

    local any_failed=0
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_error "Directory not found: $dir"
            any_failed=1
            continue
        fi
        if ! check_plugin "$dir"; then
            any_failed=1
        fi
    done

    echo
    if [ $any_failed -ne 0 ]; then
        print_error "Scaffold files detected. Replace them with real content or delete them before committing."
        exit 1
    else
        print_success "All plugins are clean — no scaffold files found."
        exit 0
    fi
}

main "$@"
