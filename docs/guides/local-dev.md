# Local Development

This guide covers setting up and running the Nimbus platform locally using Docker Compose, including hot reload, seed data, and mock services.

## Prerequisites

- Node.js 20+ (use `nvm` or `fnm`)
- pnpm 9+ (`corepack enable && corepack prepare pnpm@latest --activate`)
- Docker Desktop 4.25+ with at least 4 GB RAM allocated
- VS Code (recommended) with workspace extensions

## Docker Compose Setup

The local environment runs PostgreSQL 16, Redis 7, and MinIO (S3-compatible storage) in containers:

```bash
# Start all infrastructure services
docker compose up -d

# Verify services are running
docker compose ps
```

| Service | Port | Purpose |
|---------|------|---------|
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Cache and job queue |
| MinIO | 9000 / 9001 | File storage (S3 mock) |
| Mailpit | 8025 | Email capture |

## Hot Reload Configuration

All three apps support hot reload out of the box:

```bash
# Start all apps with hot reload
pnpm dev
```

This runs `turbo dev` which starts `apps/web` (Next.js on port 3000), `apps/api` (Express on port 4000), and `apps/worker` concurrently. File changes trigger automatic restarts via `tsx watch` for the API and worker.

If hot reload stops working, check that your file watcher limit is high enough:

```bash
# Linux
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## Seed Data

The seed script creates a realistic multi-tenant dataset:

```bash
pnpm db:seed
```

This creates:
- **Acme Corp** tenant with 3 projects, 50 tasks, and 5 users
- **Globex Inc** tenant with 2 projects, 30 tasks, and 3 users
- Admin user: `admin@nimbus.local` / password: `nimbus-dev-123`
- Regular user: `user@nimbus.local` / password: `nimbus-dev-123`

To reset the database and re-seed: `pnpm db:reset && pnpm db:seed`.

## Mock Services

External services are mocked locally using MSW (Mock Service Worker) and local alternatives:

- **Stripe**: Uses Stripe CLI with `stripe listen --forward-to localhost:4000/webhooks/stripe`
- **SendGrid**: Emails are captured by Mailpit at `http://localhost:8025`
- **LaunchDarkly**: Falls back to `flags.local.json` when `LD_SDK_KEY` is not set
- **AWS S3**: MinIO at `http://localhost:9000` (credentials: `minioadmin`/`minioadmin`)

## Recommended VS Code Extensions

Install the workspace-recommended extensions when prompted, or run:

```bash
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension prisma.prisma
code --install-extension bradlc.vscode-tailwindcss
code --install-extension ms-playwright.playwright
```

## See Also

- [Onboarding](onboarding.md) — first-time setup walkthrough
- [Debugging](debugging.md) — troubleshooting local issues
- [CI/CD Pipeline](deployment/ci-cd.md) — how local code reaches production

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Docker Compose configuration, Node.js version, or infrastructure services change -->
