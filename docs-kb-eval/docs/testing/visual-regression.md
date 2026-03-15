# Visual Regression Testing

Visual regression tests catch unintended changes to component appearance. Nimbus uses Chromatic (integrated with Storybook) for automated visual comparison.

## Chromatic Integration

[Chromatic](https://www.chromatic.com/) captures screenshots of every Storybook story and compares them against approved baselines.

Setup is in `packages/ui/`:

```bash
# Run Chromatic locally (usually only needed for debugging)
npx chromatic --project-token=$CHROMATIC_PROJECT_TOKEN

# Chromatic runs automatically in CI on every PR
```

The Chromatic project token is stored in GitHub Actions secrets.

## Component Snapshots

Every component in the design system (`packages/ui/`) has Storybook stories that serve as visual test cases:

```typescript
// packages/ui/src/components/TaskCard/TaskCard.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { TaskCard } from './TaskCard';

const meta: Meta<typeof TaskCard> = {
  component: TaskCard,
  args: {
    title: 'Implement search feature',
    priority: 'high',
    assignee: { name: 'Alex Reyes', avatar: '/avatars/alex.jpg' },
  },
};

export default meta;

export const Default: StoryObj<typeof TaskCard> = {};
export const Overdue: StoryObj<typeof TaskCard> = {
  args: { dueDate: '2026-03-01', status: 'overdue' },
};
export const Completed: StoryObj<typeof TaskCard> = {
  args: { status: 'completed' },
};
```

Chromatic captures each story variant (Default, Overdue, Completed) as a separate snapshot.

## Review Workflow

When Chromatic detects visual changes:

1. The PR check shows "Chromatic: visual changes detected".
2. Click the Chromatic link to open the review UI.
3. Review each changed component side-by-side (before vs. after).
4. **Accept** intentional changes or **Deny** unintentional regressions.
5. Accepted changes become the new baseline.

At least one team member must review and accept visual changes before the PR can merge.

## Baseline Management

- Baselines are stored in Chromatic's cloud (not in the repo).
- Each branch has its own baseline, forked from `main` at branch creation.
- When a branch merges to `main`, accepted changes become the new `main` baseline.
- To reset a baseline, use the Chromatic dashboard: Library > Component > Reset baseline.

## Handling Flaky Snapshots

Some components have non-deterministic rendering (animations, dates, avatars). To prevent false positives:

- Use `parameters.chromatic.delay` to wait for animations to complete.
- Mock dates and times in stories using Storybook decorators.
- Use `parameters.chromatic.diffThreshold` to allow minor pixel differences (default: 0.063).

```typescript
export const WithAnimation: StoryObj<typeof TaskCard> = {
  parameters: {
    chromatic: { delay: 500, diffThreshold: 0.1 },
  },
};
```

## See Also

- [E2E Tests](e2e-tests.md) — page-level screenshot comparison
- [React Patterns](../conventions/react-patterns.md) — component design standards
- [CI Test Config](ci-test-config.md) — Chromatic in the CI pipeline

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Chromatic version, Storybook version, or visual review process changes -->
