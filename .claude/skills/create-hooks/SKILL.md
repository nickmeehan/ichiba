---
name: create-hooks
description: Create and configure Claude Code hooks for lifecycle events (PreToolUse, PostToolUse, SessionStart, Stop, etc.). Use when user wants to add automation, validation, formatting, notifications, or context injection to their Claude Code workflow.
---

# Create Claude Code Hooks

This skill helps you create and configure hooks that execute automatically at specific points in Claude Code's lifecycle.

## Quick Hook Creation

**What hooks do:**
- Execute shell commands or LLM prompts at lifecycle events
- Provide deterministic control (always run, not LLM-dependent)
- Enable automation, validation, formatting, and context injection

**Common use cases:**
- Auto-format code after edits (prettier, black, gofmt)
- Block modifications to sensitive files (.env, credentials)
- Add git context at session start
- Run linters/tests after changes
- Send desktop notifications when Claude needs input
- Create auto-commits on stop

## Step 1: Understand the User's Goal

Ask the user:
1. **What should happen?** (format code, block files, inject context, etc.)
2. **When should it happen?** (after edits, before commands, at session start, etc.)
3. **What files/tools are involved?** (specific file types, tool names)

## Step 2: Select the Right Hook Event

Based on "when", choose the event:

| User Says | Event | Use Case |
|-----------|-------|----------|
| "Before Claude runs/executes" | `PreToolUse` | Validate, block, modify tool calls |
| "After Claude edits/writes" | `PostToolUse` | Format, lint, provide feedback |
| "When session starts" | `SessionStart` | Load context, setup environment |
| "When Claude finishes/stops" | `Stop` | Create commits, run tests |
| "When I submit a prompt" | `UserPromptSubmit` | Add context, validate prompts |
| "When Claude sends notifications" | `Notification` | Custom notifications |
| "When subagent finishes" | `SubagentStop` | Evaluate subagent completion |

**Need detailed event info?** Read `./events/[event-name].md`

## Step 3: Choose Hook Type

**Command Hook** (most common):
- Runs shell commands/scripts
- Fast and deterministic
- Best for: formatting, linting, file operations, validation

**Prompt Hook** (advanced):
- Uses LLM to evaluate decisions
- Slower but context-aware
- Best for: complex logic, task completion evaluation

## Step 4: Create the Hook Configuration

### For File Operations (Edit/Write)

**Auto-format example:**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read file_path; if echo \"$file_path\" | grep -q '\\.ts$'; then npx prettier --write \"$file_path\"; fi; }",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

**Block sensitive files:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "python3 -c \"import json, sys; data=json.load(sys.stdin); path=data.get('tool_input',{}).get('file_path',''); sys.exit(2 if any(p in path for p in ['.env', 'credentials.json', '.git/']) else 0)\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### For Session Start

**Inject git context:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo \"Current branch: $(git branch --show-current)\\nRecent commits:\\n$(git log --oneline -5)\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### For Notifications

**Desktop alerts:**
```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Awaiting your input'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### For Stop Events

**Run tests before stopping:**
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-tests.sh",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

## Step 5: Choose Configuration Location

**Options (in priority order):**
1. **Project-local**: `.claude/settings.local.json` (not committed, personal hooks)
2. **Project-shared**: `.claude/settings.json` (committed, team hooks)
3. **User-global**: `~/.claude/settings.json` (all projects)

**Recommendation:**
- Personal automation → `.local.json`
- Team standards (linting, formatting) → `.json`
- Cross-project preferences → user settings

## Step 6: Write the Configuration

1. Read the current settings file (or create if missing)
2. Merge the new hook into the existing `hooks` object
3. Write the updated configuration
4. Inform user: "Hook will activate on next session (restart or /clear)"

## Implementation Steps

1. **Determine the hook event** from user's goal
2. **Choose command vs prompt** (default to command unless complex logic needed)
3. **Write the hook configuration** using examples above as templates
4. **Select the right file** (.local.json for personal, .json for team)
5. **Validate the configuration** using `./scripts/validate-hook-config.py`
6. **Update the settings file** with proper JSON merging
7. **Provide testing instructions** to verify the hook works

## Matchers Reference

**Exact match:**
```json
"matcher": "Write"
```

**Multiple tools (regex):**
```json
"matcher": "Edit|Write|MultiEdit"
```

**All tools:**
```json
"matcher": "*"
```

**MCP tools:**
```json
"matcher": "mcp__memory__.*"
```

**No matcher** (for SessionStart, Stop, UserPromptSubmit):
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [...]
      }
    ]
  }
}
```

## Exit Codes & Decision Control

**Simple (exit codes):**
- `0` = Success (stdout may be added to context)
- `2` = Block/deny (stderr shown to Claude)
- Other = Non-blocking error (stderr shown to user)

**Advanced (JSON output):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Auto-approved documentation file"
  }
}
```

## Script Templates

### Python Hook Template
```python
#!/usr/bin/env python3
import json
import sys

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Invalid JSON: {e}", file=sys.stderr)
    sys.exit(1)

# Extract common fields
tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path", "")

# Your logic here
# Exit 0 for success
# Exit 2 to block/deny with stderr message

sys.exit(0)
```

### Bash Hook Template
```bash
#!/bin/bash
set -euo pipefail

# Read JSON from stdin
input=$(cat)

# Extract fields using jq
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Your logic here
# exit 0 for success
# exit 2 to block with stderr message

exit 0
```

## Need More Help?

**Event-specific details:** `./events/[event-name].md`
- `./events/pre-tool-use.md` - Validate/modify/block tool calls
- `./events/post-tool-use.md` - React to tool completion
- `./events/session-start.md` - Inject context, setup environment
- `./events/stop.md` - Check completion, create commits
- `./events/user-prompt-submit.md` - Validate/enrich prompts
- `./events/notification.md` - Custom notification handling

**Common patterns:** `./examples/`
- `./examples/auto-format.md` - Formatting hooks for various languages
- `./examples/security-validation.md` - Block sensitive operations
- `./examples/context-injection.md` - Add git/project context
- `./examples/notifications.md` - Desktop notifications
- `./examples/linting.md` - Run linters after edits
- `./examples/testing.md` - Test validation hooks

**Best practices:** `./_shared/best-practices.md`
**Validation:** `./_shared/validation.md`
**Input schema reference:** `./_shared/input-schema.md`
**Complete documentation:** `./references/complete-guide.md`

## Quick Decision Tree

```
User wants automation?
├─ Before tool runs → PreToolUse
│  ├─ Block files → matcher: "Edit|Write|MultiEdit", exit 2 on match
│  ├─ Validate commands → matcher: "Bash", check dangerous patterns
│  └─ Auto-approve → JSON with permissionDecision: "allow"
│
├─ After tool runs → PostToolUse
│  ├─ Format code → matcher: "Edit|Write|MultiEdit", run formatter
│  ├─ Run linter → matcher: "Edit|Write|MultiEdit", check + exit 2 if errors
│  └─ Log operations → matcher: "*", append to log file
│
├─ Session begins → SessionStart
│  ├─ Load git context → echo git status/log
│  ├─ Setup environment → export vars to $CLAUDE_ENV_FILE
│  └─ Install dependencies → run npm install, etc.
│
├─ Agent finishes → Stop
│  ├─ Run tests → check if passing, exit 2 if failures
│  ├─ Create checkpoint → git commit if changes exist
│  └─ Validate completion → check if all tasks done
│
└─ Custom notifications → Notification
   └─ matcher: "idle_prompt|permission_prompt", send desktop alert
```

## Validation & Testing

Before finalizing:
1. **Validate JSON syntax** - Use `./scripts/validate-hook-config.py`
2. **Test manually** - Run script with sample input: `echo '{...}' | python3 script.py`
3. **Check exit code** - Verify `echo $?` returns expected value
4. **Review security** - Check for command injection, path traversal
5. **Test timeout** - Ensure hook completes within timeout

## Common Mistakes to Avoid

❌ **Don't:**
- Use relative paths (use `"$CLAUDE_PROJECT_DIR"` or absolute paths)
- Forget to quote shell variables (`"$file_path"`, not `$file_path`)
- Skip validation of user input (always sanitize)
- Create infinite loops in Stop hooks (check `stop_hook_active`)
- Make hooks slow (keep under 60s, optimize scripts)

✅ **Do:**
- Make scripts executable (`chmod +x`)
- Handle JSON parse errors gracefully
- Use specific matchers (not `*` unless needed)
- Test hooks manually before deployment
- Document what each hook does

## Security Checklist

Before creating any hook that modifies files or runs commands:
- [ ] Validate and sanitize all input paths
- [ ] Block path traversal attempts (`..` in paths)
- [ ] Quote all shell variables properly
- [ ] Skip sensitive files (.env, credentials, keys)
- [ ] Use absolute paths for scripts
- [ ] Review command for injection vulnerabilities
- [ ] Test with malicious input samples

## Implementation Protocol

When user requests a hook:

1. **Clarify the goal** - Ask questions if unclear
2. **Recommend the event** - Based on their needs
3. **Suggest command vs prompt** - Default to command for simplicity
4. **Generate the configuration** - Use templates above
5. **Choose the file** - .local.json (personal) or .json (team)
6. **Validate the config** - Run validation script
7. **Write/update the file** - Merge with existing config
8. **Provide instructions** - How to test and activate
9. **Add security notes** - If hook runs sensitive operations

## Next Steps After Creation

1. Inform user: "✓ Hook configured in [file]"
2. Explain: "Will activate after session restart or /clear"
3. Provide test command: "To test manually: `echo '{...}' | [script]`"
4. Note security: "Review the hook in /hooks menu before applying"
5. Suggest monitoring: "Check .claude/hooks.log if issues occur"
