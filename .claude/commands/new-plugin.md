---
name: new-plugin
description: Create a new blank Claude Code plugin with sane defaults
---

You are being asked to create a new Claude Code plugin for the Ichiba marketplace.

## Task

Generate a new blank plugin by executing the plugin generator script located at `scripts/generate-plugin.sh`.

## Steps

1. Ask the user for the following information if not already provided:
   - **Plugin name**: Must be lowercase with hyphens (e.g., "my-awesome-plugin")
   - **Plugin description**: A clear description of what the plugin does (minimum 20 characters)
   - **Author name**: The plugin author (defaults to git user.name if available)

2. Run the generator script with the provided information:
   ```bash
   ./scripts/generate-plugin.sh "<plugin-name>" "<description>" "<author>"
   ```

3. After the plugin is created, inform the user:
   - The plugin location
   - The structure that was created
   - Next steps for adding components

## Plugin Structure

The generator will create the following structure:

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest with metadata
├── commands/
│   └── .gitkeep          # Ready for slash commands
├── agents/
│   └── .gitkeep          # Ready for specialized agents
├── skills/
│   └── .gitkeep          # Ready for agent skills
├── hooks/
│   └── .gitkeep          # Ready for event handlers
└── README.md             # Plugin documentation
```

## Important Notes

- The plugin.json will be initialized with empty component arrays
- The marketplace.json will be automatically updated with the new plugin entry
- All directories are created but empty (with .gitkeep files)
- The README includes a basic template to fill out

## After Creation

The user can then:
1. Add commands by creating `.md` files in `commands/`
2. Add agents by creating `.md` files in `agents/`
3. Add skills by creating `skill-name/SKILL.md` in `skills/`
4. Add hooks by creating `hooks.json` in `hooks/`
5. Update `plugin.json` to list the components
6. Test the plugin locally

## Examples

Create a plugin interactively:
```
/new-plugin
```

Create a plugin with all arguments:
```
/new-plugin my-plugin "A helpful plugin that does something useful for development workflows" "John Doe"
```
