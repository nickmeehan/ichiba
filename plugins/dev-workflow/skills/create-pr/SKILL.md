---
name: create-pr
description: >
  Create a pull request for the current branch. Use when the user asks to
  create a pull request, open a PR, or submit a PR. Supports both CLI
  (gh CLI) and Claude Code Web/Desktop (MCP tool) environments.
---

# Create PR Skill

Create a pull request for the current branch using conventional commit title format.

## Environment Detection

Determine which environment you are running in before proceeding:

1. **CLI (terminal/laptop)**: Run `which gh` — if it succeeds, use `gh pr create` for PR creation.
2. **Claude Code Web or Desktop app**: `gh` CLI is NOT available. Use the `mcp__github__create_pull_request` MCP tool instead with `owner`, `repo`, `title`, `head`, `base`, and `body` parameters.

If `which gh` fails and MCP tools are not available, inform the user that neither method is available and stop.

## Allowed Tools

- `Bash(git status:*)`
- `Bash(git diff:*)`
- `Bash(git log:*)`
- `Bash(git branch:*)`
- `Bash(git push:*)`
- `Bash(git rev-parse:*)`
- `Bash(git remote:*)`
- `Bash(which gh:*)`
- `Bash(gh pr create:*)`
- `mcp__github__create_pull_request`

## Token Efficiency

If you already have context from the current conversation about what changed (because you wrote the code or reviewed the commits), do NOT re-run exploratory git commands like `git diff`, `git log`, or `git status`. Only run those if you genuinely don't know what changed.

## Process

1. **Detect environment** — run `which gh` to determine CLI vs Web/Desktop.

2. **Gather context** (only if you don't already know what changed):
   ```bash
   git status
   git diff <base-branch>...HEAD
   git log --oneline <base-branch>..HEAD
   ```

3. **Determine branch info**:
   ```bash
   git branch --show-current
   git rev-parse --abbrev-ref HEAD@{upstream} 2>/dev/null || echo "no upstream"
   ```

4. **Push to remote**:
   ```bash
   git push -u origin <branch-name>
   ```

5. **Compose PR title** — use conventional commits format:

   | Prefix | When to use |
   |--------|-------------|
   | `feat:` | New feature |
   | `fix:` | Bug fix |
   | `chore:` | Maintenance, dependency updates |
   | `docs:` | Documentation changes |
   | `refactor:` | Code restructuring |

   Rules:
   - Keep under 70 characters
   - Lowercase description, no trailing period
   - Imperative mood: `feat: add login` not `feat: added login`

6. **Compose PR body** using this template:

   ```
   ## Summary
   - <bullet point 1>
   - <bullet point 2>
   - <bullet point 3 (optional)>

   ## Test plan
   - [ ] <testing step>
   - [ ] <testing step>
   ```

7. **Create the PR**:

   **CLI environment** — use a heredoc for the body:
   ```bash
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   ## Summary
   - ...

   ## Test plan
   - [ ] ...
   EOF
   )"
   ```

   **Web/Desktop environment** — use the MCP tool:
   ```
   mcp__github__create_pull_request(
     owner: "<org-or-user>",
     repo: "<repo-name>",
     title: "<title>",
     head: "<branch-name>",
     base: "main",
     body: "## Summary\n- ...\n\n## Test plan\n- [ ] ..."
   )
   ```

8. **After creation**:
   - Return the PR URL to the user.
   - Ask if they'd like to subscribe to PR activity events (comments, CI status, reviews) via `subscribe_pr_activity`.
