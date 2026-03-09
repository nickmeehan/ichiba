#!/bin/bash
# install-rules.sh — Symlink plugin rules into project as a named subdirectory
# Creates .claude/rules/docs-kb/ → plugin's rules/ directory.
# The project's own .claude/rules/ files are untouched — this is an additive subdirectory.
mkdir -p .claude/rules
ln -sfn "${CLAUDE_PLUGIN_ROOT}/rules" .claude/rules/docs-kb 2>/dev/null || \
cp -r "${CLAUDE_PLUGIN_ROOT}/rules" .claude/rules/docs-kb
exit 0
