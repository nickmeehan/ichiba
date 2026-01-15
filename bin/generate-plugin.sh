#!/bin/bash

# generate-plugin.sh
# Creates a new blank Claude Code plugin with sane defaults

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}→${NC} $1"
}

# Function to validate plugin name
validate_plugin_name() {
    local name=$1
    if [[ ! $name =~ ^[a-z0-9-]+$ ]]; then
        print_error "Plugin name must contain only lowercase letters, numbers, and hyphens"
        exit 1
    fi
}

# Function to generate plugin.json
generate_plugin_json() {
    local name=$1
    local description=$2
    local author=$3

    cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" << EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "$description",
  "author": "$author",
  "components": {
    "commands": [],
    "agents": [],
    "skills": [],
    "hooks": false,
    "mcp": false
  }
}
EOF
}

# Function to generate README.md
generate_readme() {
    local name=$1
    local description=$2

    cat > "$PLUGIN_DIR/README.md" << EOF
# $name

$description

## Installation

\`\`\`bash
/plugin install $name@nickmeehan/ichiba
\`\`\`

## Components

This plugin includes:

<!-- Update this section as you add components -->
- No components yet

## Usage

<!-- Add usage examples here -->

## Configuration

<!-- Add any configuration options here -->

## Requirements

<!-- List any requirements or dependencies -->

## License

MIT
EOF
}

# Function to update marketplace.json
update_marketplace_json() {
    local name=$1
    local description=$2
    local plugin_path=$3

    local marketplace_file="$REPO_ROOT/.claude-plugin/marketplace.json"

    # Create new plugin entry and add it to the plugins array using jq
    jq --arg name "$name" \
       --arg desc "$description" \
       --arg path "$plugin_path" \
       '.plugins += [{
         "name": $name,
         "version": "1.0.0",
         "description": $desc,
         "path": $path
       }]' "$marketplace_file" > "$marketplace_file.tmp" && \
    mv "$marketplace_file.tmp" "$marketplace_file"
}

# Main script
main() {
    # Get script directory and repo root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    PLUGINS_DIR="$REPO_ROOT/plugins"

    print_info "Claude Code Plugin Generator"
    echo

    # Get plugin name
    if [ -z "$1" ]; then
        read -p "Enter plugin name (lowercase, hyphens allowed): " PLUGIN_NAME
    else
        PLUGIN_NAME="$1"
    fi

    validate_plugin_name "$PLUGIN_NAME"

    # Get plugin description
    if [ -z "$2" ]; then
        read -p "Enter plugin description: " PLUGIN_DESCRIPTION
    else
        PLUGIN_DESCRIPTION="$2"
    fi

    # Validate description length
    if [ ${#PLUGIN_DESCRIPTION} -lt 20 ]; then
        print_error "Description must be at least 20 characters"
        exit 1
    fi

    # Get author name (default to nickmeehan)
    if [ -z "$3" ]; then
        DEFAULT_AUTHOR="nickmeehan"
        read -p "Enter author name [$DEFAULT_AUTHOR]: " PLUGIN_AUTHOR
        PLUGIN_AUTHOR="${PLUGIN_AUTHOR:-$DEFAULT_AUTHOR}"
    else
        PLUGIN_AUTHOR="$3"
    fi

    # Set plugin directory
    PLUGIN_DIR="$PLUGINS_DIR/$PLUGIN_NAME"

    # Check if plugin already exists
    if [ -d "$PLUGIN_DIR" ]; then
        print_error "Plugin '$PLUGIN_NAME' already exists at $PLUGIN_DIR"
        exit 1
    fi

    echo
    print_info "Creating plugin structure..."

    # Create plugin directories
    mkdir -p "$PLUGIN_DIR/.claude-plugin"
    mkdir -p "$PLUGIN_DIR/commands"
    mkdir -p "$PLUGIN_DIR/agents"
    mkdir -p "$PLUGIN_DIR/skills"
    mkdir -p "$PLUGIN_DIR/hooks"

    # Generate plugin files
    generate_plugin_json "$PLUGIN_NAME" "$PLUGIN_DESCRIPTION" "$PLUGIN_AUTHOR"
    generate_readme "$PLUGIN_NAME" "$PLUGIN_DESCRIPTION"

    # Create .gitkeep files for empty directories
    touch "$PLUGIN_DIR/commands/.gitkeep"
    touch "$PLUGIN_DIR/agents/.gitkeep"
    touch "$PLUGIN_DIR/skills/.gitkeep"
    touch "$PLUGIN_DIR/hooks/.gitkeep"

    print_success "Created plugin structure at $PLUGIN_DIR"

    # Update marketplace.json
    print_info "Updating marketplace.json..."
    update_marketplace_json "$PLUGIN_NAME" "$PLUGIN_DESCRIPTION" "plugins/$PLUGIN_NAME"
    print_success "Updated marketplace.json"

    echo
    print_success "Plugin '$PLUGIN_NAME' created successfully!"
    echo
    print_info "Next steps:"
    echo "  1. Add your commands, agents, or skills to the respective directories"
    echo "  2. Update the plugin.json components section"
    echo "  3. Update the README.md with usage examples"
    echo "  4. Test your plugin locally"
    echo
    print_info "Plugin location: $PLUGIN_DIR"
}

# Run main function
main "$@"
