---
name: new-plugin
description: Create a new Claude Code plugin when the user requests to create/make/generate a plugin or wants a plugin for a specific purpose
---

# New Plugin Skill

This skill helps create new Claude Code plugins for the Ichiba marketplace using the plugin generator script.

## When to Use This Skill

Use this skill automatically when the user:
- Asks to "create a plugin for [purpose]"
- Says "make a plugin that [does something]"
- Says "generate a new plugin for [use case]"
- Requests to "create a plugin" without specifying the purpose
- Wants to scaffold a new plugin structure

## How It Works

1. **Extract Information**: Parse the user's request to extract:
   - Plugin purpose/description from their natural language request
   - Plugin name if explicitly mentioned (otherwise derive from description)
   - Author name if mentioned

2. **Generate Plugin Name**: If not explicitly provided:
   - Convert the description into a lowercase, hyphenated name
   - Keep it short (2-4 words max)
   - Example: "GitHub issue management" → "github-issue-manager"
   - Example: "database migrations" → "db-migrations"

3. **Prepare Description**:
   - Use the user's natural language description
   - Ensure it's at least 20 characters
   - Make it clear and descriptive
   - Example: "A plugin that helps manage GitHub issues and pull requests"

4. **Run the Generator**:
   ```bash
   ./bin/generate-plugin.sh "<plugin-name>" "<description>" "<author>"
   ```
   - The script creates the full plugin structure
   - Updates marketplace.json automatically
   - Generates template files for all component types

5. **Report Results**: Tell the user:
   - The plugin was created successfully
   - The location of the new plugin
   - The structure that was generated
   - Next steps for customizing the plugin

## Examples

### Example 1: Natural Language Request
```
User: "Create a plugin for managing database migrations"

Actions:
1. Extract description: "A plugin for managing database migrations"
2. Generate name: "db-migrations"
3. Run: ./bin/generate-plugin.sh "db-migrations" "A plugin for managing database migrations" "nickmeehan"
4. Confirm creation and show location
```

### Example 2: Specific Purpose
```
User: "I need a plugin that helps with code reviews"

Actions:
1. Extract description: "A plugin that helps with code reviews"
2. Generate name: "code-review-helper"
3. Run: ./bin/generate-plugin.sh "code-review-helper" "A plugin that helps with code reviews" "nickmeehan"
4. Confirm creation and show location
```

### Example 3: With Explicit Name
```
User: "Create a plugin called awesome-linter for linting code"

Actions:
1. Use provided name: "awesome-linter"
2. Extract description: "A plugin for linting code"
3. Run: ./bin/generate-plugin.sh "awesome-linter" "A plugin for linting code" "nickmeehan"
4. Confirm creation and show location
```

## Default Values

- **Author**: Default to "nickmeehan" (the script's default)
- **Version**: Always "1.0.0" (set by the generator)
- **Components**: All directories created with example templates

## Plugin Structure Created

The generator creates:
```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/
│   └── example.md            # Example command template
├── agents/
│   └── example.md            # Example agent template
├── skills/
│   └── example/
│       └── SKILL.md          # Example skill template
├── hooks/
│   ├── hooks.json            # Example hooks config
│   └── README.md             # Hooks documentation
├── .mcp.json.example         # Example MCP config
├── MCP_README.md             # MCP documentation
└── README.md                 # Plugin documentation
```

## Important Notes

- **Plugin names** must be lowercase with hyphens only (validated by script)
- **Descriptions** must be at least 20 characters (validated by script)
- **Template files** are created for all component types (commands, agents, skills, hooks, MCP)
- **Marketplace** is automatically updated with the new plugin entry
- The generator will fail if a plugin with the same name already exists

## After Plugin Creation

Inform the user they can:
1. Navigate to `plugins/<plugin-name>/` to customize the plugin
2. Remove example template files and create actual components
3. Update `plugin.json` to reflect which components are included
4. Test the plugin locally
5. Update the README.md with usage examples

## Error Handling

If the generator script fails:
- Check the error message from the script
- Common issues:
  - Plugin already exists
  - Invalid plugin name (not lowercase/hyphens)
  - Description too short (< 20 characters)
  - Missing jq (required for marketplace.json updates)
- Report the error clearly to the user with suggestions

## Quick Reference

Script location: `bin/generate-plugin.sh`
Script signature: `<plugin-name> <description> [author]`
Default author: `nickmeehan`
Min description length: 20 characters
Plugin name pattern: `^[a-z0-9-]+$`
