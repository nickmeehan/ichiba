#!/bin/bash

# install-hooks.sh
# Installs the git pre-commit hook for this repo.
# Called automatically via SessionStart hook in .claude/settings.json.

set -e

HOOK_TARGET="$(git rev-parse --git-path hooks)/pre-commit"

cat > "$HOOK_TARGET" << 'HOOK'
#!/bin/bash

# Auto-installed by bin/install-hooks.sh

REPO_ROOT="$(git rev-parse --show-toplevel)"
staged="$(git diff --cached --name-only)"

# Validate manifests/skills when they change
if command -v claude >/dev/null 2>&1 &&
   echo "$staged" | grep -qE '(plugin\.json|marketplace\.json|hooks\.json|SKILL\.md)'; then
    claude plugin validate "$REPO_ROOT" || exit 1
fi

# Run the converter test when it or its test changes
if echo "$staged" | grep -qE '^(bin/dot2mermaid|test/)'; then
    ruby "$REPO_ROOT/test/dot2mermaid_test.rb" || exit 1
fi
HOOK

chmod +x "$HOOK_TARGET"
