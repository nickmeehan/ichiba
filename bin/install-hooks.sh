#!/bin/bash

# install-hooks.sh
# Installs the git pre-commit hook for this repo.
# Called automatically via SessionStart hook in .claude/settings.json.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_TARGET="$REPO_ROOT/.git/hooks/pre-commit"

cat > "$HOOK_TARGET" << 'HOOK'
#!/bin/bash

# Auto-installed by bin/install-hooks.sh
# Validates plugin/marketplace schemas before each commit.

REPO_ROOT="$(git rev-parse --show-toplevel)"

# Only run if manifest files are staged
if git diff --cached --name-only | grep -qE '(plugin\.json|marketplace\.json|hooks\.json|SKILL\.md)'; then
    if command -v claude >/dev/null 2>&1; then
        claude plugin validate "$REPO_ROOT"
    fi
fi
HOOK

chmod +x "$HOOK_TARGET"
