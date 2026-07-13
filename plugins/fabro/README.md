# dark-factory

A factory for building [Fabro](https://fabro.sh) dark factories.

[Fabro](https://github.com/fabro-sh/fabro) runs version-controlled workflow
graphs (Graphviz DOT) over coding agents, shell commands, and human gates —
"dark factory" = humans supervise specs and outcomes, not lines of code. The
docs teach the concepts well, but authoring workflows is still manual. This
repo closes that gap: it holds the full knowledge base and packages it as
skills an agent can use to design, author, and validate workflows for you —
in this repo or injected into any other project.

## What's here

- **`fabro-docs/`** — full mirror of [docs.fabro.sh](https://docs.fabro.sh)
  as raw markdown (~110 pages: concepts, language spec, CLI, API, tutorials).
  Refresh with `bin/sync-docs.sh`; `git diff` shows upstream changes.
- **`skills/`** — Agent Skills (`SKILL.md` format) that make agents fluent in
  Fabro. Works in both Claude Code (`.claude/skills/` symlinks) and Fabro
  itself (`{git_root}/skills/` is a native Fabro skill directory).
  - `fabro-workflow-author` — plain-English description → validated `.fabro` workflow.
- **`bin/dot2mermaid`** — zero-dependency Ruby converter from `.fabro`/DOT
  graphs to Mermaid flowcharts, for PR descriptions and docs (GitHub renders
  Mermaid inline; lossy: conditions become edge labels, prompts/models drop).

## Install as a Claude Code plugin

Distributed as the `fabro` plugin via the
[ichiba](https://github.com/nickmeehan/ichiba) marketplace:

```
/plugin marketplace add nickmeehan/ichiba
/plugin install fabro@ichiba
```

Skills become available in every project you open; the `fabro-docs/` mirror
rides along in the plugin cache for offline deep reference (the skill fetches
docs.fabro.sh live for anything version-sensitive). For a single machine
without the plugin system, symlinking works too:
`ln -s "$PWD/skills/fabro-workflow-author" ~/.claude/skills/`.

To inject skills into another project directly: copy or symlink a skill
directory into that project's `.claude/skills/` (Claude Code) or
`.fabro/skills/` (Fabro).

## Upstream sources

- Product: [fabro-sh/fabro](https://github.com/fabro-sh/fabro) (Rust, MIT) —
  docs source lives in the same repo under `docs/`, no separate docs repo.
- Related: [fabro-sh/quarry](https://github.com/fabro-sh/quarry) (shared
  agent/human document workspace), `fabro-sh/fabro.report`, `fabro-sh/graphviz-sys`.

## Roadmap sketch

- More skills: workflow reviewer (lint graphs against dark-factory maturity —
  verification gates, fix loops, checkpoints), model-stylesheet author,
  self-host/deploy helper.
- A workflow library: proven `.fabro` templates (plan→implement→verify,
  parallel review, multi-model ensemble) to import instead of writing from scratch.
- Fleet management: talk to a Fabro server's API (runs, approvals, billing)
  from here — the OpenAPI spec is mirrored at `fabro-docs/api-reference/fabro-api.yaml`.
