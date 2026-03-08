---
name: commit
description: >
  Stage and create a conventional git commit based on the current repository
  state. Use whenever a commit is needed — both when explicitly requested by
  the user and when an agent determines that work has reached a logical
  checkpoint worth capturing. Enforces Conventional Commits v1.0.0 (feat,
  fix, chore, etc.).
---

# Commit Skill

Create a conventional git commit based on the current repository state.

## Allowed Tools

- `Bash(git add:*)`
- `Bash(git status:*)`
- `Bash(git commit:*)`
- `Bash(git diff:*)`
- `Bash(git branch:*)`
- `Bash(git log:*)`

## Context

Gather the following before composing the commit message:

```bash
git status
git diff HEAD
git branch --show-current
git log --oneline -10
```

## Task

1. Analyze the staged and unstaged changes
2. Stage relevant changes with `git add`
3. Compose a **Conventional Commit** message (see spec below)
4. Create the commit with `git commit -m "..."` — do not include a session link in the message

Only emit tool calls — no explanatory text.

---

## Conventional Commits Specification v1.0.0

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | When to use | SemVer impact |
|------|-------------|---------------|
| `feat` | New feature added to the codebase | MINOR |
| `fix` | Bug fix | PATCH |
| `docs` | Documentation only changes | none |
| `style` | Formatting, whitespace — no logic change | none |
| `refactor` | Code restructuring — no feature/fix | none |
| `perf` | Performance improvement | none |
| `test` | Adding or correcting tests | none |
| `build` | Build system or external dependency changes | none |
| `ci` | CI configuration changes | none |
| `chore` | Other changes that don't modify src or test files | none |
| `revert` | Reverts a previous commit | none |

### Rules

1. **type** MUST be a lowercase noun from the table above.
2. **type** MUST be followed by a colon and a single space: `feat: `.
3. **scope** is OPTIONAL. When provided it MUST be a noun in parentheses describing the section of the codebase: `feat(auth): `.
4. **description** MUST immediately follow `type(scope): `. It is a short imperative-mood summary in lowercase, no trailing period.
5. **body** is OPTIONAL. Separate from description by one blank line. Use it to explain *what* and *why*, not *how*. Free-form paragraphs.
6. **footers** are OPTIONAL. Separate from body (or description if no body) by one blank line. Each footer token MUST use `-` instead of spaces (except `BREAKING CHANGE`).

### Breaking Changes

Breaking changes MUST be signalled in one or both of two ways:

**Option A — `!` in the type/scope prefix:**
```
feat(api)!: remove support for XML responses
```

**Option B — `BREAKING CHANGE` footer:**
```
feat(api): remove support for XML responses

BREAKING CHANGE: The /v1/data endpoint no longer accepts or returns XML.
Clients must migrate to JSON. See migration guide at docs/migration.md.
```

Both options MAY be combined. `BREAKING CHANGE` correlates with MAJOR in SemVer.

### Scope Guidelines

- Use the name of the module, package, or area affected: `feat(auth)`, `fix(parser)`, `docs(readme)`
- Keep scope short — one word or hyphenated phrase
- Omit scope when the change is truly cross-cutting

### Footer Format

```
<token>: <value>
<token> #<value>
```

Common footer tokens:
- `BREAKING CHANGE: <description>`
- `Refs: #123`
- `Co-authored-by: Name <email>`
- `Reviewed-by: Name`
- `Fixes: #456`

### Examples

**Simple feature:**
```
feat(auth): add OAuth2 login support
```

**Bug fix with issue reference:**
```
fix(parser): handle null values in nested objects

Refs: #42
```

**Breaking change with body and footer:**
```
feat(api)!: drop support for API v1 endpoints

All v1 routes have been removed. Consumers must upgrade to v2.
The migration guide is available at docs/v2-migration.md.

BREAKING CHANGE: /api/v1/* routes return 410 Gone.
Refs: #88
```

**Chore with scope:**
```
chore(deps): bump axios from 1.4.0 to 1.6.0
```

**Multi-paragraph body:**
```
refactor(store): replace Redux with Zustand

Redux added significant boilerplate for simple global state needs.
Zustand provides the same capabilities with a much smaller API surface.

All existing selectors and actions have been preserved as Zustand hooks.
```

### What NOT to do

- Do NOT capitalise the description: `feat: Add login` ❌ → `feat: add login` ✅
- Do NOT add a period at the end of the description: `fix: correct typo.` ❌
- Do NOT use past tense: `feat: added login` ❌ → `feat: add login` ✅
- Do NOT use a type outside the table above without team agreement
- Do NOT omit the space after the colon: `feat:add login` ❌
- Do NOT append a session link (e.g. `https://claude.ai/code/session_...`) to the commit message
