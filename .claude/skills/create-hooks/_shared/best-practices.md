# Hook Best Practices

## Performance

### Keep Hooks Fast
- Target **60-second timeout max**
- Use efficient scripts and tools
- Avoid blocking I/O operations
- Consider async patterns for notifications
- Cache results when possible

### Optimize for Common Cases
```python
# Good: Early exit for non-matching files
if not file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
    sys.exit(0)

# Then run expensive linter only if needed
```

## Error Handling

### Graceful Degradation
```python
#!/usr/bin/env python3
import json
import sys

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

try:
    # Your logic
    pass
except Exception as e:
    # Log error but don't block
    print(f"Hook error: {e}", file=sys.stderr)
    sys.exit(1)  # Non-blocking error
```

### Validate Inputs
```python
# Always validate expected fields exist
tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})

if not tool_name:
    sys.exit(0)  # Pass through if no tool

# Validate specific fields
file_path = tool_input.get("file_path", "")
if not file_path:
    sys.exit(0)
```

## Environment Variables

### Use Built-in Variables
```bash
# Good: Use provided environment variables
"$CLAUDE_PROJECT_DIR/.claude/hooks/my-script.sh"

# Bad: Hardcoded paths
"/Users/john/project/.claude/hooks/my-script.sh"
```

### Available Variables
- `CLAUDE_PROJECT_DIR` - Absolute path to project root
- `CLAUDE_PLUGIN_ROOT` - Plugin directory (for plugin hooks)
- `CLAUDE_ENV_FILE` - File for persisting env vars (SessionStart only)
- `CLAUDE_CODE_REMOTE` - "true" if running in web environment

### Persist Environment Changes (SessionStart)
```bash
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
    echo 'export API_URL=http://localhost:3000' >> "$CLAUDE_ENV_FILE"
fi
```

## Shell Safety

### Always Quote Variables
```bash
# Bad: Breaks with spaces in paths
file_path=$1
prettier --write $file_path

# Good: Properly quoted
file_path="$1"
prettier --write "$file_path"
```

### Escape Special Characters
```bash
# Use jq for JSON parsing, not manual extraction
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
```

### Use Safe Patterns
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Your script here
```

## Preventing Infinite Loops

### Stop Hooks Must Check `stop_hook_active`
```python
#!/usr/bin/env python3
import json
import sys

input_data = json.load(sys.stdin)

# CRITICAL: Prevent infinite loops
if input_data.get("stop_hook_active"):
    sys.exit(0)  # Already continuing, don't loop

# Your stop logic here
```

### SubagentStop Hooks Too
```python
if input_data.get("stop_hook_active"):
    sys.exit(0)
```

## Logging & Debugging

### Structured Logging
```python
import logging
import os

log_path = os.path.join(
    os.environ.get('CLAUDE_PROJECT_DIR', '.'),
    '.claude/hooks.log'
)

logging.basicConfig(
    filename=log_path,
    level=logging.DEBUG,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

logging.info(f"Hook triggered for {tool_name}")
```

### Debug Output
```python
# Verbose output shown with --debug flag
print(f"[DEBUG] Processing file: {file_path}", file=sys.stderr)
```

### Test Scripts Manually
```bash
# Create sample input
echo '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "test.txt",
    "content": "hello"
  }
}' | python3 my-hook.py

# Check exit code
echo $?

# Check stderr output
echo '{...}' | python3 my-hook.py 2>&1
```

## Security

### Validate Paths
```python
import os

file_path = tool_input.get("file_path", "")

# Block path traversal
if ".." in file_path:
    print("Path traversal detected", file=sys.stderr)
    sys.exit(2)

# Block absolute paths outside project
if os.path.isabs(file_path):
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if not file_path.startswith(project_dir):
        print("Path outside project", file=sys.stderr)
        sys.exit(2)
```

### Skip Sensitive Files
```python
SENSITIVE_PATTERNS = [
    '.env',
    'credentials',
    'secrets',
    '.git/',
    'private_key',
    'id_rsa',
    '.pem'
]

file_path_lower = file_path.lower()
if any(pattern in file_path_lower for pattern in SENSITIVE_PATTERNS):
    print(f"Skipping sensitive file: {file_path}", file=sys.stderr)
    sys.exit(2)
```

### Sanitize Command Inputs
```python
# Bad: Command injection risk
command = tool_input.get("command", "")
os.system(command)  # NEVER DO THIS

# Good: Validate against allowlist
ALLOWED_COMMANDS = ['npm', 'git', 'pytest']
command = tool_input.get("command", "").split()[0]
if command not in ALLOWED_COMMANDS:
    sys.exit(2)
```

## Configuration Management

### Merge Hooks Properly
```python
import json

# Read existing config
with open(settings_file, 'r') as f:
    config = json.load(f)

# Initialize hooks if not present
if 'hooks' not in config:
    config['hooks'] = {}

if 'PostToolUse' not in config['hooks']:
    config['hooks']['PostToolUse'] = []

# Add new hook (don't overwrite existing)
config['hooks']['PostToolUse'].append({
    "matcher": "Edit|Write",
    "hooks": [new_hook]
})

# Write back
with open(settings_file, 'w') as f:
    json.dump(config, f, indent=2)
```

### Choose Right Location
- **User global** (`~/.claude/settings.json`): Cross-project preferences
- **Project shared** (`.claude/settings.json`): Team standards, committed
- **Project local** (`.claude/settings.local.json`): Personal, not committed

## Matcher Patterns

### Be Specific
```json
// Bad: Matches too much
"matcher": "*"

// Good: Specific tools
"matcher": "Edit|Write|MultiEdit"
```

### Use Regex for Related Tools
```json
// Notebook tools
"matcher": "Notebook.*"

// MCP memory tools
"matcher": "mcp__memory__.*"

// Any write operation from MCP
"matcher": "mcp__.*__write.*"
```

### Case Sensitivity
Matchers are **case-sensitive**:
```json
"matcher": "write"   // Won't match "Write"
"matcher": "Write"   // Correct
```

## Decision Control

### Use Appropriate Exit Codes
```python
# Success - hook approves
sys.exit(0)

# Block/deny - show reason to Claude
print("Reason for blocking", file=sys.stderr)
sys.exit(2)

# Non-blocking error - show to user only
print("Warning: linter unavailable", file=sys.stderr)
sys.exit(1)
```

### JSON for Complex Decisions
```python
# Auto-approve documentation files
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
```

## Testing

### Manual Testing
```bash
# 1. Create test input
cat > test-input.json <<'EOF'
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "test.txt",
    "content": "hello world"
  }
}
EOF

# 2. Run hook
cat test-input.json | python3 hooks/my-hook.py

# 3. Check exit code
echo $?

# 4. Check output
cat test-input.json | python3 hooks/my-hook.py 2>&1 | jq .
```

### Test Cases to Cover
- Valid input → exit 0
- Invalid input → graceful error
- Missing fields → safe default
- Edge cases (empty strings, null values)
- Sensitive file paths → exit 2
- Path traversal attempts → exit 2

## Common Patterns

### Filter by File Extension
```python
def should_process(file_path: str, extensions: list) -> bool:
    return any(file_path.endswith(ext) for ext in extensions)

if not should_process(file_path, ['.ts', '.tsx', '.js', '.jsx']):
    sys.exit(0)
```

### Conditional Execution
```python
# Only run in certain environments
if os.environ.get('CLAUDE_CODE_REMOTE') == 'true':
    sys.exit(0)  # Skip in web environment

# Only run for specific branches
branch = subprocess.check_output(
    ['git', 'branch', '--show-current'],
    text=True
).strip()

if branch == 'main':
    # Extra strict validation on main
    pass
```

### Parallel Hook Execution
Multiple hooks for same event run in **parallel**:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {"type": "command", "command": "prettier"},
          {"type": "command", "command": "eslint"}
        ]
      }
    ]
  }
}
```
Both prettier and eslint run simultaneously.

## Documentation

### Comment Your Hooks
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "./hooks/format.sh",
            "timeout": 60,
            "_description": "Auto-format TypeScript/JavaScript files with Prettier"
          }
        ]
      }
    ]
  }
}
```

### Add README
Create `.claude/hooks/README.md`:
```markdown
# Project Hooks

## Auto-formatting (PostToolUse)
Runs Prettier on all TypeScript/JavaScript edits.

## Git context (SessionStart)
Injects current branch and recent commits at session start.

## Security validation (PreToolUse)
Blocks modifications to .env and credentials files.
```

## Maintenance

### Review Hook Changes
Use `/hooks` command to review active hooks before applying changes.

### Version Control
```bash
# Commit shared hooks
git add .claude/settings.json
git commit -m "Add auto-formatting hook"

# Ignore personal hooks
echo '.claude/settings.local.json' >> .gitignore
```

### Monitor Performance
```python
import time

start = time.time()
# Your hook logic
duration = time.time() - start

if duration > 5:
    logging.warning(f"Slow hook execution: {duration:.2f}s")
```

## Summary Checklist

Before deploying a hook:
- [ ] Script is executable (`chmod +x`)
- [ ] Uses absolute or `$CLAUDE_PROJECT_DIR` paths
- [ ] Validates JSON input gracefully
- [ ] Quotes all shell variables
- [ ] Handles missing fields safely
- [ ] Validates file paths (no traversal)
- [ ] Skips sensitive files appropriately
- [ ] Checks `stop_hook_active` for Stop hooks
- [ ] Has reasonable timeout (< 60s)
- [ ] Tested manually with sample input
- [ ] Logged/documented purpose
- [ ] Security reviewed
- [ ] Won't block critical operations accidentally
