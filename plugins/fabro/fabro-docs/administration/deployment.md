> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Deployment

> Choose where the Fabro server runs: on your laptop or self-hosted on a server

Fabro runs as a server. The CLI authenticates and communicates with that server, whether the server is running on your laptop or on a remote host. Choose where the server runs based on how you use Fabro.

## Two deployment modes

| | Local | Self-hosted |
| - | - | - |
| **Where the server runs** | Your laptop | A host you operate (Docker container) |
| **How to start it** | `fabro server start` | `docker compose up -d` |
| **Best for** | Solo use, getting started, learning | Teams, production, 24/7 workflows |
| **Trade-off** | Workflows pause when your laptop sleeps or shuts off | You operate the host |

Both modes use the same image, the same workflow engine, and the same CLI. The only difference is where the server process lives.

## Local

Run `fabro server start` on your machine. State persists under `~/.fabro/`. The CLI talks to it over a Unix socket by default. This is the right mode for solo use and getting started — no deployment required.

When your laptop sleeps or shuts off, in-flight workflows pause until the laptop wakes again. For workflows that need to run 24/7 or for teams sharing a single instance, self-host.

See [Server Operations](https://docs.fabro.sh/reference/server-operations.md) for starting the server, the install wizard, authentication, and pointing the CLI at it.

## Self-hosted

For team use, production workflows, or running 24/7, self-host the server as a Docker container. The recommended approach is `docker compose` for a single host, or any cloud container service (ECS, Cloud Run, Kubernetes) using the same image with the same requirements.

Use a public reverse proxy such as Caddy when the server must be reachable from the public internet. Use Tailscale Services when the server should stay private to your tailnet; Fabro still serves plain HTTP locally, and Tailscale provides the HTTPS endpoint.

> **[Self-host with Docker](https://docs.fabro.sh/administration/self-host-docker.md)**
>
> Compose-first walkthrough, including Caddy and Tailscale Services options.

> **[Deploy to Railway](https://docs.fabro.sh/administration/deploy-railway.md)**
>
> One-click managed shortcut for the same Docker image.


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.