---
name: new-plugin-skill
description: Create a new Claude Code plugin when the user requests to create/make/generate a plugin or wants a plugin for a specific purpose
---

# New Plugin Skill

This skill detects when users want to create a new plugin in natural language and automatically invokes the `/new-plugin` command with appropriate parameters.

## When to Use This Skill

Use this skill automatically when the user:
- Asks to "create a plugin for [purpose]"
- Says "make a plugin that [does something]"
- Says "generate a new plugin for [use case]"
- Requests to "create a plugin" without specifying details
- Wants to scaffold a new plugin structure

## How It Works

This skill acts as a natural language interface to the `/new-plugin` command:

1. **Detect Intent**: Recognize that the user wants to create a plugin
2. **Extract Information**: Parse the user's request to extract:
   - Plugin description from their natural language request
   - Plugin name if explicitly mentioned
   - Author name if mentioned
3. **Invoke Command**: Call `/new-plugin` with the extracted parameters
4. **Let Command Handle**: The command takes care of all the actual work

## Architecture

```
User: "Create a plugin for managing GitHub issues"
  ↓
Skill: Detects intent, extracts "managing GitHub issues"
  ↓
Invokes: /new-plugin with description
  ↓
Command: Handles all execution, validation, script running, etc.
```

## Examples

### Example 1: Natural Language Request
```
User: "Create a plugin for managing database migrations"

Skill Actions:
1. Detect: User wants to create a plugin
2. Extract description: "managing database migrations"
3. Invoke: /new-plugin with that description
4. Command handles the rest
```

### Example 2: With Explicit Name
```
User: "Create a plugin called awesome-linter for linting code"

Skill Actions:
1. Detect: User wants to create a plugin
2. Extract name: "awesome-linter"
3. Extract description: "linting code"
4. Invoke: /new-plugin --name awesome-linter --description "linting code"
5. Command handles the rest
```

### Example 3: Minimal Request
```
User: "I need a plugin that helps with code reviews"

Skill Actions:
1. Detect: User wants to create a plugin
2. Extract description: "helps with code reviews"
3. Invoke: /new-plugin with that description
4. Command handles the rest (including asking for missing info)
```

## Parameter Extraction

When parsing natural language:

- **Description**: The "for [X]" or "that [does Y]" part
  - "Create a plugin for X" → description: "X"
  - "Make a plugin that does Y" → description: "Y"
  - Expand to full sentence if needed: "X" → "A plugin for X"

- **Name**: Only if explicitly stated
  - "Create a plugin called X" → name: "X"
  - Otherwise let the command prompt for it

- **Author**: Only if explicitly mentioned
  - "Create a plugin by John" → author: "John"
  - Otherwise use command's default

## Command Delegation

All actual logic lives in the `/new-plugin` command:
- Name generation and validation
- Description validation
- Script execution
- Error handling
- User feedback
- Marketplace updates

The skill is purely for intent detection and natural language parsing.

## Benefits

- **DRY**: No duplicated logic between skill and command
- **Maintainability**: Update command once, skill benefits automatically
- **Consistency**: Same execution path whether user types `/new-plugin` or uses natural language
- **Clear separation**: Skill = intent detection, Command = execution

## Quick Reference

- **Command**: `/new-plugin`
- **Skill name**: `new-plugin-skill` (distinct from command name)
- **Purpose**: Natural language wrapper for the command
- **Logic location**: All execution logic in the command
