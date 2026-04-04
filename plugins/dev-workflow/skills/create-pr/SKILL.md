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

5. **Compose PR body** — exactly two sections, nothing else:
   ```
   ## Summary
   - <what changed and why>

   ## Test plan
   - [ ] <verification step>
   ```

6. **Create the PR**:

   CLI: `gh pr create --title "<title>" --body "<body>"`

   Web/Desktop:
   ```
   mcp__github__create_pull_request(
     owner, repo, title, head: "<branch>", base: "main", body
   )
   ```

7. **Show the PR URL** to the user.
