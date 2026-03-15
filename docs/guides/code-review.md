# Code Review Process

Code review is a critical quality gate at Nimbus. Every change to `main` must be reviewed and approved before merge. This guide covers expectations for both authors and reviewers.

## Review Checklist

Reviewers should verify the following:

- [ ] **Correctness**: Does the code do what the ticket describes?
- [ ] **Tests**: Are there adequate unit and integration tests for new behavior?
- [ ] **Types**: Are TypeScript types precise (no `any`, proper generics)?
- [ ] **Security**: Is user input validated? Are authorization checks present?
- [ ] **Performance**: Are there N+1 queries, missing indexes, or unnecessary re-renders?
- [ ] **Tenant isolation**: Does the query filter by `tenantId`? Multi-tenant leaks are P0 bugs.
- [ ] **Accessibility**: Do new UI components have proper ARIA attributes and keyboard support?
- [ ] **Documentation**: Are complex decisions explained in code comments or ADRs?

## PR Size Guidelines

| Size | Lines changed | Target |
|------|--------------|--------|
| Small | < 100 | Preferred for most changes |
| Medium | 100-300 | Acceptable for features |
| Large | 300-500 | Should be split if possible |
| XL | 500+ | Requires tech lead justification |

If a feature is inherently large, break it into a stack of PRs using feature flags to keep incomplete work hidden.

## Review Turnaround SLA

- **Small PRs** (< 100 lines): reviewed within 4 business hours
- **Medium PRs** (100-300 lines): reviewed within 8 business hours
- **Large PRs** (300+ lines): reviewed within 24 business hours

If your PR has not been reviewed within the SLA, post a reminder in `#nimbus-pr-reviews`. If it is blocking a release, escalate to the tech lead.

## Approval Requirements

- All PRs require **at least one approval** from a team member.
- PRs touching `packages/db/prisma/` (schema changes) require approval from **the tech lead or DevOps lead**.
- PRs touching `infra/` (Terraform) require approval from **the DevOps lead**.
- PRs modifying authentication or authorization require approval from **two reviewers**, one of whom must be a senior engineer.

## Merge Strategy

Nimbus uses **squash merges** to `main`. The squash commit message should follow the format:

```
feat(projects): add task dependency visualization (#1234)
```

After merge, delete your feature branch. The CI pipeline handles deployment to staging automatically.

## See Also

- [PR Process](../conventions/pr-process.md) — PR template and automation
- [Git Workflow](../conventions/git-workflow.md) — branching conventions
- [TypeScript Style](../conventions/typescript-style.md) — type-level expectations

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: review process, approval requirements, or merge strategy changes -->
