# dev-workflow

Developer workflow automation for Claude Code.

## Installation

```bash
/plugin install dev-workflow@nickmeehan/ichiba
```

## Skills

### `commit`

Stages and creates a [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/) based on the current repository state.

Invoke by asking Claude to commit, e.g.:
- "commit my changes"
- "make a commit"
- "commit this"

The skill gathers `git status`, `git diff HEAD`, current branch, and recent log before composing the message. It enforces the full Conventional Commits v1.0.0 spec (types, scopes, breaking changes) without needing to look anything up at runtime.
