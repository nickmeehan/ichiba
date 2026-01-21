# Security Validation Examples

Examples for blocking dangerous operations and protecting sensitive files.

## Block Sensitive Files

Prevent modifications to credentials, keys, and config files.

**Script:** `.claude/hooks/block-sensitive.py`

```python
#!/usr/bin/env python3
"""Block modifications to sensitive files"""
import json
import sys
import os

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(1)

tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path", "")

if not file_path:
    sys.exit(0)

# Sensitive file patterns
SENSITIVE_PATTERNS = [
    '.env',
    '.env.local',
    '.env.production',
    'credentials',
    'secrets',
    '.git/config',
    'private_key',
    'id_rsa',
    'id_ed25519',
    '.pem',
    '.key',
    '.crt',
    'secret.json',
    'auth.json',
    '.password',
    'token',
]

# Normalize path
file_path_lower = file_path.lower()

# Check for sensitive patterns
for pattern in SENSITIVE_PATTERNS:
    if pattern in file_path_lower:
        print(f"❌ Cannot modify sensitive file: {file_path}", file=sys.stderr)
        print(f"   Contains pattern: {pattern}", file=sys.stderr)
        sys.exit(2)

# Block specific files
BLOCKED_FILES = {
    'package-lock.json',
    'yarn.lock',
    'Cargo.lock',
    'Gemfile.lock',
    'poetry.lock',
}

basename = os.path.basename(file_path)
if basename in BLOCKED_FILES:
    print(f"❌ Cannot modify lockfile: {file_path}", file=sys.stderr)
    print("   Regenerate with package manager instead", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
```

**Configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-sensitive.py",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## Path Traversal Prevention

Block attempts to access files outside project directory.

```python
#!/usr/bin/env python3
"""Prevent path traversal attacks"""
import json
import sys
import os

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path", "")

if not file_path:
    sys.exit(0)

# Block path traversal attempts
if ".." in file_path:
    print("❌ Path traversal detected", file=sys.stderr)
    print(f"   Path contains '..': {file_path}", file=sys.stderr)
    sys.exit(2)

# Verify path is within project (if absolute path)
if os.path.isabs(file_path):
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if project_dir:
        project_dir = os.path.abspath(project_dir)
        abs_file_path = os.path.abspath(file_path)

        if not abs_file_path.startswith(project_dir):
            print("❌ Path outside project directory", file=sys.stderr)
            print(f"   Project: {project_dir}", file=sys.stderr)
            print(f"   Path: {abs_file_path}", file=sys.stderr)
            sys.exit(2)

sys.exit(0)
```

## Validate Bash Commands

Block dangerous shell commands.

```python
#!/usr/bin/env python3
"""Validate bash commands for security"""
import json
import sys
import re

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
command = tool_input.get("command", "")

if not command:
    sys.exit(0)

# Dangerous patterns
DANGEROUS_PATTERNS = [
    (r'rm\s+-rf\s+/', 'Recursive delete from root'),
    (r'dd\s+if=', 'Disk manipulation with dd'),
    (r'mkfs', 'Filesystem creation'),
    (r':\(\)\{.*\|\:&\};:', 'Fork bomb'),
    (r'chmod\s+-R\s+777', 'Overly permissive chmod'),
    (r'curl.*\|\s*bash', 'Piping curl to bash'),
    (r'wget.*\|\s*sh', 'Piping wget to shell'),
    (r'>\s*/dev/sd[a-z]', 'Writing directly to disk'),
    (r'nohup.*&.*disown', 'Background process that survives logout'),
]

for pattern, description in DANGEROUS_PATTERNS:
    if re.search(pattern, command, re.IGNORECASE):
        print(f"❌ Dangerous command blocked: {description}", file=sys.stderr)
        print(f"   Command: {command}", file=sys.stderr)
        sys.exit(2)

# Warning patterns (allow but notify)
WARNING_PATTERNS = [
    (r'sudo', 'Sudo usage'),
    (r'rm\s+-rf', 'Recursive delete'),
    (r'git\s+push\s+--force', 'Force push'),
]

for pattern, description in WARNING_PATTERNS:
    if re.search(pattern, command, re.IGNORECASE):
        print(f"⚠️  Warning: {description} in command", file=sys.stderr)
        # Don't block, just warn
        break

sys.exit(0)
```

## Whitelist Approach

Only allow specific commands (more secure).

```python
#!/usr/bin/env python3
"""Whitelist approach to bash commands"""
import json
import sys

input_data = json.load(sys.stdin)
command = input_data.get("tool_input", {}).get("command", "")

if not command:
    sys.exit(0)

# Extract base command
cmd_parts = command.split()
if not cmd_parts:
    sys.exit(0)

base_command = cmd_parts[0]

# Whitelist of allowed commands
ALLOWED_COMMANDS = {
    'git', 'npm', 'yarn', 'node', 'python', 'python3',
    'pip', 'pip3', 'cargo', 'rustc', 'go', 'mvn',
    'gradle', 'make', 'cmake', 'docker', 'docker-compose',
    'kubectl', 'ls', 'cat', 'grep', 'find', 'echo',
    'test', 'pytest', 'jest', 'tsc', 'eslint',
}

if base_command not in ALLOWED_COMMANDS:
    print(f"❌ Command not in whitelist: {base_command}", file=sys.stderr)
    print(f"   Allowed: {', '.join(sorted(ALLOWED_COMMANDS))}", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
```

## Protect Production Branch

Block direct commits/pushes to main/master.

```python
#!/usr/bin/env python3
"""Protect production branches"""
import json
import sys
import subprocess
import os
import re

input_data = json.load(sys.stdin)
command = input_data.get("tool_input", {}).get("command", "")

if not command:
    sys.exit(0)

# Check if this is a git push or commit to protected branch
if not re.search(r'git\s+(push|commit)', command):
    sys.exit(0)

try:
    os.chdir(os.environ.get('CLAUDE_PROJECT_DIR', '.'))

    # Get current branch
    result = subprocess.run(
        ['git', 'branch', '--show-current'],
        capture_output=True,
        text=True
    )

    branch = result.stdout.strip()

    # Protected branches
    PROTECTED_BRANCHES = {'main', 'master', 'production'}

    if branch in PROTECTED_BRANCHES:
        print(f"❌ Cannot push/commit directly to {branch}", file=sys.stderr)
        print("   Create a feature branch instead", file=sys.stderr)
        sys.exit(2)

except Exception:
    pass

sys.exit(0)
```

## Block File Size Limits

Prevent committing large files.

```python
#!/usr/bin/env python3
"""Block large files"""
import json
import sys
import os

input_data = json.load(sys.stdin)
file_path = input_data.get("tool_input", {}).get("file_path", "")
content = input_data.get("tool_input", {}).get("content", "")

if not file_path:
    sys.exit(0)

# Check content size (for Write)
if content:
    size_mb = len(content) / (1024 * 1024)
    if size_mb > 10:  # 10MB limit
        print(f"❌ File content too large: {size_mb:.1f}MB", file=sys.stderr)
        print("   Maximum: 10MB", file=sys.stderr)
        sys.exit(2)

# Check existing file size (for Edit)
if os.path.exists(file_path):
    size_mb = os.path.getsize(file_path) / (1024 * 1024)
    if size_mb > 10:
        print(f"❌ File too large to edit: {size_mb:.1f}MB", file=sys.stderr)
        print("   Maximum: 10MB", file=sys.stderr)
        sys.exit(2)

sys.exit(0)
```

## Scan for Secrets

Detect hardcoded secrets in code.

```python
#!/usr/bin/env python3
"""Detect hardcoded secrets"""
import json
import sys
import re

input_data = json.load(sys.stdin)
content = input_data.get("tool_input", {}).get("content", "")
file_path = input_data.get("tool_input", {}).get("file_path", "")

if not content:
    sys.exit(0)

# Secret patterns
SECRET_PATTERNS = [
    (r'(?i)password\s*=\s*["\'][^"\']{8,}["\']', 'Hardcoded password'),
    (r'(?i)api[_-]?key\s*=\s*["\'][^"\']{20,}["\']', 'API key'),
    (r'(?i)secret\s*=\s*["\'][^"\']{20,}["\']', 'Secret token'),
    (r'(?i)token\s*=\s*["\'][^"\']{20,}["\']', 'Token'),
    (r'(?:sk|pk)_live_[a-zA-Z0-9]{20,}', 'Stripe live key'),
    (r'AIza[0-9A-Za-z-_]{35}', 'Google API key'),
    (r'AKIA[0-9A-Z]{16}', 'AWS access key'),
    (r'github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}', 'GitHub personal access token'),
]

findings = []
for pattern, description in SECRET_PATTERNS:
    if re.search(pattern, content):
        findings.append(description)

if findings:
    print(f"❌ Potential secrets detected in {file_path}:", file=sys.stderr)
    for finding in findings:
        print(f"   - {finding}", file=sys.stderr)
    print("\nMove secrets to environment variables or .env file", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
```

## Rate Limiting

Prevent too many operations in short time.

```python
#!/usr/bin/env python3
"""Rate limit hook executions"""
import json
import sys
import os
import time

# State file for rate limiting
STATE_FILE = os.path.join(
    os.environ.get('CLAUDE_PROJECT_DIR', '.'),
    '.claude/hook-state.json'
)

input_data = json.load(sys.stdin)

# Load state
try:
    with open(STATE_FILE, 'r') as f:
        state = json.load(f)
except:
    state = {"timestamps": []}

# Add current timestamp
now = time.time()
state["timestamps"].append(now)

# Keep only last minute
state["timestamps"] = [
    ts for ts in state["timestamps"]
    if now - ts < 60
]

# Check rate limit
if len(state["timestamps"]) > 100:  # 100 operations per minute
    print("❌ Rate limit exceeded: too many operations", file=sys.stderr)
    sys.exit(2)

# Save state
os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
with open(STATE_FILE, 'w') as f:
    json.dump(state, f)

sys.exit(0)
```

## Combined Security Hook

All-in-one security validation.

```python
#!/usr/bin/env python3
"""Comprehensive security validation"""
import json
import sys
import os
import re

def check_sensitive_files(file_path):
    """Check if file is sensitive."""
    sensitive = ['.env', 'credentials', 'secrets', 'private_key', '.pem']
    return any(s in file_path.lower() for s in sensitive)

def check_path_traversal(file_path):
    """Check for path traversal."""
    return ".." in file_path

def check_dangerous_command(command):
    """Check for dangerous bash commands."""
    dangerous = ['rm -rf /', 'dd if=', 'mkfs', ':(){ :|:& };:']
    return any(d in command for d in dangerous)

def check_secrets(content):
    """Check for hardcoded secrets."""
    patterns = [
        r'password\s*=\s*["\'][^"\']{8,}["\']',
        r'api[_-]?key\s*=\s*["\'][^"\']{20,}["\']',
    ]
    return any(re.search(p, content, re.IGNORECASE) for p in patterns)

def main():
    input_data = json.load(sys.stdin)
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    # File operations
    if tool_name in ["Write", "Edit", "MultiEdit"]:
        file_path = tool_input.get("file_path", "")
        content = tool_input.get("content", "")

        if check_sensitive_files(file_path):
            print(f"❌ Cannot modify sensitive file: {file_path}", file=sys.stderr)
            sys.exit(2)

        if check_path_traversal(file_path):
            print("❌ Path traversal detected", file=sys.stderr)
            sys.exit(2)

        if content and check_secrets(content):
            print("❌ Hardcoded secrets detected", file=sys.stderr)
            sys.exit(2)

    # Bash commands
    elif tool_name == "Bash":
        command = tool_input.get("command", "")

        if check_dangerous_command(command):
            print(f"❌ Dangerous command blocked", file=sys.stderr)
            sys.exit(2)

    sys.exit(0)

if __name__ == "__main__":
    main()
```

**Configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/security.py",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

## Best Practices

1. **Defense in depth** - Multiple checks better than one
2. **Clear error messages** - Explain why blocked
3. **Allowlist > Denylist** - Whitelist is more secure
4. **Fast checks** - Keep security hooks under 10s
5. **Fail securely** - Block when uncertain
6. **Log attempts** - Track blocked operations
7. **Regular updates** - Keep pattern lists current

## Testing

```bash
# Test sensitive file blocking
echo '{
  "tool_name": "Write",
  "tool_input": {"file_path": ".env"}
}' | python3 .claude/hooks/block-sensitive.py
echo $?  # Should be 2

# Test normal file (should pass)
echo '{
  "tool_name": "Write",
  "tool_input": {"file_path": "src/index.ts"}
}' | python3 .claude/hooks/block-sensitive.py
echo $?  # Should be 0
```
