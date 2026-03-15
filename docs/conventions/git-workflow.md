# Git Workflow

Nimbus follows trunk-based development with short-lived feature branches. This guide covers branching, commit messages, and merge strategy.

## Trunk-Based Development

`main` is the single source of truth. All feature work branches from `main` and merges back to `main`. There are no long-lived development or release branches.

```
main ─────●──────●──────●──────●──────●──────
           \    /         \    /
            feat/NIMB-42   feat/NIMB-58
            (1-3 days)     (1-2 days)
```

## Branch Naming

Branch names follow the pattern:

```
<type>/NIMB-<ticket>-<short-description>
```

| Type | When to use |
|------|------------|
| `feat/` | New feature or enhancement |
| `fix/` | Bug fix |
| `chore/` | Maintenance, dependencies, config |
| `refactor/` | Code restructuring without behavior change |
| `docs/` | Documentation only |

Examples:
- `feat/NIMB-123-task-dependencies`
- `fix/NIMB-456-login-redirect-loop`
- `chore/NIMB-789-upgrade-prisma`

## Short-Lived Branches

Feature branches should live for **1-3 days** maximum. If a feature takes longer:

1. Break it into smaller PRs using feature flags.
2. Merge partial work behind a flag.
3. Keep the branch up to date with `main` by rebasing daily.

Long-lived branches cause merge conflicts and delay integration testing.

## Commit Message Format

Individual commit messages on feature branches are not strictly enforced (they will be squashed). However, use meaningful messages for your own benefit:

```
Add task dependency model and migration
Wire up dependency API endpoints
Fix circular dependency validation
Add unit tests for dependency service
```

## Squash Merges

All PRs are merged with **squash merge**. The squash commit message follows Conventional Commits:

```
<type>(<scope>): <description> (#<PR-number>)
```

Examples:
- `feat(tasks): add task dependency tracking (#1234)`
- `fix(auth): resolve redirect loop after session expiry (#1256)`
- `chore(deps): upgrade Prisma to 5.12.0 (#1260)`

The PR title becomes the squash commit message. Write the PR title in this format from the start.

## Rebase vs. Merge

- **Rebase** your feature branch onto `main` to stay current: `git rebase main`.
- **Never** merge `main` into your feature branch (creates noisy merge commits).
- **Never** force-push to `main`.

## See Also

- [PR Process](pr-process.md) — pull request workflow
- [Code Review](../guides/code-review.md) — review and approval process
- [CI/CD Pipeline](../guides/deployment/ci-cd.md) — what happens after merge

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: branching strategy, commit message format, or merge strategy changes -->
