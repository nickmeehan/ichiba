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

2. **Stage** relevant files with `git add` — name files explicitly, never use `git add .` or `git add -A`.

3. **Compose message** — conventional commit format, then create with `git commit -m "..."`.

Only emit tool calls — no explanatory text.

## Conventional Commit Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

Choose the type that matches the **intent** of the change, not just the shape of the diff. If new files or abstractions are introduced solely to make existing behavior faster, that's `perf`, not `feat`. If code is restructured without changing behavior, that's `refactor`, not `feat`.

| Type | Use for |
|------|---------|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace — no logic change |
| `refactor` | Restructuring — no feature or fix |
| `perf` | Making existing behavior faster |
| `test` | Adding or correcting tests |
| `build` | Build system changes (webpack, tsconfig, Makefile) |
| `ci` | CI configuration |
| `chore` | Other maintenance, dependency bumps |
| `revert` | Revert a previous commit |

### Examples

These steer common ambiguous cases:

```
feat(auth): add OAuth2 login support
fix(parser): handle null values in nested objects
chore(deps): bump axios from 1.4.0 to 1.6.0
perf(db): add query caching layer
refactor(store): replace Redux with Zustand
test(auth): add unit tests for middleware
docs(readme): add API reference and troubleshooting
```

### Breaking Changes

Signal breaking changes with `!` after type/scope and/or a `BREAKING CHANGE:` footer:
```
feat(api)!: drop support for API v1 endpoints

BREAKING CHANGE: /api/v1/* routes return 410 Gone.
```

### Rules

- Use lowercase type from the table, followed by colon and space: `feat: `
- Add optional scope in parentheses: `feat(auth): `
- Write description in lowercase imperative mood, no trailing period
- Separate optional body from description with one blank line — explain *what* and *why*
- Separate optional footers from body with one blank line — use `-` in tokens instead of spaces (except `BREAKING CHANGE`)
- Never append a session link to the commit message
