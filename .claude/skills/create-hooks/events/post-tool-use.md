# PostToolUse Hook Event

Triggers **after** a tool executes successfully, allowing you to format code, run linters, provide feedback, or log operations.

## When to Use

- **Auto-format code** - Run prettier, black, gofmt after edits
- **Run linters** - Check code quality after changes
- **Provide feedback** - Suggest improvements
- **Log operations** - Track what was changed
- **Trigger builds** - Recompile after source changes
- **Update dependencies** - Regenerate lockfiles

## Hook Configuration

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "path/to/formatter.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

## Input Schema

```json
{
  "session_id": "abc123",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "content that was written"
  },
  "tool_response": {
    "filePath": "/path/to/file.txt",
    "success": true
  },
  "tool_use_id": "toolu_01ABC"
}
```

## Decision Control

### Exit Codes

**Exit 0** - Success, operation completed:
```python
sys.exit(0)  # Continue normally
```

**Exit 2** - Block with feedback:
```python
print("Linting errors found:\n" + errors, file=sys.stderr)
sys.exit(2)  # Claude receives stderr as feedback
```

**Note:** Tool already executed! Exit 2 provides feedback but doesn't undo the operation.

### JSON Output

```json
{
  "decision": "block",
  "reason": "Linting errors found in file",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "ESLint found 3 errors:\n- Line 10: Missing semicolon\n..."
  }
}
```

## Common Use Cases

### 1. Auto-Format TypeScript/JavaScript

```bash
#!/bin/bash
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Only format TS/JS files
if [[ "$file_path" =~ \.(ts|tsx|js|jsx)$ ]]; then
    npx prettier --write "$file_path" 2>&1
fi

exit 0
```

**Configuration:**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/format-ts.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### 2. Run Linter and Block on Errors

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")

# Only lint TypeScript/JavaScript
if not file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
    sys.exit(0)

# Run ESLint
result = subprocess.run(
    ['npx', 'eslint', file_path, '--format', 'compact'],
    capture_output=True,
    text=True,
    cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.')
)

if result.returncode != 0:
    print(f"ESLint errors in {file_path}:\n{result.stdout}", file=sys.stderr)
    sys.exit(2)  # Block and show errors to Claude

sys.exit(0)
```

### 3. Format Python with Black

```python
#!/usr/bin/env python3
import json
import sys
import subprocess

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")

# Only format Python files
if not file_path.endswith('.py'):
    sys.exit(0)

# Run black
result = subprocess.run(
    ['black', file_path],
    capture_output=True,
    text=True
)

if result.returncode != 0:
    print(f"Black formatting failed: {result.stderr}", file=sys.stderr)
    sys.exit(1)  # Non-blocking error

sys.exit(0)
```

### 4. Multi-Language Formatter

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")

if not file_path:
    sys.exit(0)

cwd = os.environ.get('CLAUDE_PROJECT_DIR', '.')

# Format based on extension
if file_path.endswith(('.ts', '.tsx', '.js', '.jsx', '.json', '.css')):
    subprocess.run(['npx', 'prettier', '--write', file_path], cwd=cwd)
elif file_path.endswith('.py'):
    subprocess.run(['black', file_path], cwd=cwd)
elif file_path.endswith('.go'):
    subprocess.run(['gofmt', '-w', file_path], cwd=cwd)
elif file_path.endswith('.rs'):
    subprocess.run(['rustfmt', file_path], cwd=cwd)

sys.exit(0)
```

### 5. Log File Changes

```bash
#!/bin/bash
set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log to file
log_file="$CLAUDE_PROJECT_DIR/.claude/file-changes.log"
echo "$timestamp - $tool_name - $file_path" >> "$log_file"

exit 0
```

### 6. Regenerate Type Definitions

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")

# If schema file changed, regenerate types
if 'schema' in file_path and file_path.endswith('.graphql'):
    cwd = os.environ.get('CLAUDE_PROJECT_DIR', '.')
    subprocess.run(
        ['npm', 'run', 'generate:types'],
        cwd=cwd,
        capture_output=True
    )

sys.exit(0)
```

### 7. Run Tests After Changes

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")

# Run tests for modified file
if file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
    # Find corresponding test file
    test_file = file_path.replace('/src/', '/tests/').replace('.ts', '.test.ts')

    if os.path.exists(test_file):
        result = subprocess.run(
            ['npm', 'test', test_file],
            capture_output=True,
            text=True,
            cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.')
        )

        if result.returncode != 0:
            print(f"Tests failing:\n{result.stdout}", file=sys.stderr)
            sys.exit(2)

sys.exit(0)
```

## Language-Specific Formatters

### TypeScript/JavaScript (Prettier)
```bash
if [[ "$file_path" =~ \.(ts|tsx|js|jsx)$ ]]; then
    npx prettier --write "$file_path"
fi
```

### Python (Black)
```bash
if [[ "$file_path" =~ \.py$ ]]; then
    black "$file_path"
fi
```

### Go (gofmt)
```bash
if [[ "$file_path" =~ \.go$ ]]; then
    gofmt -w "$file_path"
fi
```

### Rust (rustfmt)
```bash
if [[ "$file_path" =~ \.rs$ ]]; then
    rustfmt "$file_path"
fi
```

### C/C++ (clang-format)
```bash
if [[ "$file_path" =~ \.(c|cpp|h|hpp)$ ]]; then
    clang-format -i "$file_path"
fi
```

### Ruby (rubocop)
```bash
if [[ "$file_path" =~ \.rb$ ]]; then
    rubocop -a "$file_path"
fi
```

## Best Practices

### 1. Skip Non-Relevant Files Early
```python
# Exit early to avoid unnecessary work
if not file_path.endswith(('.ts', '.tsx')):
    sys.exit(0)
```

### 2. Handle Formatter Failures Gracefully
```python
result = subprocess.run(['prettier', '--write', file_path], capture_output=True)

if result.returncode != 0:
    # Log but don't block
    print(f"Warning: Prettier failed for {file_path}", file=sys.stderr)
    sys.exit(1)  # Non-blocking error
```

### 3. Use Timeouts
```json
{
  "type": "command",
  "command": "./format.sh",
  "timeout": 30  // Don't let formatters run forever
}
```

### 4. Check Tool Success
```python
tool_response = input_data.get("tool_response", {})
success = tool_response.get("success", False)

if not success:
    sys.exit(0)  # Tool failed, don't format
```

### 5. Run Formatters in Project Directory
```python
subprocess.run(
    ['prettier', '--write', file_path],
    cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.')
)
```

### 6. Provide Helpful Feedback
```python
if lint_errors:
    feedback = f"Found {len(lint_errors)} linting issues:\n"
    for error in lint_errors[:5]:  # Show first 5
        feedback += f"  - {error}\n"
    print(feedback, file=sys.stderr)
    sys.exit(2)
```

## Parallel Hook Execution

Multiple PostToolUse hooks run in **parallel**:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {"type": "command", "command": "./format.sh"},
          {"type": "command", "command": "./lint.sh"},
          {"type": "command", "command": "./log.sh"}
        ]
      }
    ]
  }
}
```

All three scripts execute simultaneously.

## Testing

```bash
# Create test input
cat > /tmp/test-post-tool.json <<'EOF'
{
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "src/index.ts",
    "content": "console.log('test');"
  },
  "tool_response": {
    "filePath": "src/index.ts",
    "success": true
  }
}
EOF

# Test the hook
cat /tmp/test-post-tool.json | .claude/hooks/format.sh

# Check exit code
echo $?

# Verify file was formatted
cat src/index.ts
```

## Complete Example

```python
#!/usr/bin/env python3
"""PostToolUse: Auto-format and lint edited files"""

import json
import sys
import subprocess
import os

def format_file(file_path: str, cwd: str) -> bool:
    """Format file based on extension. Returns True if successful."""

    formatters = {
        ('.ts', '.tsx', '.js', '.jsx'): ['npx', 'prettier', '--write', file_path],
        ('.py',): ['black', file_path],
        ('.go',): ['gofmt', '-w', file_path],
        ('.rs',): ['rustfmt', file_path],
    }

    for extensions, command in formatters.items():
        if file_path.endswith(extensions):
            result = subprocess.run(command, cwd=cwd, capture_output=True)
            return result.returncode == 0

    return True  # No formatter, that's okay

def lint_file(file_path: str, cwd: str) -> tuple[bool, str]:
    """Lint file if applicable. Returns (success, errors)."""

    if file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
        result = subprocess.run(
            ['npx', 'eslint', file_path, '--format', 'compact'],
            cwd=cwd,
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            return False, result.stdout

    return True, ""

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(1)

    tool_input = input_data.get("tool_input", {})
    tool_response = input_data.get("tool_response", {})
    file_path = tool_input.get("file_path", "")

    # Only process successful file operations
    if not file_path or not tool_response.get("success"):
        sys.exit(0)

    cwd = os.environ.get('CLAUDE_PROJECT_DIR', '.')

    # Format the file
    if not format_file(file_path, cwd):
        print(f"Warning: Formatting failed for {file_path}", file=sys.stderr)
        sys.exit(1)  # Non-blocking

    # Lint the file
    success, errors = lint_file(file_path, cwd)
    if not success:
        print(f"Linting errors in {file_path}:\n{errors}", file=sys.stderr)
        sys.exit(2)  # Block and show to Claude

    sys.exit(0)

if __name__ == "__main__":
    main()
```

## Troubleshooting

**Formatter not running:**
- Check file extension matching
- Verify formatter is installed (`which prettier`, `which black`)
- Check timeout (formatters may be slow)
- Review hook logs with `claude --debug`

**Tool response missing:**
- Some tools may have different response schemas
- Gracefully handle: `tool_response.get("success", True)`

**Performance issues:**
- Format only changed files, not entire codebase
- Use faster formatters or configure for speed
- Increase timeout if needed
- Run heavy operations async or in background

**Changes not persisted:**
- Ensure hook runs in project directory (`cwd=...`)
- Check file permissions
- Verify formatter modifies files in-place (`-w`, `--write` flags)

## Related

- **PreToolUse** - Validate before execution
- See `./_shared/best-practices.md` for optimization tips
- See `./examples/auto-format.md` for more formatting examples
