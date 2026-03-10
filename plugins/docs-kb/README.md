# docs-kb

Progressive disclosure documentation system for Claude Code. Gives any project a docs/ directory that Claude navigates automatically based on task relevance.

## Installation

```bash
/plugin install docs-kb@nickmeehan/ichiba
```

## Getting Started

After installation, initialize your docs:

```
/docs-kb:docs-bootstrap
```

This creates the docs infrastructure (`_index.md`, CLAUDE.md markers) without skeleton files. You create your first doc when Claude makes a preventable mistake — not before.

## Components

### Agents

#### `doc-traversal`

Navigates the docs directory tree to find documentation relevant to the current task. Reads `_index.md` routing tables at each level, matches entries against the task, and returns relevant leaf docs. Errs on the side of inclusion — reading an extra doc is cheaper than missing a relevant one.

### Skills

#### `docs-bootstrap`

Initialize a docs/ progressive disclosure system for a project. Creates `_index.md`, CLAUDE.md markers, and README. Supports subfolder (default `docs/`) or repo-root placement.

```
/docs-kb:docs-bootstrap
```

#### `docs-add`

Create a new doc file and register it in the docs index. Enforces naming conventions, duplicate detection, tree-aware placement, and situation-based descriptions.

```
/docs-kb:docs-add auth
```

### Rules

#### `scan-docs-index`

Automatically loaded on every session start via a SessionStart hook. Instructs Claude to scan the docs index in CLAUDE.md at the start of every task, read matching docs before starting work, and fall back to codebase search when no doc matches.

## How It Works

1. **CLAUDE.md** contains a docs index section (between `DOCS-INDEX-START`/`DOCS-INDEX-END` markers) listing docs with situation-based descriptions
2. **A rule file** (auto-installed to `.claude/rules/docs-kb/`) triggers Claude to scan this index at every task start
3. **The traversal agent** navigates nested doc trees via `_index.md` routing tables at each directory level
4. **Skills** help you create docs with proper conventions and placement

## When to Use This Plugin

- Your CLAUDE.md exceeds 150-200 lines
- Your project has 8+ distinct documentation topics
- Claude regularly makes preventable mistakes due to missing context

## When NOT to Use This Plugin

- Your CLAUDE.md is under 150 lines and working fine
- Subdirectory CLAUDE.md files handle your needs
- You have fewer than 1,500 total lines of documentation
