# New Developer Onboarding

Welcome to Nimbus. This guide covers everything you need to go from zero to shipping your first pull request within your first week.

## First-Day Checklist

- [ ] Get added to the `nimbus-eng` GitHub team
- [ ] Request access to 1Password Engineering vault
- [ ] Join Slack channels: `#nimbus-dev`, `#nimbus-deploys`, `#nimbus-incidents`, `#nimbus-pr-reviews`
- [ ] Accept calendar invites for daily standup (10:15 AM ET) and weekly architecture review (Thursdays 2 PM ET)
- [ ] Set up your [local development environment](local-dev.md)

## Codebase Tour

Nimbus is a monorepo structured as follows:

```
nimbus/
├── apps/
│   ├── web/          # Next.js frontend (React, TypeScript)
│   ├── api/          # Express API server
│   └── worker/       # Background job processor (BullMQ)
├── packages/
│   ├── db/           # Prisma schema + migrations
│   ├── shared/       # Shared types, utils, constants
│   └── ui/           # Design system components (Storybook)
├── infra/            # Terraform modules (AWS)
└── scripts/          # Developer tooling scripts
```

Start by reading `packages/db/prisma/schema.prisma` to understand the data model. Then look at `apps/api/src/routes/` to see how API endpoints are organized by resource.

## Key Contacts

| Role | Person | Slack handle |
|------|--------|-------------|
| Engineering Manager | Dana Park | `@dana` |
| Tech Lead | Alex Reyes | `@areyes` |
| DevOps Lead | Jordan Liu | `@jliu` |
| Product Manager | Sam Okoro | `@sokoro` |
| Design Lead | Maya Chen | `@mchen` |

## Dev Environment Setup

See the full [Local Development](local-dev.md) guide. The short version:

```bash
git clone git@github.com:nimbus-hq/nimbus.git
cd nimbus
cp .env.example .env.local
pnpm install
docker compose up -d
pnpm db:migrate
pnpm db:seed
pnpm dev
```

## Your First PR

1. Pick a ticket labeled `good-first-issue` from the current sprint board.
2. Create a branch: `git checkout -b feat/NIMB-<ticket-number>-short-description`.
3. Make your changes, write tests, and ensure `pnpm check` passes locally.
4. Open a PR using the PR template. Tag `@nimbus-eng` for review.
5. Read the [Code Review](code-review.md) guide so you know what reviewers look for.

Your onboarding buddy will pair with you on your first PR if you want a walkthrough.

## See Also

- [Local Development](local-dev.md) — detailed environment setup
- [Code Review](code-review.md) — how we review PRs
- [Git Workflow](../conventions/git-workflow.md) — branching and commit conventions

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: onboarding process changes or team contacts rotate -->
