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

command -v claude >/dev/null 2>&1 || exit 0

staged="$(git diff --cached --name-only)"
echo "$staged" | grep -qE '(plugin\.json|marketplace\.json|hooks\.json|SKILL\.md)' || exit 0

# Validate the marketplace if its manifest or any plugin manifest changed
if echo "$staged" | grep -qE '(^|/)\.claude-plugin/(marketplace|plugin)\.json$|(^|/)hooks\.json$|(^|/)SKILL\.md$'; then
    claude plugin validate "$REPO_ROOT" || exit 1
fi

# Validate each plugin whose tree has staged changes
changed_plugins="$(echo "$staged" | awk -F/ '$1 == "plugins" && NF >= 2 { print $2 }' | sort -u)"
for plugin in $changed_plugins; do
    [ -d "$REPO_ROOT/plugins/$plugin" ] || continue
    claude plugin validate "$REPO_ROOT/plugins/$plugin" || exit 1
done
HOOK

chmod +x "$HOOK_TARGET"
