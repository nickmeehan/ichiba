# Auto-Formatting Examples

Comprehensive examples for automatically formatting code after edits.

## Universal Multi-Language Formatter

Formats files based on extension using appropriate tools.

**Script:** `.claude/hooks/auto-format.sh`

```bash
#!/bin/bash
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Skip if no file path
if [ -z "$file_path" ]; then
    exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# Format based on extension
case "$file_path" in
    *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.html|*.md)
        npx prettier --write "$file_path" 2>/dev/null || true
        ;;
    *.py)
        black "$file_path" 2>/dev/null || true
        ;;
    *.go)
        gofmt -w "$file_path" 2>/dev/null || true
        ;;
    *.rs)
        rustfmt "$file_path" 2>/dev/null || true
        ;;
    *.rb)
        rubocop -a "$file_path" 2>/dev/null || true
        ;;
    *.java)
        google-java-format -i "$file_path" 2>/dev/null || true
        ;;
    *.cpp|*.cc|*.c|*.h|*.hpp)
        clang-format -i "$file_path" 2>/dev/null || true
        ;;
esac

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
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/auto-format.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## TypeScript/JavaScript with Prettier

**Python version:** `.claude/hooks/format-ts.py`

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)

file_path = input_data.get("tool_input", {}).get("file_path", "")

# Only format TS/JS files
if not file_path.endswith(('.ts', '.tsx', '.js', '.jsx', '.json')):
    sys.exit(0)

try:
    subprocess.run(
        ['npx', 'prettier', '--write', file_path],
        cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.'),
        capture_output=True,
        timeout=10
    )
except Exception:
    # Formatter failed, but don't block
    pass

sys.exit(0)
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
            "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/format-ts.py",
            "timeout": 20
          }
        ]
      }
    ]
  }
}
```

## Python with Black and isort

Format and organize imports automatically.

```python
#!/usr/bin/env python3
"""Auto-format Python files with black and isort"""
import json
import sys
import subprocess
import os

try:
    input_data = json.load(sys.stdin)
except:
    sys.exit(0)

file_path = input_data.get("tool_input", {}).get("file_path", "")

if not file_path.endswith('.py'):
    sys.exit(0)

cwd = os.environ.get('CLAUDE_PROJECT_DIR', '.')

try:
    # Sort imports
    subprocess.run(
        ['isort', file_path],
        cwd=cwd,
        capture_output=True,
        timeout=10
    )

    # Format code
    subprocess.run(
        ['black', file_path],
        cwd=cwd,
        capture_output=True,
        timeout=10
    )
except Exception:
    pass

sys.exit(0)
```

## Rust with rustfmt

```bash
#!/bin/bash
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

if [[ "$file_path" =~ \.rs$ ]]; then
    rustfmt "$file_path" 2>/dev/null || true
fi

exit 0
```

## Go with gofmt and goimports

```bash
#!/bin/bash
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

if [[ "$file_path" =~ \.go$ ]]; then
    # Format code
    gofmt -w "$file_path" 2>/dev/null || true

    # Organize imports
    goimports -w "$file_path" 2>/dev/null || true
fi

exit 0
```

## Conditional Formatting

Only format files in specific directories.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")

# Only format files in src/ and tests/
if not (file_path.startswith('src/') or file_path.startswith('tests/')):
    sys.exit(0)

if file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
    subprocess.run(
        ['npx', 'prettier', '--write', file_path],
        cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.'),
        capture_output=True
    )

sys.exit(0)
```

## Format with Configuration File

Use project-specific formatter configs.

```bash
#!/bin/bash
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

cd "$CLAUDE_PROJECT_DIR"

# Check for prettier config
if [ -f .prettierrc ] || [ -f .prettierrc.json ]; then
    if [[ "$file_path" =~ \.(ts|tsx|js|jsx|json)$ ]]; then
        npx prettier --write "$file_path"
    fi
fi

# Check for black config
if [ -f pyproject.toml ] && grep -q "tool.black" pyproject.toml; then
    if [[ "$file_path" =~ \.py$ ]]; then
        black "$file_path"
    fi
fi

exit 0
```

## Format with ESLint --fix

Auto-fix ESLint issues.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")

if not file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
    sys.exit(0)

cwd = os.environ.get('CLAUDE_PROJECT_DIR', '.')

# Run prettier first
subprocess.run(
    ['npx', 'prettier', '--write', file_path],
    cwd=cwd,
    capture_output=True
)

# Then ESLint --fix
subprocess.run(
    ['npx', 'eslint', '--fix', file_path],
    cwd=cwd,
    capture_output=True
)

sys.exit(0)
```

## Parallel Formatting and Linting

Run multiple formatters in parallel.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/format.sh",
            "timeout": 20
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/lint.sh",
            "timeout": 20
          }
        ]
      }
    ]
  }
}
```

Both run simultaneously, making it faster.

## Format Only Changed Sections

More efficient for large files.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)
tool_name = input_data.get("tool_name", "")
file_path = input_data.get("tool_input", {}).get("file_path", "")

# For Edit (not Write), only format if file is small
if tool_name == "Edit":
    try:
        size = os.path.getsize(file_path)
        if size > 100_000:  # > 100KB
            # Don't format large files on edits
            sys.exit(0)
    except:
        pass

if file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
    subprocess.run(
        ['npx', 'prettier', '--write', file_path],
        cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.'),
        capture_output=True
    )

sys.exit(0)
```

## Format with Feedback

Show when formatting made changes.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os
import hashlib

def file_hash(path):
    """Calculate file hash."""
    try:
        with open(path, 'rb') as f:
            return hashlib.md5(f.read()).hexdigest()
    except:
        return None

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")

if not file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
    sys.exit(0)

# Hash before formatting
before = file_hash(file_path)

# Format
subprocess.run(
    ['npx', 'prettier', '--write', file_path],
    cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.'),
    capture_output=True
)

# Hash after
after = file_hash(file_path)

if before != after:
    print(f"Formatted: {file_path}")

sys.exit(0)
```

## Verify Formatting (Block if Failed)

Block if formatter fails (for critical projects).

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")

if not file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
    sys.exit(0)

result = subprocess.run(
    ['npx', 'prettier', '--write', file_path],
    cwd=os.environ.get('CLAUDE_PROJECT_DIR', '.'),
    capture_output=True,
    text=True
)

if result.returncode != 0:
    print(f"Prettier failed for {file_path}:\n{result.stderr}", file=sys.stderr)
    sys.exit(2)  # Block and show error to Claude

sys.exit(0)
```

## Best Practices

1. **Graceful failures** - Use `|| true` or `capture_output=True` to not block on formatter errors
2. **File type filtering** - Exit early for non-matching files
3. **Reasonable timeouts** - 20-30 seconds for formatters
4. **Silent execution** - Redirect stderr to `/dev/null` or capture output
5. **Use project configs** - Let formatters read .prettierrc, pyproject.toml, etc.
6. **Parallel hooks** - Run multiple formatters simultaneously when possible
7. **Performance** - Skip formatting for very large files or non-src directories

## Testing

```bash
# Create test input
echo '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "src/test.ts",
    "content": "const x=1;"
  }
}' | .claude/hooks/auto-format.sh

# Check file was formatted
cat src/test.ts
# Should show: const x = 1;
```

## Installation

1. Copy script to `.claude/hooks/`
2. Make executable: `chmod +x .claude/hooks/auto-format.sh`
3. Add configuration to `.claude/settings.json` or `.claude/settings.local.json`
4. Restart Claude Code or run `/clear`
