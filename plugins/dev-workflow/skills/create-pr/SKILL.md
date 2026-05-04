---
name: create-pr
description: >
  Create a pull request for the current branch. Use when the user asks to
  create a pull request, open a PR, or submit a PR. Make sure to use this
  skill whenever the user mentions PRs, pull requests, submitting code for
  review, or pushing changes for merge, even if they don't explicitly say
  "create a PR."
---

# Create PR Skill

## Environment Detection

Run `which gh` before anything else — `gh` CLI isn't available in Claude Code Web or Desktop.

- **Found** → use `gh pr create`
- **Not found** → use `mcp__github__create_pull_request` MCP tool. Parse `git remote get-url origin` for `owner` and `repo`.

Stop and tell the user if neither `gh` nor MCP tools are available.

## Token Efficiency

Skip `git diff`, `git log`, and `git status` when you already know what changed from the current conversation (you wrote the code or reviewed commits). Only gather context when you genuinely lack knowledge of what's on the branch.

## Process

1. **Detect environment** — `which gh`

2. **Gather context** (skip when you already know what changed):
   `git status`, `git diff <base>...HEAD`, `git log --oneline <base>..HEAD`

3. **Get branch name and push**:
   ```bash
   git branch --show-current
   git push -u origin <branch-name>
   ```

4. **Compose PR title** — conventional commits, under 70 chars, lowercase, no period, imperative mood:

   | Prefix | Use for |
   |--------|---------|
   | `feat:` | New feature |
   | `fix:` | Bug fix |
   | `chore:` | Maintenance, deps |
   | `docs:` | Documentation |
   | `refactor:` | Restructuring |

5. **Compose PR body** — exactly two sections, in this order: `## Summary` and `## Testing`. Both sections appear on every PR. The items inside each are conditional — include them only when they help the reviewer.

   **`## Summary`** — cover, in this order, only the items that apply:

   1. **State what changed.** Describe the user-visible or behavior-level change. Do not list files.
   2. **Explain why.** Fold in the ticket / conversation / issue link that prompted the work. Do not add a separate `## Context` heading.
   3. **Add a mermaid diagram when it helps.** Include a fenced `mermaid` code block when a flow, sequence, or state change reads more clearly as a picture (new request flow, reordered pipeline, state machine). Skip for trivial diffs.
   4. **Call out risks only when applicable.** Flag risks or things to watch when the change touches auth, migrations, shared infra, or perf-sensitive paths. Omit on trivial PRs.

   **`## Testing`** — cover both items below:

   1. **Write step-by-step verification.** Give concrete steps a reviewer can run to confirm the change works. Use checkbox bullets (`- [ ]`) so the reviewer can tick them off.
   2. **Embed screenshots and recordings inline.** Keep images and video links together inside Testing — do not split them into a separate section. Use them whenever richer media shows the thing actually works (UI, CLI output, an API response, a job running, a flow completing). Apply this bar: *would a reviewer understand faster from seeing it than from reading steps?* Skip only when there is genuinely nothing visual worth showing (pure refactor, doc-only change).

6. **Create the PR**:

   CLI: `gh pr create --title "<title>" --body "<body>"`

   Web/Desktop:
   ```
   mcp__github__create_pull_request(
     owner, repo, title, head: "<branch>", base: "main", body
   )
   ```

7. **Show the PR URL** to the user.
