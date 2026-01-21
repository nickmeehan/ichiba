# Hook Configuration Validation

## Pre-Deployment Checklist

Before finalizing any hook configuration, validate:

### 1. JSON Syntax
```bash
# Validate settings file
cat .claude/settings.json | jq .

# Should output formatted JSON without errors
```

### 2. Hook Structure
```python
# Required fields
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",  # Optional for some events
        "hooks": [
          {
            "type": "command",      # Required: "command" or "prompt"
            "command": "script.sh", # Required for type: command
            "timeout": 60           # Optional: defaults to 60
          }
        ]
      }
    ]
  }
}
```

### 3. Event Names
Valid event names (case-sensitive):
- `PreToolUse`
- `PermissionRequest`
- `PostToolUse`
- `Notification`
- `UserPromptSubmit`
- `Stop`
- `SubagentStop`
- `PreCompact`
- `SessionStart`
- `SessionEnd`

### 4. Hook Types
- `"command"` - Execute shell command
- `"prompt"` - LLM evaluation

### 5. Matcher Patterns
Events that **require** matchers:
- `PreToolUse`
- `PermissionRequest`
- `PostToolUse`
- `Notification`
- `PreCompact`
- `SessionStart`

Events that **don't use** matchers:
- `UserPromptSubmit`
- `Stop`
- `SubagentStop`
- `SessionEnd`

### 6. File Paths
```python
# Bad: Relative paths
"command": "./hooks/script.sh"

# Good: Absolute or variable-based
"command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/script.sh"
"command": "/usr/local/bin/my-hook"
```

### 7. Script Permissions
```bash
# Make scripts executable
chmod +x .claude/hooks/my-script.sh

# Verify
ls -l .claude/hooks/my-script.sh
# Should show: -rwxr-xr-x
```

## Manual Testing

### Test Script Execution

```bash
# 1. Create test input
cat > /tmp/test-hook-input.json <<'EOF'
{
  "session_id": "test123",
  "transcript_path": "/tmp/test.jsonl",
  "cwd": "/tmp",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/tmp/test.txt",
    "content": "hello world"
  }
}
EOF

# 2. Run the hook script
cat /tmp/test-hook-input.json | .claude/hooks/my-script.py

# 3. Check exit code
echo $?
# 0 = success
# 2 = block/deny
# other = error

# 4. Check output
cat /tmp/test-hook-input.json | .claude/hooks/my-script.py 2>&1
```

### Test Different Scenarios

**Success case:**
```bash
echo '{"tool_name":"Read","tool_input":{"file_path":"README.md"}}' | python3 hook.py
echo $?  # Should be 0
```

**Block case:**
```bash
echo '{"tool_name":"Write","tool_input":{"file_path":".env"}}' | python3 hook.py
echo $?  # Should be 2
```

**Invalid input:**
```bash
echo 'invalid json' | python3 hook.py
echo $?  # Should handle gracefully
```

**Missing fields:**
```bash
echo '{}' | python3 hook.py
echo $?  # Should handle gracefully
```

## Security Validation

### Path Traversal Check
```python
def test_path_traversal():
    test_inputs = [
        "../../../etc/passwd",
        "../../.env",
        "/tmp/../../../etc/passwd",
        "normal/path/../../../secret"
    ]

    for path in test_inputs:
        result = run_hook({"tool_input": {"file_path": path}})
        assert result.exit_code == 2, f"Failed to block: {path}"
```

### Sensitive File Check
```python
def test_sensitive_files():
    sensitive = [
        ".env",
        "credentials.json",
        ".git/config",
        "private_key.pem",
        "id_rsa"
    ]

    for file in sensitive:
        result = run_hook({"tool_input": {"file_path": file}})
        assert result.exit_code == 2, f"Failed to block: {file}"
```

### Command Injection Check
```bash
# Test with malicious commands
echo '{
  "tool_input": {
    "command": "ls; rm -rf /"
  }
}' | python3 hook.py

# Hook should sanitize or reject
```

## Performance Testing

### Timeout Testing
```bash
# Set short timeout
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "sleep 5",
            "timeout": 2  # Should timeout
          }
        ]
      }
    ]
  }
}
```

### Benchmark Hook Execution
```python
import time
import subprocess

def benchmark_hook(iterations=10):
    times = []
    for _ in range(iterations):
        start = time.time()
        subprocess.run(['python3', 'hook.py'],
                      input='{"tool_name":"Write"}',
                      capture_output=True,
                      text=True)
        times.append(time.time() - start)

    avg = sum(times) / len(times)
    print(f"Average execution time: {avg:.3f}s")
    print(f"Max: {max(times):.3f}s, Min: {min(times):.3f}s")
```

## Common Validation Errors

### Error: Hook not triggering

**Check:**
1. Matcher pattern (case-sensitive!)
```json
// Wrong
"matcher": "write"

// Correct
"matcher": "Write"
```

2. Event name spelling
```json
// Wrong
"matcher": "PreTooluse"

// Correct
"matcher": "PreToolUse"
```

3. File location priority
- User settings can be overridden by project settings
- Check all config locations

### Error: Permission denied

**Fix:**
```bash
chmod +x .claude/hooks/script.sh
```

### Error: Command not found

**Fix:**
```json
// Bad: Relative path
"command": "./hooks/script.sh"

// Good: Absolute path
"command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/script.sh"
```

### Error: JSON parse error

**Fix:**
```python
# Add error handling
try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Invalid JSON: {e}", file=sys.stderr)
    sys.exit(1)
```

### Error: Hook times out

**Fix:**
```json
{
  "timeout": 120  // Increase timeout
}
```

Or optimize the script:
```python
# Bad: Slow sequential operations
for file in files:
    process(file)

# Good: Early exit
if not file_path.endswith('.ts'):
    sys.exit(0)  # Skip non-TypeScript files
```

## Integration Testing

### Test Hook Chain
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {"type": "command", "command": "hook1.sh"},
          {"type": "command", "command": "hook2.sh"}
        ]
      }
    ]
  }
}
```

Test both hooks execute:
```bash
# Enable debug mode
claude --debug

# Watch for hook execution logs
# Should see both hook1.sh and hook2.sh execute
```

### Test Multiple Matchers
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [{"command": "write-hook.sh"}]
      },
      {
        "matcher": "Edit",
        "hooks": [{"command": "edit-hook.sh"}]
      }
    ]
  }
}
```

Verify correct hook triggers for each tool.

## Validation Script

Use the provided validation script:

```bash
python3 .claude/skills/create-hooks/scripts/validate-hook-config.py \
  .claude/settings.json
```

Expected output:
```
✓ Valid JSON syntax
✓ All event names are valid
✓ All hook types are valid
✓ Matchers present where required
✓ File paths use absolute paths or variables
✓ Timeouts are reasonable (< 300s)

Configuration is valid!
```

## Pre-Commit Validation

Create a git pre-commit hook:

```bash
#!/bin/bash
# .git/hooks/pre-commit

if git diff --cached --name-only | grep -q "\.claude/settings.json"; then
    echo "Validating Claude Code hooks configuration..."

    python3 .claude/skills/create-hooks/scripts/validate-hook-config.py \
      .claude/settings.json

    if [ $? -ne 0 ]; then
        echo "Hook configuration validation failed!"
        exit 1
    fi

    echo "✓ Hook configuration is valid"
fi
```

## Debug Checklist

Hook not working as expected?

1. **Enable debug mode**
```bash
claude --debug
```

2. **Check hook execution logs**
Look for:
```
[DEBUG] Executing hooks for PostToolUse:Write
[DEBUG] Found 1 hook matchers
[DEBUG] Executing hook command: ...
```

3. **Review active hooks**
```bash
# In Claude Code session
/hooks
```

4. **Test script independently**
```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"test.txt"}}' \
  | python3 .claude/hooks/my-hook.py
```

5. **Check exit code**
```bash
echo $?
```

6. **Review stderr output**
```bash
... | python3 hook.py 2>&1
```

7. **Verify script permissions**
```bash
ls -l .claude/hooks/
```

8. **Check timeout**
```bash
# Run with time command
time echo '{}' | python3 hook.py
```

9. **Validate JSON**
```bash
cat .claude/settings.json | jq .
```

10. **Restart session**
Hook changes require session restart or `/clear`

## Validation Automation

Create a test suite:

```python
#!/usr/bin/env python3
"""Test suite for hook validation"""

import subprocess
import json

def run_hook(input_data):
    """Run hook and return exit code and output"""
    result = subprocess.run(
        ['python3', '.claude/hooks/my-hook.py'],
        input=json.dumps(input_data),
        capture_output=True,
        text=True
    )
    return result.returncode, result.stdout, result.stderr

def test_valid_input():
    code, out, err = run_hook({
        "tool_name": "Read",
        "tool_input": {"file_path": "README.md"}
    })
    assert code == 0, f"Expected 0, got {code}"

def test_sensitive_file():
    code, out, err = run_hook({
        "tool_name": "Write",
        "tool_input": {"file_path": ".env"}
    })
    assert code == 2, f"Expected 2 (block), got {code}"
    assert "sensitive" in err.lower(), "Should mention sensitive file"

def test_path_traversal():
    code, out, err = run_hook({
        "tool_name": "Write",
        "tool_input": {"file_path": "../../../etc/passwd"}
    })
    assert code == 2, f"Expected 2 (block), got {code}"

def test_invalid_json():
    result = subprocess.run(
        ['python3', '.claude/hooks/my-hook.py'],
        input="invalid json",
        capture_output=True,
        text=True
    )
    assert result.returncode != 0, "Should fail on invalid JSON"

if __name__ == '__main__':
    tests = [
        test_valid_input,
        test_sensitive_file,
        test_path_traversal,
        test_invalid_json
    ]

    for test in tests:
        try:
            test()
            print(f"✓ {test.__name__}")
        except AssertionError as e:
            print(f"✗ {test.__name__}: {e}")
```

Run tests:
```bash
python3 test_hooks.py
```

## Sign-off Checklist

Before deploying hooks to production:

- [ ] JSON syntax validated
- [ ] Event names correct (case-sensitive)
- [ ] Matchers appropriate for event type
- [ ] Hook types valid ("command" or "prompt")
- [ ] File paths absolute or use variables
- [ ] Scripts executable (`chmod +x`)
- [ ] Manually tested with sample inputs
- [ ] Security validated (paths, sensitive files)
- [ ] Performance tested (< 60s typical)
- [ ] Error handling implemented
- [ ] Logging added (if needed)
- [ ] Documentation updated
- [ ] Tested in debug mode
- [ ] Reviewed with `/hooks` command
- [ ] Team approved (if shared hooks)
- [ ] Committed to version control (if shared)
