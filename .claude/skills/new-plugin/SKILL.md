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

2. **Ask which components the plugin needs** — present these options and let the user select one or more:
   - **commands** — Slash commands (`.md` files users invoke with `/command-name`)
   - **agents** — Specialized agents (`.md` files invoked via the Task tool)
   - **skills** — Agent skills (directories with `SKILL.md` that Claude auto-discovers)
   - **hooks** — Event handlers (shell commands triggered by lifecycle events)
   - **mcp** — MCP server configuration (Model Context Protocol integrations)

   If the user isn't sure, suggest starting with only the components they know they need — they can always add directories later. Do NOT default to "all".

3. **Run the generator script** with the selected components:
   ```bash
   ./bin/generate-plugin.sh "<plugin-name>" "<description>" "<author>" "<components>"
   ```

   The 4th argument is a comma-separated list of selected components (e.g., `"commands,skills"`).

   **IMPORTANT**: Always provide all four arguments to avoid interactive prompts and to prevent unnecessary scaffold files.

4. **Validate the new plugin** to confirm no stale scaffold files were created:
   ```bash
   ./bin/validate-plugin.sh "plugins/<plugin-name>"
   ```

   If validation fails (exit code 1), review the output — scaffold files will only exist for the components the user selected, which is expected for a brand-new plugin. The user should replace them with real content before committing.

5. **Inform the user** of:
   - The plugin location
   - Which components were scaffolded (and which were skipped)
   - That scaffold/example files need to be replaced with real content before committing
   - How to run `bin/validate-plugin.sh` themselves to check for leftover placeholders

## Plugin Structure

The generator creates only the directories for selected components. For example, if the user selects `commands` and `skills`:

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest with metadata
├── commands/
│   └── example.md        # Template — replace with real commands
├── skills/
│   └── example/
│       └── SKILL.md      # Template — replace with real skills
└── README.md             # Plugin documentation
```

Directories for unselected components (agents, hooks, mcp in this example) are **not created**, keeping the plugin clean from the start.

## Important Notes

- The plugin.json will be initialized with empty component arrays
- The marketplace.json will be automatically updated with the new plugin entry
- Only selected component directories are created with example templates
- Scaffold files (example.md, etc.) are meant to be replaced — run `bin/validate-plugin.sh` before committing to catch any leftovers

## After Creation

The user can then:
1. Replace scaffold files with real content for each selected component
2. Update `plugin.json` to list the components
3. Add more component directories later if needed (manually or re-run)
4. Run `bin/validate-plugin.sh plugins/<plugin-name>` before committing
5. Test the plugin locally

## Examples

### Natural Language
```
User: "Create a plugin for managing database migrations"

Actions:
1. Extract description: "managing database migrations"
2. Ask for plugin name and author
3. Ask which components: user selects "commands" and "skills"
4. Run: ./bin/generate-plugin.sh "db-migrations" "A plugin for managing database migrations" "nickmeehan" "commands,skills"
5. Run: ./bin/validate-plugin.sh "plugins/db-migrations"
```

### With Explicit Name
```
User: "Create a plugin called awesome-linter for linting code"

Actions:
1. Extract name: "awesome-linter", description: "linting code"
2. Ask for author (default: nickmeehan)
3. Ask which components: user selects "commands" and "hooks"
4. Run: ./bin/generate-plugin.sh "awesome-linter" "A plugin for linting code" "nickmeehan" "commands,hooks"
5. Run: ./bin/validate-plugin.sh "plugins/awesome-linter"
```
