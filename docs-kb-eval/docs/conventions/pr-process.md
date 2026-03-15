# PR Process

This guide covers the pull request lifecycle at Nimbus, from opening a PR to post-merge cleanup.

## PR Template

Every PR uses the template at `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Summary
<!-- What does this PR do and why? -->

## Changes
<!-- Bullet list of notable changes -->

## Testing
<!-- How was this tested? -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Types are correct (no `any`)
- [ ] Tenant isolation verified
- [ ] Feature flag configured (if applicable)
- [ ] Database migration tested in staging
- [ ] Documentation updated (if applicable)

## Screenshots
<!-- For UI changes, include before/after screenshots -->

Ticket: NIMB-<number>
```

Fill out every section. Reviewers will ask for missing context.

## Required Checks

PRs cannot merge until all required checks pass:

| Check | Tool | Blocking |
|-------|------|----------|
| Lint | ESLint | Yes |
| Type check | TypeScript | Yes |
| Unit tests | Jest | Yes |
| Integration tests | Jest | Yes |
| E2E tests | Playwright | Yes |
| Security scan | Snyk | Yes (high/critical) |
| Visual regression | Chromatic | Yes |
| Coverage | Codecov | Yes (if drops > 2%) |

## Review Assignment

PRs are auto-assigned reviewers using GitHub's CODEOWNERS file:

```
# .github/CODEOWNERS
packages/db/          @nimbus-hq/db-owners
apps/api/             @nimbus-hq/api-team
apps/web/             @nimbus-hq/web-team
infra/                @nimbus-hq/devops
packages/ui/          @nimbus-hq/design-system
```

If no CODEOWNERS match, the PR is assigned to the team lead's review queue.

## Merge Requirements

A PR can be merged when:

1. All required CI checks are green.
2. At least one approval from a CODEOWNERS reviewer.
3. No unresolved review comments (resolved or addressed with a follow-up ticket).
4. Branch is up to date with `main` (auto-enforced by GitHub).

Use the **Squash and merge** button. The PR title becomes the commit message.

## Post-Merge Cleanup

After merge:

1. Delete the feature branch (GitHub does this automatically if configured).
2. Verify the staging deployment succeeds (check `#nimbus-deploys`).
3. Move the Linear ticket to "In Review" or "Done" as appropriate.
4. If a follow-up ticket was created during review, link it to the parent ticket.

## See Also

- [Git Workflow](git-workflow.md) — branching and commit conventions
- [Code Review](../guides/code-review.md) — reviewer expectations and SLA
- [CI/CD Pipeline](../guides/deployment/ci-cd.md) — required check configuration

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: PR template, required checks, CODEOWNERS, or merge rules change -->
