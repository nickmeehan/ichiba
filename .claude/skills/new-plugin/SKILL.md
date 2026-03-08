---
name: new-plugin
description: Create a new blank Claude Code plugin when the user requests to create/make/generate a plugin or wants a plugin for a specific purpose
---

# New Plugin

Create a new Claude Code plugin for the Ichiba marketplace by executing the plugin generator script at `bin/generate-plugin.sh`.

## When to Use This Skill

Use this skill automatically when the user:
- Asks to "create a plugin for [purpose]"
- Says "make a plugin that [does something]"
- Says "generate a new plugin for [use case]"
- Requests to "create a plugin" without specifying details
- Wants to scaffold a new plugin structure

## Steps

1. **Gather information** — ask the user if not already provided:
   - **Plugin name**: Must be lowercase with hyphens (e.g., "my-awesome-plugin")
   - **Plugin description**: A clear description of what the plugin does (minimum 20 characters)
   - **Author name**: The plugin author (defaults to "nickmeehan")

   When parsing natural language:
   - **Description**: The "for [X]" or "that [does Y]" part. Expand to a full sentence if needed.
   - **Name**: Only if explicitly stated (e.g., "create a plugin called X"). Otherwise ask.
   - **Author**: Only if explicitly mentioned. Otherwise ask.

2. **Run the generator script** with the provided information:
   ```bash
   ./bin/generate-plugin.sh "<plugin-name>" "<description>" "<author>"
   ```

   **IMPORTANT**: Always provide all three arguments to avoid interactive prompts.

3. **Inform the user** of:
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
│   └── .gitkeep
├── agents/
│   └── .gitkeep
├── skills/
│   └── .gitkeep
├── hooks/
│   └── .gitkeep
└── README.md             # Plugin documentation
```

## Important Notes

- The plugin.json will be initialized with empty component arrays
- The marketplace.json will be automatically updated with the new plugin entry
- Directories are created empty (with .gitkeep files) — add only what you need
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

### Natural Language
```
User: "Create a plugin for managing database migrations"

Actions:
1. Extract description: "managing database migrations"
2. Ask for plugin name and author
3. Run: ./bin/generate-plugin.sh "db-migrations" "A plugin for managing database migrations" "nickmeehan"
```

### With Explicit Name
```
User: "Create a plugin called awesome-linter for linting code"

Actions:
1. Extract name: "awesome-linter", description: "linting code"
2. Ask for author (default: nickmeehan)
3. Run: ./bin/generate-plugin.sh "awesome-linter" "A plugin for linting code" "nickmeehan"
```
