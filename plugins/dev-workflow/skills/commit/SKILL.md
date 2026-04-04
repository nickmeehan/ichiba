---
name: commit
description: >
  Stage and create a conventional git commit. Use when the user asks to commit,
  or when an agent reaches a logical checkpoint worth capturing. Enforces
  Conventional Commits v1.0.0.
---

# Commit Skill

## Allowed Tools

- `Bash(git add:*)`
- `Bash(git status:*)`
- `Bash(git commit:*)`
- `Bash(git diff:*)`
- `Bash(git log:*)`

## Token Efficiency

Skip `git diff` and `git log` when you already know what changed from the current conversation (you wrote or reviewed the code). Only gather context when you genuinely lack knowledge of the changes.

## Process

1. **Gather context** (skip when you already know what changed):
   ```bash
   git status
   git diff HEAD
   git log --oneline -5
   ```

2. **Stage** relevant files with `git add`.

3. **Compose message** — conventional commit format, then create with `git commit -m "..."`.

Only emit tool calls — no explanatory text.

## Conventional Commit Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Use for |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace — no logic change |
| `refactor` | Restructuring — no feature or fix |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `build` | Build system or dependency changes |
| `ci` | CI configuration |
| `chore` | Other maintenance |
| `revert` | Revert a previous commit |

### Rules

- Use lowercase type from the table, followed by colon and space: `feat: `
- Add optional scope in parentheses: `feat(auth): `
- Write description in lowercase imperative mood, no trailing period
- Separate optional body from description with one blank line — explain *what* and *why*
- Separate optional footers from body with one blank line — use `-` in tokens instead of spaces (except `BREAKING CHANGE`)
- Signal breaking changes with `!` after type/scope (`feat(api)!:`) and/or a `BREAKING CHANGE:` footer
- Never append a session link to the commit message
