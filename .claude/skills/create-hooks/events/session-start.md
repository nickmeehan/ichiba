# SessionStart Hook Event

Triggers when Claude Code session starts or resumes, allowing you to load context, setup environment, install dependencies, or inject initial information.

## When to Use

- **Load git context** - Inject current branch, recent commits
- **Setup environment** - Export environment variables, load .env files
- **Install dependencies** - Run npm install, pip install, etc.
- **Check system state** - Verify tools installed, services running
- **Inject project context** - Load issue tracking, docs, recent changes
- **Initialize development environment** - Start services, databases

## Hook Configuration

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/init-session.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

## Matchers

SessionStart hooks can filter by **source**:

| Matcher | When Triggered |
|---------|----------------|
| `"startup"` | Fresh session start |
| `"resume"` | From `--resume`, `--continue`, or `/resume` |
| `"clear"` | From `/clear` command |
| `"compact"` | After compaction (auto or manual) |
| `""` or omit | All session starts (most common) |

## Input Schema

```json
{
  "session_id": "abc123",
  "hook_event_name": "SessionStart",
  "cwd": "/path/to/project",
  "source": "startup"
}
```

| Field | Type | Values |
|-------|------|--------|
| `source` | string | `"startup"`, `"resume"`, `"clear"`, `"compact"` |

## Decision Control

### Exit Codes

**Exit 0** - stdout is **added to Claude's context**:
```bash
#!/bin/bash
echo "Current branch: $(git branch --show-current)"
echo "Recent commits:"
git log --oneline -5
exit 0
```

Claude sees this output and can reference it.

### JSON Output

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Current branch: main\nRecent commits:\n- abc123: Fix bug\n- def456: Add feature"
  }
}
```

## Environment Variable Persistence

**UNIQUE TO SessionStart:** Access to `$CLAUDE_ENV_FILE`

```bash
#!/bin/bash

if [ -n "$CLAUDE_ENV_FILE" ]; then
    # Export variables that persist for the session
    echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
    echo 'export API_URL=http://localhost:3000' >> "$CLAUDE_ENV_FILE"
    echo 'export DEBUG=app:*' >> "$CLAUDE_ENV_FILE"
fi

exit 0
```

Variables exported to `$CLAUDE_ENV_FILE` are available to all subsequent tool calls in the session.

## Common Use Cases

### 1. Load Git Context

**Goal:** Inject current branch, recent commits, and status.

```bash
#!/bin/bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

echo "=== Git Context ==="
echo "Branch: $(git branch --show-current)"
echo ""
echo "Status:"
git status --short
echo ""
echo "Recent commits:"
git log --oneline -5
echo ""
echo "Uncommitted changes:"
git diff --stat

exit 0
```

Claude receives all this context automatically.

### 2. Setup Development Environment

**Goal:** Load .env, set NODE_ENV, configure paths.

```bash
#!/bin/bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

if [ -n "$CLAUDE_ENV_FILE" ]; then
    # Load .env file if exists
    if [ -f .env ]; then
        # Parse .env and export to session
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue

            # Export to session
            echo "export $key='$value'" >> "$CLAUDE_ENV_FILE"
        done < .env
    fi

    # Set development mode
    echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"

    # Add node_modules to PATH
    echo 'export PATH="$CLAUDE_PROJECT_DIR/node_modules/.bin:$PATH"' >> "$CLAUDE_ENV_FILE"
fi

echo "Development environment configured"
exit 0
```

### 3. Install Dependencies (First Startup Only)

**Goal:** Run npm/pip install on fresh sessions.

```bash
#!/bin/bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

# Read the source
input=$(cat)
source=$(echo "$input" | jq -r '.source // ""')

# Only on fresh startup
if [ "$source" = "startup" ]; then
    if [ -f package.json ] && [ ! -d node_modules ]; then
        echo "Installing npm dependencies..."
        npm install
    fi

    if [ -f requirements.txt ] && [ ! -d venv ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
    fi

    echo "Dependencies installed"
fi

exit 0
```

### 4. Load Issue/Task Context

**Goal:** Show current issues, tasks, or project status.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

os.chdir(os.environ['CLAUDE_PROJECT_DIR'])

# Get assigned issues from GitHub
result = subprocess.run(
    ['gh', 'issue', 'list', '--assignee', '@me', '--limit', 5, '--json', 'number,title'],
    capture_output=True,
    text=True
)

if result.returncode == 0:
    issues = json.loads(result.stdout)
    if issues:
        print("=== Your Assigned Issues ===")
        for issue in issues:
            print(f"#{issue['number']}: {issue['title']}")
        print()

sys.exit(0)
```

### 5. Check System Dependencies

**Goal:** Verify required tools are installed.

```python
#!/usr/bin/env python3
import sys
import subprocess
import shutil

required_tools = {
    'node': 'Node.js',
    'npm': 'npm',
    'git': 'Git',
    'docker': 'Docker'
}

missing = []
for command, name in required_tools.items():
    if not shutil.which(command):
        missing.append(name)

if missing:
    print(f"⚠️  Missing tools: {', '.join(missing)}", file=sys.stderr)
    print("Please install before proceeding.", file=sys.stderr)
    sys.exit(1)

print("✓ All required tools installed")
sys.exit(0)
```

### 6. Load nvm/Version Managers

**Goal:** Activate correct Node.js version.

```bash
#!/bin/bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

if [ -n "$CLAUDE_ENV_FILE" ]; then
    # Load nvm
    if [ -f "$HOME/.nvm/nvm.sh" ]; then
        source "$HOME/.nvm/nvm.sh"

        # Use project Node version
        if [ -f .nvmrc ]; then
            nvm use
        fi

        # Capture environment changes
        export -p | grep -E 'PATH|NODE|NVM' >> "$CLAUDE_ENV_FILE"
    fi
fi

echo "Node version: $(node --version)"
exit 0
```

### 7. Start Development Services

**Goal:** Start database, Redis, etc. on session start.

```bash
#!/bin/bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

# Start services via Docker Compose
if [ -f docker-compose.yml ]; then
    # Check if services already running
    if ! docker-compose ps | grep -q "Up"; then
        echo "Starting development services..."
        docker-compose up -d

        # Wait for services to be ready
        sleep 3

        echo "✓ Services started"
    else
        echo "✓ Services already running"
    fi
fi

exit 0
```

### 8. Load Recent Work Summary

**Goal:** Summarize recent changes since last session.

```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os
from datetime import datetime, timedelta

os.chdir(os.environ['CLAUDE_PROJECT_DIR'])

# Get commits from last 24 hours
since = datetime.now() - timedelta(days=1)
since_str = since.strftime('%Y-%m-%d')

result = subprocess.run(
    ['git', 'log', '--since', since_str, '--oneline', '--author', 'Claude'],
    capture_output=True,
    text=True
)

if result.stdout.strip():
    print("=== Recent Work (Last 24h) ===")
    print(result.stdout)

# Get changed files
result = subprocess.run(
    ['git', 'diff', '--name-only', 'HEAD~5..HEAD'],
    capture_output=True,
    text=True
)

if result.stdout.strip():
    print("=== Recently Modified Files ===")
    for line in result.stdout.strip().split('\n')[:10]:
        print(f"  - {line}")

sys.exit(0)
```

## Advanced Patterns

### Conditional Context Loading

```bash
#!/bin/bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

input=$(cat)
source=$(echo "$input" | jq -r '.source // ""')

case "$source" in
    startup)
        # Full context on fresh start
        echo "=== Full Project Context ==="
        git status
        git log --oneline -10
        ;;
    resume)
        # Minimal context on resume
        echo "Resumed session in: $(pwd)"
        ;;
    clear)
        # Context after clear
        echo "Session cleared, reloading context..."
        git status --short
        ;;
esac

exit 0
```

### Project Type Detection

```python
#!/usr/bin/env python3
import os
import sys

project_dir = os.environ['CLAUDE_PROJECT_DIR']
os.chdir(project_dir)

# Detect project type
project_type = "Unknown"
if os.path.exists('package.json'):
    project_type = "Node.js/TypeScript"
elif os.path.exists('requirements.txt'):
    project_type = "Python"
elif os.path.exists('Cargo.toml'):
    project_type = "Rust"
elif os.path.exists('go.mod'):
    project_type = "Go"

print(f"Project type: {project_type}")
print(f"Project directory: {project_dir}")

sys.exit(0)
```

### Load Environment from Multiple Sources

```bash
#!/bin/bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

if [ -n "$CLAUDE_ENV_FILE" ]; then
    # Load .env
    [ -f .env ] && grep -v '^#' .env | xargs -I {} echo "export {}" >> "$CLAUDE_ENV_FILE"

    # Load .env.local if exists
    [ -f .env.local ] && grep -v '^#' .env.local | xargs -I {} echo "export {}" >> "$CLAUDE_ENV_FILE"

    # Set additional vars
    echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
fi

exit 0
```

## Best Practices

### 1. Keep Output Concise
```python
# Don't dump entire files
print("Recent commits:")
print(subprocess.check_output(['git', 'log', '--oneline', '-5'], text=True))

# Not entire git log
```

### 2. Handle Missing Tools Gracefully
```bash
if command -v git &> /dev/null; then
    git status
else
    echo "Git not available"
fi
```

### 3. Use Timeouts for Slow Operations
```json
{
  "type": "command",
  "command": "./install-deps.sh",
  "timeout": 300  // 5 minutes for installs
}
```

### 4. Differentiate by Source
```bash
input=$(cat)
source=$(echo "$input" | jq -r '.source // ""')

if [ "$source" = "startup" ]; then
    # Heavy initialization only on startup
    npm install
fi
```

### 5. Persist Env Vars Properly
```bash
# Good: Use CLAUDE_ENV_FILE
echo 'export VAR=value' >> "$CLAUDE_ENV_FILE"

# Bad: Regular export (won't persist to tools)
export VAR=value
```

## Testing

```bash
# Create test input
cat > /tmp/test-session-start.json <<'EOF'
{
  "session_id": "test123",
  "hook_event_name": "SessionStart",
  "cwd": "/path/to/project",
  "source": "startup"
}
EOF

# Test hook
cat /tmp/test-session-start.json | .claude/hooks/init-session.sh

# Check output (should be context for Claude)
cat /tmp/test-session-start.json | .claude/hooks/init-session.sh 2>&1
```

## Complete Example

```bash
#!/bin/bash
"""SessionStart: Load git context and setup environment"""
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR"

# Read input
input=$(cat)
source=$(echo "$input" | jq -r '.source // ""')

echo "=== Session Starting ($source) ==="
echo ""

# Load git context
if command -v git &> /dev/null && [ -d .git ]; then
    echo "Repository: $(basename "$CLAUDE_PROJECT_DIR")"
    echo "Branch: $(git branch --show-current)"
    echo ""

    echo "Status:"
    git status --short
    echo ""

    echo "Recent commits:"
    git log --oneline -5
    echo ""
fi

# Setup environment (only if CLAUDE_ENV_FILE available)
if [ -n "$CLAUDE_ENV_FILE" ]; then
    # Load .env if exists
    if [ -f .env ]; then
        grep -v '^#' .env | grep -v '^$' | xargs -I {} echo "export {}" >> "$CLAUDE_ENV_FILE"
    fi

    # Set NODE_ENV
    echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"

    # Add local bin to PATH
    echo 'export PATH="./node_modules/.bin:$PATH"' >> "$CLAUDE_ENV_FILE"

    echo "✓ Environment configured"
fi

# On fresh startup, check dependencies
if [ "$source" = "startup" ]; then
    if [ -f package.json ] && [ ! -d node_modules ]; then
        echo ""
        echo "⚠️  Note: node_modules not found. You may want to run 'npm install'"
    fi
fi

exit 0
```

## Troubleshooting

**Context not showing:**
- Verify output goes to stdout (not stderr)
- Check exit code is 0
- Test manually: `echo '{"source":"startup"}' | ./hook.sh`

**Environment vars not persisting:**
- Ensure using `$CLAUDE_ENV_FILE`
- Check file is writable: `[ -w "$CLAUDE_ENV_FILE" ]`
- Verify exports have correct syntax: `export KEY=value`

**Hook too slow:**
- Increase timeout in config
- Move slow operations (npm install) to background
- Only run heavy tasks on `source=startup`

**Git commands failing:**
- Check running in project directory: `cd "$CLAUDE_PROJECT_DIR"`
- Verify .git exists: `[ -d .git ]`
- Handle errors: `git status || echo "Not a git repo"`

## Related

- **SessionEnd** - Cleanup when session ends
- **Stop** - Check completion before agent stops
- See `./_shared/best-practices.md` for environment variable tips
- See `./examples/context-injection.md` for more context loading patterns
