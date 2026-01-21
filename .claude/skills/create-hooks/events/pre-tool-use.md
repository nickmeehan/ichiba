# PreToolUse Hook Event

Triggers **before** Claude executes a tool, allowing you to validate, modify, approve, or deny the operation.

## When to Use

- **Block sensitive files** - Prevent edits to .env, credentials, etc.
- **Auto-approve operations** - Bypass permissions for safe operations
- **Validate inputs** - Check command safety, file paths, etc.
- **Modify tool parameters** - Change file paths, commands before execution
- **Log operations** - Track what tools are being used

## Hook Configuration

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ToolName",
        "hooks": [
          {
            "type": "command",
            "command": "path/to/script.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

## Matchers

Use matchers to target specific tools:

| Matcher | Tools Matched |
|---------|---------------|
| `"Write"` | Only Write tool |
| `"Edit\|Write\|MultiEdit"` | All file editing tools |
| `"Bash"` | Shell commands |
| `"*"` | All tools |
| `"mcp__.*"` | All MCP tools |

## Input Schema

```json
{
  "session_id": "abc123",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "content here"
  },
  "tool_use_id": "toolu_01ABC"
}
```

See `./_shared/input-schema.md` for complete schema.

## Decision Control

### Simple: Exit Codes

**Exit 0** - Allow operation:
```python
sys.exit(0)  # Tool proceeds normally
```

**Exit 2** - Block operation:
```python
print("Cannot modify .env files", file=sys.stderr)
sys.exit(2)  # Tool blocked, stderr shown to Claude
```

### Advanced: JSON Output

**Auto-approve (bypass permissions):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Documentation file auto-approved"
  },
  "suppressOutput": true
}
```

**Deny with reason:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Cannot modify production config"
  }
}
```

**Ask user:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  }
}
```

**Modify tool input:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": {
      "file_path": "/modified/path.txt"
    }
  }
}
```

## Common Use Cases

### 1. Block Sensitive Files

**Goal:** Prevent modifications to .env, credentials, etc.

```python
#!/usr/bin/env python3
import json
import sys

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path", "")

SENSITIVE_PATTERNS = ['.env', 'credentials', 'secrets', '.git/', 'private_key']

if any(pattern in file_path.lower() for pattern in SENSITIVE_PATTERNS):
    print(f"Cannot modify sensitive file: {file_path}", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
```

### 2. Validate Bash Commands

**Goal:** Block dangerous commands.

```python
#!/usr/bin/env python3
import json
import sys

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
command = tool_input.get("command", "")

DANGEROUS_PATTERNS = ['rm -rf /', 'dd if=', ':(){:|:&};:', 'mkfs']

for pattern in DANGEROUS_PATTERNS:
    if pattern in command:
        print(f"Dangerous command blocked: {pattern}", file=sys.stderr)
        sys.exit(2)

sys.exit(0)
```

### 3. Auto-Approve Documentation

**Goal:** Skip permissions for safe file reads.

```python
#!/usr/bin/env python3
import json
import sys

input_data = json.load(sys.stdin)
tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path", "")

# Auto-approve reads of documentation
if tool_name == "Read":
    if file_path.endswith(('.md', '.txt', '.json', '.yaml', '.yml')):
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "Documentation file auto-approved"
            },
            "suppressOutput": True
        }
        print(json.dumps(output))
        sys.exit(0)

sys.exit(0)
```

### 4. Path Traversal Prevention

**Goal:** Block attempts to access files outside project.

```python
#!/usr/bin/env python3
import json
import sys
import os

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path", "")

# Block path traversal
if ".." in file_path:
    print("Path traversal detected", file=sys.stderr)
    sys.exit(2)

# Ensure path is within project
project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
if project_dir:
    abs_path = os.path.abspath(file_path)
    if not abs_path.startswith(project_dir):
        print("Path outside project directory", file=sys.stderr)
        sys.exit(2)

sys.exit(0)
```

### 5. Log All Operations

**Goal:** Track tool usage for auditing.

```bash
#!/bin/bash
set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log to file
echo "$timestamp - $tool_name - $input" >> "$CLAUDE_PROJECT_DIR/.claude/tool-log.jsonl"

exit 0
```

### 6. Redirect Test Files

**Goal:** Run tests in isolated environment.

```python
#!/usr/bin/env python3
import json
import sys

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
command = tool_input.get("command", "")

# Redirect test DB to test environment
if "pytest" in command or "npm test" in command:
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {
                "command": f"TEST_ENV=1 {command}"
            }
        }
    }
    print(json.dumps(output))
    sys.exit(0)

sys.exit(0)
```

## Tool-Specific Validation

### Write/Edit/MultiEdit

```python
tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path", "")
content = tool_input.get("content", "")  # Write only

# Validate file extension
allowed_extensions = ['.ts', '.tsx', '.js', '.jsx', '.py']
if not any(file_path.endswith(ext) for ext in allowed_extensions):
    print(f"File type not allowed: {file_path}", file=sys.stderr)
    sys.exit(2)

# Check content length
if len(content) > 1_000_000:  # 1MB limit
    print("File content too large", file=sys.stderr)
    sys.exit(2)
```

### Bash

```python
tool_input = input_data.get("tool_input", {})
command = tool_input.get("command", "")
description = tool_input.get("description", "")

# Parse command
cmd_parts = command.split()
if not cmd_parts:
    sys.exit(0)

base_command = cmd_parts[0]

# Allowlist approach
ALLOWED_COMMANDS = ['git', 'npm', 'pytest', 'cargo', 'go']
if base_command not in ALLOWED_COMMANDS:
    print(f"Command not in allowlist: {base_command}", file=sys.stderr)
    sys.exit(2)
```

### Read

```python
tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path", "")

# Block reading sensitive files
if any(s in file_path for s in ['.env', 'credentials', 'private_key']):
    print("Cannot read sensitive file", file=sys.stderr)
    sys.exit(2)
```

### Task (Subagent)

```python
tool_input = input_data.get("tool_input", {})
subagent_type = tool_input.get("subagent_type", "")
prompt = tool_input.get("prompt", "")

# Log subagent launches
with open(f"{os.environ['CLAUDE_PROJECT_DIR']}/.claude/subagent.log", 'a') as f:
    f.write(f"{subagent_type}: {prompt}\n")

sys.exit(0)
```

## Best Practices

### 1. Fail Safely
Default to allowing operations unless explicitly blocked:
```python
# Don't block if uncertain
if not file_path:
    sys.exit(0)  # No file path, pass through
```

### 2. Provide Clear Reasons
```python
# Bad
sys.exit(2)

# Good
print("Cannot modify .env files - they contain secrets", file=sys.stderr)
sys.exit(2)
```

### 3. Use Allowlists When Possible
```python
# More secure than denylists
ALLOWED_EXTENSIONS = ['.ts', '.tsx', '.js', '.jsx']
if not any(file_path.endswith(ext) for ext in ALLOWED_EXTENSIONS):
    sys.exit(2)
```

### 4. Log for Debugging
```python
import logging
logging.basicConfig(filename='.claude/hooks.log', level=logging.DEBUG)
logging.debug(f"PreToolUse: {tool_name} on {file_path}")
```

### 5. Handle Missing Fields
```python
tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path", "")

if not file_path:
    sys.exit(0)  # No file path to validate
```

## Testing

```bash
# Test blocking sensitive files
echo '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": ".env"
  }
}' | python3 hooks/block-sensitive.py

echo $?  # Should be 2
```

```bash
# Test allowing normal files
echo '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "src/index.ts"
  }
}' | python3 hooks/block-sensitive.py

echo $?  # Should be 0
```

## Complete Example

```python
#!/usr/bin/env python3
"""PreToolUse hook: Block sensitive files and validate paths"""

import json
import sys
import os

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON: {e}", file=sys.stderr)
        sys.exit(1)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    # Only validate file operations
    if tool_name not in ["Write", "Edit", "MultiEdit"]:
        sys.exit(0)

    if not file_path:
        sys.exit(0)

    # Block path traversal
    if ".." in file_path:
        print("Path traversal detected", file=sys.stderr)
        sys.exit(2)

    # Block sensitive files
    sensitive = ['.env', 'credentials', 'secrets', 'private_key']
    if any(s in file_path.lower() for s in sensitive):
        print(f"Cannot modify sensitive file: {file_path}", file=sys.stderr)
        sys.exit(2)

    # Auto-approve documentation
    if file_path.endswith(('.md', '.txt', '.json')):
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "Documentation file auto-approved"
            },
            "suppressOutput": True
        }
        print(json.dumps(output))
        sys.exit(0)

    # Default: let normal permission flow proceed
    sys.exit(0)

if __name__ == "__main__":
    main()
```

Save to `.claude/hooks/pre-tool-use-validator.py`, make executable:
```bash
chmod +x .claude/hooks/pre-tool-use-validator.py
```

Configure:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre-tool-use-validator.py",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

## Troubleshooting

**Hook not triggering:**
- Check matcher pattern (case-sensitive: `"Write"` not `"write"`)
- Verify hook in `.claude/settings.json` or `.claude/settings.local.json`
- Restart session or run `/clear`

**Always blocking:**
- Check exit code logic
- Test with: `echo '{}' | python3 hook.py; echo $?`
- Review stderr output

**Permissions still showing:**
- Ensure using `permissionDecision: "allow"` in JSON output
- Verify exit code is 0 when outputting JSON
- Check `suppressOutput: true` to hide verbose output

## Related

- **PostToolUse** - React after tool executes
- **PermissionRequest** - Handle permission dialogs
- See `./_shared/best-practices.md` for security guidelines
