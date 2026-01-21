# Hook Input Schema Reference

All hooks receive JSON data via **stdin**. This reference documents the complete schema for each event type.

## Common Fields (All Events)

Every hook receives these base fields:

```json
{
  "session_id": "abc123def456",
  "transcript_path": "/Users/username/.claude/projects/my-project/abc123/session.jsonl",
  "cwd": "/Users/username/projects/my-project",
  "permission_mode": "default",
  "hook_event_name": "EventName"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | string | Unique identifier for this Claude Code session |
| `transcript_path` | string | Absolute path to the conversation transcript (JSONL format) |
| `cwd` | string | Current working directory |
| `permission_mode` | string | Permission mode: `"default"`, `"plan"`, `"acceptEdits"`, `"bypassPermissions"` |
| `hook_event_name` | string | Name of the hook event being triggered |

## PreToolUse

Triggered **before** Claude executes a tool.

```json
{
  "session_id": "abc123",
  "transcript_path": "...",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "file content here"
  },
  "tool_use_id": "toolu_01ABC123XYZ"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `tool_name` | string | Name of tool about to execute (e.g., "Write", "Edit", "Bash") |
| `tool_input` | object | Parameters being passed to the tool (tool-specific schema) |
| `tool_use_id` | string | Unique identifier for this tool invocation |

### Common Tool Input Schemas

**Write/Edit/MultiEdit:**
```json
{
  "tool_input": {
    "file_path": "/absolute/path/to/file.txt",
    "content": "file content"  // Write only
    "old_string": "...",       // Edit only
    "new_string": "..."        // Edit only
  }
}
```

**Bash:**
```json
{
  "tool_input": {
    "command": "npm test",
    "description": "Run test suite",
    "timeout": 120000
  }
}
```

**Read:**
```json
{
  "tool_input": {
    "file_path": "/absolute/path/to/file.txt",
    "offset": 0,
    "limit": 2000
  }
}
```

**Grep:**
```json
{
  "tool_input": {
    "pattern": "function.*export",
    "path": "/path/to/search",
    "output_mode": "content",
    "glob": "*.ts"
  }
}
```

**Task:**
```json
{
  "tool_input": {
    "subagent_type": "Bash",
    "prompt": "Fix the failing tests",
    "description": "Fix tests"
  }
}
```

## PermissionRequest

Triggered when permission dialog is shown to user.

Schema identical to **PreToolUse**:
```json
{
  "session_id": "abc123",
  "hook_event_name": "PermissionRequest",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf node_modules"
  },
  "tool_use_id": "toolu_01ABC123"
}
```

## PostToolUse

Triggered **after** tool executes successfully.

```json
{
  "session_id": "abc123",
  "transcript_path": "...",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "file content"
  },
  "tool_response": {
    "filePath": "/path/to/file.txt",
    "success": true
  },
  "tool_use_id": "toolu_01ABC123"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `tool_name` | string | Tool that was executed |
| `tool_input` | object | Parameters that were used |
| `tool_response` | object | Result returned by the tool |
| `tool_use_id` | string | Unique tool invocation ID |

### Tool Response Examples

**Write:**
```json
{
  "tool_response": {
    "filePath": "/path/to/file.txt",
    "success": true
  }
}
```

**Bash:**
```json
{
  "tool_response": {
    "output": "test output here",
    "exitCode": 0
  }
}
```

**Read:**
```json
{
  "tool_response": {
    "content": "file contents...",
    "lineCount": 150
  }
}
```

## Notification

Triggered when Claude Code sends a notification.

```json
{
  "session_id": "abc123",
  "transcript_path": "...",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "Notification",
  "message": "Claude needs your permission to use Bash",
  "notification_type": "permission_prompt"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `message` | string | Notification message text |
| `notification_type` | string | Type of notification (see below) |

### Notification Types

| Type | When Triggered |
|------|----------------|
| `permission_prompt` | Permission dialog shown |
| `idle_prompt` | Claude waiting for input (60+ seconds idle) |
| `auth_success` | User authenticated successfully |
| `elicitation_dialog` | MCP tool needs additional input |

## UserPromptSubmit

Triggered when user submits a prompt.

```json
{
  "session_id": "abc123",
  "transcript_path": "...",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "UserPromptSubmit",
  "prompt": "Write a function to calculate factorial"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `prompt` | string | The user's submitted prompt text |

## Stop

Triggered when main Claude Code agent finishes responding.

```json
{
  "session_id": "abc123",
  "transcript_path": "...",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
```

| Field | Type | Description |
|-------|------|-------------|
| `stop_hook_active` | boolean | `true` if Claude already continuing due to previous stop hook |

**⚠️ CRITICAL:** Always check `stop_hook_active` to prevent infinite loops!

```python
if input_data.get("stop_hook_active"):
    sys.exit(0)  # Already continuing, don't loop
```

## SubagentStop

Triggered when a subagent (Task tool) finishes.

Schema identical to **Stop**:
```json
{
  "session_id": "abc123",
  "hook_event_name": "SubagentStop",
  "stop_hook_active": false
}
```

**⚠️ CRITICAL:** Also check `stop_hook_active` for subagent hooks!

## PreCompact

Triggered before Claude Code runs compaction.

```json
{
  "session_id": "abc123",
  "transcript_path": "...",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "PreCompact",
  "trigger": "manual",
  "custom_instructions": ""
}
```

| Field | Type | Description |
|-------|------|-------------|
| `trigger` | string | `"manual"` (user invoked `/compact`) or `"auto"` (automatic) |
| `custom_instructions` | string | Custom compaction instructions (if provided) |

## SessionStart

Triggered when Claude Code session starts or resumes.

```json
{
  "session_id": "abc123",
  "transcript_path": "...",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "SessionStart",
  "source": "startup"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `source` | string | How session started (see below) |

### Session Start Sources

| Source | When Triggered |
|--------|----------------|
| `startup` | Fresh session start |
| `resume` | From `--resume`, `--continue`, or `/resume` |
| `clear` | From `/clear` command |
| `compact` | After automatic or manual compaction |

### Environment Variable Persistence

**SessionStart is the ONLY event** with access to `CLAUDE_ENV_FILE`:

```bash
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
    echo 'export API_URL=http://localhost:3000' >> "$CLAUDE_ENV_FILE"
fi
```

## SessionEnd

Triggered when session ends.

```json
{
  "session_id": "abc123",
  "transcript_path": "...",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "SessionEnd",
  "reason": "clear"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `reason` | string | Why session ended (see below) |

### Session End Reasons

| Reason | Description |
|--------|-------------|
| `clear` | Session cleared with `/clear` |
| `logout` | User logged out |
| `prompt_input_exit` | User exited during prompt input |
| `other` | Other exit reasons |

## Parsing Input Data

### Python
```python
#!/usr/bin/env python3
import json
import sys

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Invalid JSON: {e}", file=sys.stderr)
    sys.exit(1)

# Access fields safely
session_id = input_data.get("session_id", "")
hook_event = input_data.get("hook_event_name", "")
tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})
```

### Bash
```bash
#!/bin/bash
set -euo pipefail

# Read entire stdin
input=$(cat)

# Parse with jq
session_id=$(echo "$input" | jq -r '.session_id // ""')
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Check if field exists
if [ -z "$tool_name" ]; then
    exit 0  # No tool, pass through
fi
```

### Node.js
```javascript
#!/usr/bin/env node
const readline = require('readline');

let inputData = '';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

rl.on('line', (line) => {
  inputData += line;
});

rl.on('close', () => {
  try {
    const data = JSON.parse(inputData);

    const sessionId = data.session_id || '';
    const toolName = data.tool_name || '';
    const toolInput = data.tool_input || {};

    // Your logic here

    process.exit(0);
  } catch (error) {
    console.error('Invalid JSON:', error.message);
    process.exit(1);
  }
});
```

## Environment Variables

Available to all hooks:

| Variable | Description | Example |
|----------|-------------|---------|
| `CLAUDE_PROJECT_DIR` | Absolute path to project root | `/Users/john/projects/myapp` |
| `CLAUDE_PLUGIN_ROOT` | Plugin directory (plugin hooks only) | `/Users/john/.claude/plugins/my-plugin` |
| `CLAUDE_ENV_FILE` | Env persistence file (SessionStart only) | `/tmp/claude-env-abc123.sh` |
| `CLAUDE_CODE_REMOTE` | "true" if web environment | `true` or empty |

### Usage Example
```bash
#!/bin/bash
cd "$CLAUDE_PROJECT_DIR"

# Now in project root
git status
```

## Reading Transcript

The transcript file (`transcript_path`) contains the full conversation in JSONL format:

```python
import json

transcript_path = input_data.get("transcript_path", "")

messages = []
with open(transcript_path, 'r') as f:
    for line in f:
        messages.append(json.loads(line))

# Analyze conversation history
for msg in messages:
    if msg.get('role') == 'user':
        print(msg.get('content'))
```

## Permission Modes

| Mode | Description |
|------|-------------|
| `default` | Normal permission checking |
| `plan` | Plan mode (planning changes) |
| `acceptEdits` | Auto-accept edits mode |
| `bypassPermissions` | Bypass all permissions |

Hooks can check mode and adjust behavior:

```python
permission_mode = input_data.get("permission_mode", "default")

if permission_mode == "bypassPermissions":
    # Skip validation since permissions already bypassed
    sys.exit(0)
```

## Testing with Sample Data

Create test fixtures:

```bash
# test-fixtures/pre-tool-use-write.json
{
  "session_id": "test123",
  "transcript_path": "/tmp/test.jsonl",
  "cwd": "/tmp/test-project",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/tmp/test-project/src/index.ts",
    "content": "console.log('hello');"
  },
  "tool_use_id": "test_001"
}
```

Test hook:
```bash
cat test-fixtures/pre-tool-use-write.json | python3 hooks/my-hook.py
```

## Schema Validation

Validate hook input programmatically:

```python
def validate_hook_input(data: dict, event_name: str) -> bool:
    """Validate hook input has required fields."""

    # Common fields
    required_common = ['session_id', 'hook_event_name', 'cwd']
    for field in required_common:
        if field not in data:
            return False

    # Event-specific fields
    if event_name in ['PreToolUse', 'PermissionRequest', 'PostToolUse']:
        if 'tool_name' not in data or 'tool_input' not in data:
            return False

    if event_name == 'Notification':
        if 'notification_type' not in data:
            return False

    if event_name == 'UserPromptSubmit':
        if 'prompt' not in data:
            return False

    return True

# Usage
if not validate_hook_input(input_data, 'PreToolUse'):
    print("Invalid hook input", file=sys.stderr)
    sys.exit(1)
```

## Quick Reference

| Event | Key Fields |
|-------|------------|
| PreToolUse | `tool_name`, `tool_input`, `tool_use_id` |
| PermissionRequest | `tool_name`, `tool_input`, `tool_use_id` |
| PostToolUse | `tool_name`, `tool_input`, `tool_response` |
| Notification | `message`, `notification_type` |
| UserPromptSubmit | `prompt` |
| Stop | `stop_hook_active` |
| SubagentStop | `stop_hook_active` |
| PreCompact | `trigger`, `custom_instructions` |
| SessionStart | `source` |
| SessionEnd | `reason` |
