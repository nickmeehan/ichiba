> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Quick Start

> Get up and running with Fabro

> [!NOTE]
>
> Fabro runs as a server. This quickstart runs everything locally on your laptop — no deployment required. To self-host the server for a team or 24/7 workflows, see [Deployment](https://docs.fabro.sh/administration/deployment.md).

## Supported platforms

| OS | Architecture | Supported |
| - | - | - |
| Linux | x86\_64 | Yes |
| Linux | arm64 (aarch64) | Yes |
| macOS | arm64 (Apple Silicon) | Yes |
| macOS | x86\_64 (Intel) | No |
| Windows | any | No |

> [!NOTE]
>
> On Intel Macs, run Fabro in a Linux x86\_64 container or VM. Native Windows isn't supported; use WSL2 with a supported Linux architecture.

## Install

> [tab] Claude Code
>
> ```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
> curl -fsSL https://fabro.sh/install.md | claude
> ```

> [tab] Codex
>
> ```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
> codex "$(curl -fsSL https://fabro.sh/install.md)"
> ```

> [tab] Homebrew
>
> ```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
> brew install fabro-sh/tap/fabro-nightly
> ```

> [tab] Bash
>
> ```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
> curl -fsSL https://fabro.sh/install.sh | bash
> ```

> [!TIP]
>
> Release binaries and the multi-arch Docker image ship with [SLSA Build Provenance](https://docs.fabro.sh/reference/verifying-releases.md) attestations you can verify with `gh attestation verify`.

> [!NOTE]
>
> Self-hosting the server? See [Self-host with Docker](https://docs.fabro.sh/administration/self-host-docker.md) and [Server Operations](https://docs.fabro.sh/reference/server-operations.md) for the install wizard, auth, and CLI-pointing.

## Initialize your project

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
cd my-repo/
fabro repo init
```

This creates `.fabro/project.toml` and a starter workflow under `.fabro/workflows/hello/`.

## Configure API keys

`fabro run` uses the Fabro server even when you run it from a local terminal. If installation has not already configured a provider, store a key in that server's vault:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro secret set ANTHROPIC_API_KEY sk-ant-...
```

You can also use `fabro provider login --provider anthropic` for guided setup. You only need one provider to get started; add more to enable multi-model workflows.

> [!NOTE]
>
> Exporting a provider key in your shell does not configure server-backed workflows. For a remote server, use `fabro secret --server https://fabro.example.com set ANTHROPIC_API_KEY sk-ant-...` and `fabro run --server https://fabro.example.com hello` so both commands use the same server. Direct `fabro exec` and SDK callers have different [credential sources](https://docs.fabro.sh/core-concepts/models.md#credential-sources).

## Run your first workflow

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro run hello
```

## Next steps

> [card] [Why Fabro?](https://docs.fabro.sh/getting-started/why-fabro.md)
>
> Understand the problems Fabro solves.

> [card] [Workflows](https://docs.fabro.sh/core-concepts/workflows.md)
>
> Learn how to define workflow graphs in Graphviz.


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.