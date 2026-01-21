# Stop Hook Event

Triggers when the main Claude Code agent finishes responding, allowing you to check if work is complete, run tests, create commits, or force continuation.

## When to Use

- **Check task completion** - Verify all requested work is done
- **Run tests** - Ensure tests pass before stopping
- **Create checkpoints** - Auto-commit changes
- **Validate changes** - Check build succeeds, no linting errors
- **Generate summaries** - Create work logs, update docs
- **Force continuation** - Keep Claude working until specific conditions met

## Hook Configuration

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-completion.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

**Note:** Stop hooks **do not use matchers**.

## Input Schema

```json
{
  "session_id": "abc123",
  "hook_event_name": "Stop",
  "cwd": "/path/to/project",
  "stop_hook_active": false
}
```

| Field | Type | Description |
|-------|------|-------------|
| `stop_hook_active` | boolean | `true` if Claude already continuing due to previous stop hook |

## ⚠️ CRITICAL: Prevent Infinite Loops

**ALWAYS check `stop_hook_active` first:**

```python
import json
import sys

input_data = json.load(sys.stdin)

# Prevent infinite loops
if input_data.get("stop_hook_active"):
    sys.exit(0)  # Already continuing, don't loop

# Your stop logic here
```

Without this check, your hook can cause infinite loops!

## Decision Control

### Exit Codes

**Exit 0** - Allow stop:
```python
sys.exit(0)  # Claude stops normally
```

**Exit 2** - Block stop (force continuation):
```python
print("Tests are failing. Please fix before stopping.", file=sys.stderr)
sys.exit(2)  # Claude continues, sees stderr message
```

### JSON Output

```json
{
  "decision": "block",
  "reason": "Tests failing:\n- test_user_login: FAILED\n- test_checkout: FAILED\n\nPlease fix these tests before stopping."
}
```

Claude receives the reason and continues working to address it.

## Common Use Cases

### 1. Run Tests Before Stop

**Goal:** Don't allow stop if tests are failing.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)

# Prevent infinite loops
if input_data.get("stop_hook_active"):
    sys.exit(0)

os.chdir(os.environ['CLAUDE_PROJECT_DIR'])

# Run tests
result = subprocess.run(
    ['npm', 'test'],
    capture_output=True,
    text=True
)

if result.returncode != 0:
    output = {
        "decision": "block",
        "reason": f"Tests are failing. Please fix them:\n\n{result.stdout[-500:]}"
    }
    print(json.dumps(output))
    sys.exit(0)

# Tests pass, allow stop
sys.exit(0)
```

### 2. Auto-Commit on Stop

**Goal:** Create a checkpoint commit when work is done.

```bash
#!/bin/bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

# Read input
input=$(cat)
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')

# Prevent infinite loops
if [ "$stop_hook_active" = "true" ]; then
    exit 0
fi

# Check if there are changes
if ! git diff --quiet || ! git diff --staged --quiet; then
    # Create checkpoint commit
    git add -A
    git commit -m "checkpoint: $(date +%Y-%m-%d_%H:%M:%S)" || true

    echo "Created checkpoint commit"
fi

exit 0
```

### 3. Check Build Success

**Goal:** Ensure build succeeds before stopping.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)

if input_data.get("stop_hook_active"):
    sys.exit(0)

os.chdir(os.environ['CLAUDE_PROJECT_DIR'])

# Run build
result = subprocess.run(
    ['npm', 'run', 'build'],
    capture_output=True,
    text=True
)

if result.returncode != 0:
    output = {
        "decision": "block",
        "reason": f"Build failed:\n{result.stderr[:500]}\n\nPlease fix build errors."
    }
    print(json.dumps(output))
    sys.exit(0)

sys.exit(0)
```

### 4. Validate Todo List Complete

**Goal:** Check all todos are done before stopping.

```python
#!/usr/bin/env python3
import json
import sys
import os

input_data = json.load(sys.stdin)

if input_data.get("stop_hook_active"):
    sys.exit(0)

# Read transcript to check for todos
transcript_path = input_data.get("transcript_path", "")
if not transcript_path or not os.path.exists(transcript_path):
    sys.exit(0)

# Parse transcript for incomplete todos
incomplete_todos = []
with open(transcript_path, 'r') as f:
    for line in f:
        try:
            msg = json.loads(line)
            # Look for TodoWrite tool calls with pending todos
            # (simplified - real implementation would be more complex)
        except:
            continue

if incomplete_todos:
    output = {
        "decision": "block",
        "reason": f"You have {len(incomplete_todos)} incomplete todos. Please finish them."
    }
    print(json.dumps(output))
    sys.exit(0)

sys.exit(0)
```

### 5. Intelligent Completion Check (Prompt-based)

**Goal:** Use LLM to evaluate if work is truly complete.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if Claude should stop working. Context: $ARGUMENTS\n\nCheck if:\n1. All user-requested tasks appear complete\n2. No errors or warnings need addressing\n3. Tests are passing (if applicable)\n4. Code is properly formatted and linted\n\nRespond with JSON:\n{\n  \"decision\": \"approve\" or \"block\",\n  \"reason\": \"detailed explanation\"\n}",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### 6. Generate Work Summary

**Goal:** Create summary of changes when stopping.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os
from datetime import datetime

input_data = json.load(sys.stdin)

if input_data.get("stop_hook_active"):
    sys.exit(0)

os.chdir(os.environ['CLAUDE_PROJECT_DIR'])

# Get changes since session started
session_start = datetime.now().strftime('%Y-%m-%d')

result = subprocess.run(
    ['git', 'diff', '--stat', 'HEAD~1..HEAD'],
    capture_output=True,
    text=True
)

if result.stdout.strip():
    summary_file = f".claude/summaries/{session_start}.md"
    os.makedirs(os.path.dirname(summary_file), exist_ok=True)

    with open(summary_file, 'a') as f:
        f.write(f"\n## Session {datetime.now().strftime('%H:%M:%S')}\n")
        f.write(result.stdout)

    print(f"Work summary saved to {summary_file}")

sys.exit(0)
```

### 7. Check Uncommitted Changes

**Goal:** Warn if stopping with uncommitted changes.

```bash
#!/bin/bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

input=$(cat)
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')

if [ "$stop_hook_active" = "true" ]; then
    exit 0
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --staged --quiet; then
    # Create JSON output
    cat <<'EOF'
{
  "decision": "block",
  "reason": "You have uncommitted changes. Would you like to create a commit before stopping?"
}
EOF
    exit 0
fi

exit 0
```

### 8. Conditional Stop Based on File Changes

**Goal:** If certain files changed, require tests.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)

if input_data.get("stop_hook_active"):
    sys.exit(0)

os.chdir(os.environ['CLAUDE_PROJECT_DIR'])

# Check what files changed
result = subprocess.run(
    ['git', 'diff', '--name-only', 'HEAD'],
    capture_output=True,
    text=True
)

changed_files = result.stdout.strip().split('\n')

# If source files changed, require tests
source_changed = any(
    f.startswith('src/') and f.endswith(('.ts', '.tsx', '.js', '.jsx'))
    for f in changed_files
)

if source_changed:
    # Run tests
    test_result = subprocess.run(['npm', 'test'], capture_output=True)
    if test_result.returncode != 0:
        output = {
            "decision": "block",
            "reason": "Source files changed but tests are failing. Please fix."
        }
        print(json.dumps(output))
        sys.exit(0)

sys.exit(0)
```

## Prompt Hook Pattern

For complex completion evaluation, use LLM:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Review the conversation and determine if Claude has completed all requested tasks.\n\nContext: $ARGUMENTS\n\nConsider:\n- Are all explicit requests completed?\n- Are there any error states?\n- Is the work production-ready?\n- Are tests passing?\n\nIf work is incomplete, respond:\n{\n  \"decision\": \"block\",\n  \"reason\": \"Specific tasks still needed...\"\n}\n\nIf complete, respond:\n{\n  \"decision\": \"approve\",\n  \"reason\": \"All tasks completed successfully\"\n}",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Best Practices

### 1. ALWAYS Check stop_hook_active

```python
# This is MANDATORY
if input_data.get("stop_hook_active"):
    sys.exit(0)
```

### 2. Be Specific in Block Reasons

```python
# Bad
output = {"decision": "block", "reason": "Not done"}

# Good
output = {
    "decision": "block",
    "reason": "Tests failing:\n- test_login: FAILED\n- test_checkout: FAILED\n\nPlease fix these 2 tests."
}
```

### 3. Don't Block for Warnings

```python
# Allow stop for non-critical issues
if lint_warnings:
    print(f"Note: {len(lint_warnings)} linting warnings", file=sys.stderr)
    sys.exit(0)  # Allow stop anyway
```

### 4. Handle Long-Running Checks

```python
# Use reasonable timeouts for test/build checks
result = subprocess.run(
    ['npm', 'test'],
    capture_output=True,
    timeout=120  # 2 minute timeout
)
```

### 5. Graceful Degradation

```python
# Don't block if checks can't run
try:
    result = subprocess.run(['npm', 'test'], capture_output=True)
except FileNotFoundError:
    # npm not installed, can't check
    sys.exit(0)
```

## Testing

```bash
# Test with stop_hook_active=false
echo '{
  "hook_event_name": "Stop",
  "stop_hook_active": false
}' | .claude/hooks/check-stop.py

# Test with stop_hook_active=true (should always pass)
echo '{
  "hook_event_name": "Stop",
  "stop_hook_active": true
}' | .claude/hooks/check-stop.py

# Check exit code
echo $?
```

## Complete Example

```python
#!/usr/bin/env python3
"""Stop hook: Validate completion before stopping"""

import json
import sys
import subprocess
import os

def run_tests() -> tuple[bool, str]:
    """Run tests and return (success, output)"""
    try:
        result = subprocess.run(
            ['npm', 'test'],
            capture_output=True,
            text=True,
            timeout=120,
            cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.')
        )
        return result.returncode == 0, result.stdout
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return True, ""  # Can't run tests, allow stop

def check_uncommitted_changes() -> bool:
    """Check if there are uncommitted changes"""
    try:
        result = subprocess.run(
            ['git', 'diff', '--quiet'],
            cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.')
        )
        return result.returncode != 0
    except:
        return False

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    # CRITICAL: Prevent infinite loops
    if input_data.get("stop_hook_active"):
        sys.exit(0)

    reasons_to_continue = []

    # Check tests
    tests_pass, test_output = run_tests()
    if not tests_pass:
        reasons_to_continue.append(
            f"Tests are failing:\n{test_output[-500:]}"
        )

    # Check uncommitted changes
    if check_uncommitted_changes():
        reasons_to_continue.append(
            "You have uncommitted changes. Consider creating a commit."
        )

    # If issues found, block stop
    if reasons_to_continue:
        output = {
            "decision": "block",
            "reason": "\n\n".join(reasons_to_continue)
        }
        print(json.dumps(output))
        sys.exit(0)

    # All checks pass, allow stop
    sys.exit(0)

if __name__ == "__main__":
    main()
```

## Troubleshooting

**Infinite loop:**
- Verify `stop_hook_active` check at top of script
- Test: `echo '{"stop_hook_active":true}' | ./hook.py; echo $?` should exit 0

**Hook not blocking:**
- Check exit code is 0 when outputting JSON
- Verify `decision: "block"` in JSON
- Test manually with sample input

**Tests timeout:**
- Increase timeout in subprocess.run()
- Or increase hook timeout in config
- Consider running async

**False positives:**
- Make checks more specific
- Handle edge cases (no tests, no git, etc.)
- Allow stop when checks unavailable

## Related

- **SubagentStop** - Similar but for subagents
- **SessionEnd** - Cleanup when session ends
- See `./_shared/best-practices.md` for infinite loop prevention
- See `./examples/testing.md` for test validation patterns
