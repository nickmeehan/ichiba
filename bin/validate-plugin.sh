#!/bin/bash

# validate-plugin.sh
# Validates plugin and marketplace schemas, checks for leftover scaffold files,
# and cross-checks version consistency.
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

# --- Scaffold checks ---

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

# --- Plugin schema checks ---

validate_plugin_schema() {
    local plugin_dir="$1"
    local plugin_name
    plugin_name="$(basename "$plugin_dir")"
    local manifest="$plugin_dir/.claude-plugin/plugin.json"
    local errors=0

    if [ ! -f "$manifest" ]; then
        print_error "$plugin_name: missing .claude-plugin/plugin.json"
        return 1
    fi

    if ! jq empty "$manifest" 2>/dev/null; then
        print_error "$plugin_name: plugin.json is not valid JSON"
        return 1
    fi

    # name: required, kebab-case
    local name
    name=$(jq -r '.name // empty' "$manifest")
    if [ -z "$name" ]; then
        print_error "$plugin_name: plugin.json missing required field 'name'"
        errors=1
    elif [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        print_error "$plugin_name: plugin.json 'name' must be kebab-case (got '$name')"
        errors=1
    fi

    # author: must be object, not string
    local author_type
    author_type=$(jq -r '.author | type' "$manifest")
    if [ "$author_type" = "string" ]; then
        print_error "$plugin_name: plugin.json 'author' must be an object {\"name\": \"...\"}, not a string"
        errors=1
    elif [ "$author_type" = "object" ]; then
        local author_name
        author_name=$(jq -r '.author.name // empty' "$manifest")
        if [ -z "$author_name" ]; then
            print_error "$plugin_name: plugin.json 'author.name' is required when author is present"
            errors=1
        fi
    fi

    # reject legacy 'components' wrapper
    if jq -e '.components' "$manifest" >/dev/null 2>&1; then
        print_error "$plugin_name: plugin.json uses legacy 'components' wrapper — move skills/agents/hooks/mcpServers to top level"
        errors=1
    fi

    # reject legacy 'mcp' (should be 'mcpServers')
    if jq -e 'has("mcp")' "$manifest" | grep -q true; then
        print_error "$plugin_name: plugin.json uses legacy 'mcp' field — rename to 'mcpServers'"
        errors=1
    fi

    # hooks/mcpServers must not be boolean
    for field in hooks mcpServers; do
        local field_type
        field_type=$(jq -r ".$field | type" "$manifest")
        if [ "$field_type" = "boolean" ]; then
            print_error "$plugin_name: plugin.json '$field' must be a path string, array, or object — not a boolean"
            errors=1
        fi
    done

    return $errors
}

# --- Marketplace schema checks ---

validate_marketplace_schema() {
    local marketplace_file="$1"
    local errors=0

    if [ ! -f "$marketplace_file" ]; then
        print_error "marketplace.json not found at $marketplace_file"
        return 1
    fi

    if ! jq empty "$marketplace_file" 2>/dev/null; then
        print_error "marketplace.json is not valid JSON"
        return 1
    fi

    # name: required
    local name
    name=$(jq -r '.name // empty' "$marketplace_file")
    if [ -z "$name" ]; then
        print_error "marketplace.json missing required field 'name'"
        errors=1
    fi

    # owner: required, must be object with .name
    local owner_type
    owner_type=$(jq -r '.owner | type' "$marketplace_file")
    if [ "$owner_type" = "null" ]; then
        print_error "marketplace.json missing required field 'owner'"
        errors=1
    elif [ "$owner_type" = "string" ]; then
        print_error "marketplace.json 'owner' must be an object {\"name\": \"...\"}, not a string"
        errors=1
    elif [ "$owner_type" = "object" ]; then
        local owner_name
        owner_name=$(jq -r '.owner.name // empty' "$marketplace_file")
        if [ -z "$owner_name" ]; then
            print_error "marketplace.json 'owner.name' is required"
            errors=1
        fi
    fi

    # reject legacy top-level fields
    if jq -e 'has("author")' "$marketplace_file" | grep -q true; then
        print_error "marketplace.json uses legacy 'author' field — use 'owner' instead"
        errors=1
    fi
    for field in version description; do
        if jq -e "has(\"$field\")" "$marketplace_file" | grep -q true; then
            print_error "marketplace.json has top-level '$field' — move it under 'metadata'"
            errors=1
        fi
    done

    # plugins: required array
    local plugins_type
    plugins_type=$(jq -r '.plugins | type' "$marketplace_file")
    if [ "$plugins_type" != "array" ]; then
        print_error "marketplace.json missing or invalid 'plugins' array"
        errors=1
    else
        local count
        count=$(jq '.plugins | length' "$marketplace_file")
        for ((i=0; i<count; i++)); do
            local entry_name entry_source
            entry_name=$(jq -r ".plugins[$i].name // empty" "$marketplace_file")
            entry_source=$(jq -r ".plugins[$i].source // empty" "$marketplace_file")

            if [ -z "$entry_name" ]; then
                print_error "marketplace.json plugins[$i]: missing 'name'"
                errors=1
            fi
            if [ -z "$entry_source" ]; then
                local entry_path
                entry_path=$(jq -r ".plugins[$i].path // empty" "$marketplace_file")
                if [ -n "$entry_path" ]; then
                    print_error "marketplace.json plugins[$i] ($entry_name): uses legacy 'path' — rename to 'source'"
                else
                    print_error "marketplace.json plugins[$i] ($entry_name): missing 'source'"
                fi
                errors=1
            fi
        done
    fi

    return $errors
}

# --- Main ---

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

    # Validate marketplace schema
    print_info "Validating marketplace schema..."
    if ! validate_marketplace_schema "$marketplace_file"; then
        any_failed=1
    else
        print_success "marketplace.json schema is valid"
    fi

    echo

    # Validate each plugin
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_error "Directory not found: $dir"
            any_failed=1
            continue
        fi

        local pname
        pname="$(basename "$dir")"
        print_info "Validating $pname..."

        if ! check_scaffold_files "$dir"; then
            any_failed=1
        fi
        if ! validate_plugin_schema "$dir"; then
            any_failed=1
        else
            print_success "$pname: plugin.json schema is valid"
        fi

        # Cross-check: plugin version must match marketplace entry
        local plugin_version marketplace_version
        plugin_version=$(jq -r '.version // empty' "$dir/.claude-plugin/plugin.json" 2>/dev/null)
        marketplace_version=$(jq -r --arg name "$pname" '.plugins[] | select(.name == $name) | .version // empty' "$marketplace_file" 2>/dev/null)
        if [ -n "$plugin_version" ] && [ -n "$marketplace_version" ] && [ "$plugin_version" != "$marketplace_version" ]; then
            print_error "$pname: version mismatch — plugin.json has '$plugin_version' but marketplace.json has '$marketplace_version'"
            any_failed=1
        fi
    done

    echo
    if [ $any_failed -ne 0 ]; then
        print_error "Validation failed. Fix the errors above before committing."
        exit 1
    else
        print_success "All validations passed."
        exit 0
    fi
}

main "$@"
