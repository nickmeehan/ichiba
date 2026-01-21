# Claude Code Hooks: Complete Reference

This is a condensed reference. For the complete mastery guide with all details, examples, and advanced patterns, see the original documentation.

## Quick Reference

### Hook Events

| Event | When | Matchers | Can Block | Common Use |
|-------|------|----------|-----------|------------|
| **PreToolUse** | Before tool runs | Required | Yes | Validate, block sensitive files |
| **PostToolUse** | After tool runs | Required | Feedback | Format, lint |
| **SessionStart** | Session begins | Optional | Context | Load git context, setup env |
| **Stop** | Agent finishes | No | Yes | Check tests, create commits |
| **UserPromptSubmit** | User submits | No | Yes | Add context, validate |
| **Notification** | Notifications | Required | No | Custom alerts |
| **PermissionRequest** | Permission shown | Required | Yes | Auto-approve/deny |
| **SubagentStop** | Subagent finishes | No | Yes | Evaluate completion |
| **PreCompact** | Before compact | Optional | No | Backup transcripts |
| **SessionEnd** | Session ends | No | No | Cleanup, logging |

### Exit Codes

- **0** - Success (stdout may be added to context for SessionStart/UserPromptSubmit)
- **2** - Block/deny operation (stderr shown to Claude)
- **Other** - Non-blocking error (stderr shown to user)

### Configuration Structure

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "path/to/script",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

### Common Matchers

```json
"matcher": "Write"                    // Exact match
"matcher": "Edit|Write|MultiEdit"    // Multiple tools
"matcher": "*"                       // All tools
"matcher": "mcp__.*"                 // All MCP tools
```

### Environment Variables

- `$CLAUDE_PROJECT_DIR` - Project root path
- `$CLAUDE_PLUGIN_ROOT` - Plugin directory
- `$CLAUDE_ENV_FILE` - Environment persistence (SessionStart only)
- `$CLAUDE_CODE_REMOTE` - "true" if web environment

### Input Schema (Common Fields)

```json
{
  "session_id": "abc123",
  "hook_event_name": "EventName",
  "cwd": "/path/to/project",
  "tool_name": "ToolName",
  "tool_input": { /* tool parameters */ }
}
```

### Script Template

```python
#!/usr/bin/env python3
import json
import sys

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(1)

# Your logic here

sys.exit(0)  # Success
```

### Decision Control (JSON Output)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Reason here"
  }
}
```

## Quick Recipes

### Auto-format after edits
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [{
        "type": "command",
        "command": "jq -r '.tool_input.file_path' | { read f; [[ \"$f\" =~ \\.ts$ ]] && prettier --write \"$f\"; }"
      }]
    }]
  }
}
```

### Block sensitive files
```python
# .claude/hooks/block-sensitive.py
import json, sys
data = json.load(sys.stdin)
path = data.get("tool_input", {}).get("file_path", "")
if any(s in path for s in ['.env', 'credentials']):
    print("Cannot modify sensitive file", file=sys.stderr)
    sys.exit(2)
sys.exit(0)
```

### Inject git context on start
```bash
# .claude/hooks/git-context.sh
echo "Branch: $(git branch --show-current)"
echo "Recent commits:"
git log --oneline -5
```

### Check tests before stop
```python
# .claude/hooks/check-tests.py
import json, sys, subprocess
data = json.load(sys.stdin)
if data.get("stop_hook_active"):
    sys.exit(0)
result = subprocess.run(['npm', 'test'], capture_output=True)
if result.returncode != 0:
    print(json.dumps({
        "decision": "block",
        "reason": "Tests failing"
    }))
sys.exit(0)
```

## Critical Rules

### Stop/SubagentStop Hooks
**ALWAYS check `stop_hook_active` first:**
```python
if input_data.get("stop_hook_active"):
    sys.exit(0)
```

### Security
- Validate all file paths (no `..`)
- Quote shell variables: `"$var"` not `$var`
- Skip sensitive files (.env, credentials, keys)
- Use absolute paths or `$CLAUDE_PROJECT_DIR`

### Performance
- Keep hooks under 60 seconds
- Exit early for non-matching files
- Use efficient validation logic
- Handle errors gracefully

## File Locations

- **User global**: `~/.claude/settings.json`
- **Project shared**: `.claude/settings.json` (committed)
- **Project local**: `.claude/settings.local.json` (not committed)
- **Plugin hooks**: `.claude-plugin/hooks/hooks.json`

## Debugging

```bash
# Enable debug mode
claude --debug

# Test hook manually
echo '{...}' | python3 hook.py
echo $?

# Validate configuration
python3 .claude/skills/create-hooks/scripts/validate-hook-config.py .claude/settings.json

# Review active hooks
# In Claude Code: /hooks
```

## Common Patterns

**Multi-language formatter:**
```bash
case "$file_path" in
  *.ts|*.js) prettier --write "$file_path" ;;
  *.py) black "$file_path" ;;
  *.go) gofmt -w "$file_path" ;;
esac
```

**Conditional auto-approve:**
```python
if tool_name == "Read" and file_path.endswith('.md'):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow"
        }
    }))
```

**Environment persistence (SessionStart):**
```bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
fi
```

## Integration

### Skills
```markdown
---
name: my-skill
hooks:
  PostToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "./format.sh"
---
```

### Plugins
Create `hooks/hooks.json` in plugin:
```json
{
  "description": "Auto-formatting plugin",
  "hooks": { /* hook config */ }
}
```

## Resources

- Event details: `./events/[event-name].md`
- Examples: `./examples/`
- Best practices: `./_shared/best-practices.md`
- Input schema: `./_shared/input-schema.md`
- Validation: `./_shared/validation.md`
- Complete documentation: See original hooks mastery guide
