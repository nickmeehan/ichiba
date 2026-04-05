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

Skip `git diff` and `git log` when you already know what changed (you wrote or reviewed the code in this conversation). Only run these commands when you genuinely lack knowledge of the changes.

## Process

1. **Gather context** (skip if you already know what changed):
   ```bash
   git status
   git diff HEAD
   git log --oneline -5
   ```

2. **Stage files** — run `git add` with explicit file names. Never use `git add .` or `git add -A`.

3. **Compose and commit** — build a conventional commit message and run `git commit -m "..."`.

Emit only tool calls. Do not output explanatory text.

## Conventional Commit Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

Match the type to the **intent** of the change, not the shape of the diff. Use `perf` when new code exists solely to make existing behavior faster. Use `refactor` when code is restructured without changing behavior. Do not default to `feat` just because new files appear.

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

Common types need one example each. Ambiguous types need more to prevent misclassification.

```
feat(auth): add OAuth2 login support
fix(parser): handle null values in nested objects
docs(readme): add API reference and troubleshooting
style: apply prettier formatting to src/
test(auth): add unit tests for middleware
build: migrate from webpack to vite
ci: add node 22 to test matrix
revert: revert "feat(auth): add OAuth2 login support"
```

**chore** — use for dependency bumps and general maintenance (not `build`):
```
chore(deps): bump axios from 1.4.0 to 1.6.0
chore(deps): upgrade typescript from 5.3 to 5.5
chore: remove unused legacy migration scripts
```

**perf** — use when the goal is making existing behavior faster, even if new code or abstractions are added (not `feat`):
```
perf(db): add query caching layer
perf(api): batch database lookups in list endpoint
perf(render): memoize expensive component tree calculations
```

**refactor** — use when restructuring without behavior change, even if new files are created (not `feat`):
```
refactor(store): replace Redux with Zustand
refactor(validation): extract controller logic into middleware
refactor(auth): switch from session cookies to JWTs
```

### Breaking Changes

Mark breaking changes with `!` after type/scope and/or a `BREAKING CHANGE:` footer:
```
feat(api)!: drop support for API v1 endpoints

BREAKING CHANGE: /api/v1/* routes return 410 Gone.
```

### Rules

- Pick a lowercase type from the table. Follow it with a colon and space: `feat: `
- Optionally add a scope in parentheses: `feat(auth): `
- Write the description in lowercase imperative mood. Do not end with a period.
- Separate the body from the description with one blank line. Explain *what* and *why*.
- Separate footers from the body with one blank line. Use `-` in footer tokens instead of spaces (except `BREAKING CHANGE`).
- Do not append a session link to the commit message.
