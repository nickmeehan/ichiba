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

# Function to generate example command template
generate_command_template() {
    cat > "$PLUGIN_DIR/commands/example.md" << 'EOF'
---
name: example
description: Brief description of what this command does
argument-hint: [optional-argument]
---

You are being asked to perform a specific task via the example command.

## Task

[Describe what this command should do]

## Steps

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Notes

- You can use \$ARGUMENTS to access arguments passed to the command
- Remove this file and create your actual command files
- Commands are automatically loaded from any .md file in this directory

## Example

When user runs: \`/example "some value"\`

The command receives "some value" in \$ARGUMENTS
EOF
}

# Function to generate example agent template
generate_agent_template() {
    cat > "$PLUGIN_DIR/agents/example.md" << 'EOF'
---
name: example
description: Brief description of what this agent does
---

You are a specialized agent for [specific task].

## Your Role

[Describe the agent's purpose and capabilities]

## Available Tools

You have access to:
- [Tool 1]
- [Tool 2]
- [Tool 3]

## Guidelines

1. [Guideline 1]
2. [Guideline 2]
3. [Guideline 3]

## Notes

- Remove this file and create your actual agent files
- Agents are markdown files that define specialized behaviors
- They are invoked via the Task tool with the agent name
EOF
}

# Function to generate example skill template
generate_skill_template() {
    mkdir -p "$PLUGIN_DIR/skills/example"

    cat > "$PLUGIN_DIR/skills/example/SKILL.md" << 'EOF'
---
name: example
description: Brief description of what this skill does and when to use it
---

# Example Skill

[Detailed description of what this skill does]

## When to Use This Skill

Use this skill when:
- [Condition 1]
- [Condition 2]
- [Condition 3]

## How It Works

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Examples

### Example 1
[Description and example]

### Example 2
[Description and example]

## Notes

- The description in frontmatter is critical - it's how Claude decides to use this skill
- Remove this example and create your actual skills
- Each skill should be in its own directory with a SKILL.md file
- Skills are automatically discovered and available to Claude
EOF
}

# Function to generate example hooks configuration
generate_hooks_template() {
    cat > "$PLUGIN_DIR/hooks/hooks.json" << 'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'File modified: ${TOOL_INPUT}'",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
EOF

    cat > "$PLUGIN_DIR/hooks/README.md" << 'EOF'
# Hooks

Hooks are shell commands that run at specific points in Claude Code's lifecycle.

## Available Hook Events

- `PreToolUse` - Before a tool runs
- `PostToolUse` - After a tool completes successfully
- `Notification` - When Claude sends an alert
- `Stop` - When the AI agent finishes its response
- `UserPromptSubmit` - When user submits a prompt
- `SessionStart` - When a session starts

## Example Configuration

The `hooks.json` file contains an example hook. Modify it for your needs.

## Hook Communication

Hooks receive JSON via stdin and communicate through:
- Exit code 0 = Success
- Exit code non-zero = Failure
- stdout = Output shown to user (or added to context for certain events)
- stderr = Error messages

## Remove This

Remove the example hooks.json and create your actual hooks configuration.
EOF
}

# Function to generate MCP configuration template
generate_mcp_template() {
    cat > "$PLUGIN_DIR/.mcp.json.example" << 'EOF'
{
  "mcpServers": {
    "example-server": {
      "command": "npx",
      "args": [
        "-y",
        "@example/mcp-server"
      ],
      "env": {
        "API_KEY": "your-api-key-here"
      }
    }
  }
}
EOF

    cat > "$PLUGIN_DIR/MCP_README.md" << 'EOF'
# MCP (Model Context Protocol) Configuration

MCP servers provide external tools and resources to Claude Code.

## Setup

1. Rename `.mcp.json.example` to `.mcp.json`
2. Configure your MCP server(s)
3. Update plugin.json to set "mcp": true

## Example Servers

Popular MCP servers include:
- `@modelcontextprotocol/server-filesystem` - File system access
- `@modelcontextprotocol/server-github` - GitHub integration
- `@modelcontextprotocol/server-postgres` - PostgreSQL access
- Custom servers built for your specific needs

## Remove This

Remove this file and .mcp.json.example once you've set up your MCP configuration.
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

    # Generate template files for each component type
    print_info "Creating template files..."
    generate_command_template
    generate_agent_template
    generate_skill_template
    generate_hooks_template
    generate_mcp_template

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
