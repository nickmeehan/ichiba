---
name: docs-add
description: >
  Create a new doc file and register it in the docs index. Use when adding
  documentation to the docs tree. Enforces naming conventions, duplicate
  detection, tree-aware placement, and situation-based descriptions.
---

# docs-add

Create a new doc file and register it in the docs index.

## When to Use

- "add a doc for auth"
- "create docs for the testing setup"
- "document the deployment process"
- Adding any new documentation file to the docs tree

## Arguments

- `topic` (required): The topic name for the doc (e.g., "auth", "database", "deploy")

## Allowed Tools

- Read
- Write
- Edit
- Glob
- Grep
- AskUserQuestion

## Process

1. **Validate the topic name.** Must be lowercase, single-word or kebab-case.
   If not, suggest a corrected name.

2. **Check for duplicates.** Read the `_index.md` tree starting from the root
   (found via the CLAUDE.md doc-traversal agent reference). If a doc already
   covers this topic, warn the user and suggest updating the existing doc.

3. **Determine the correct location.** Traverse the `_index.md` tree to find
   which subdirectory best fits the new doc's topic:
   - If a matching subdirectory exists, the doc goes there (e.g., adding an
     "auth" doc in a project with a `services/` subtree -> `services/auth.md`).
   - If no subdirectory fits, place the doc at the level where the root
     `_index.md` lives.
   - When placing at the repo root (root-level mode), warn if the filename
     collides with conventional root files (`README.md`, `LICENSE.md`, etc.).

4. **Create the doc file.** Write `<target-dir>/<topic>.md` with the doc
   template (see below). Keep the template minimal — headers only, no TODO
   placeholders that accumulate as noise.

5. **Write the index description.** Ask the user: "Describe when Claude should
   read this doc. Format: `<domain nouns> — read when <task trigger>`"

   Validate the description against these quality criteria:
   - **Has a task trigger** — rejects generic descriptions without concrete
     triggers (e.g., "read when needed").
   - **Is scope-specific** — the description must indicate the doc's layer or
     scope (e.g., "API-layer auth" not just "auth") so the doc-traversal agent
     can distinguish it from similar docs in other parts of the tree.
   - **Uses discriminating keywords** — the nouns and triggers should
     differentiate this doc from nearby siblings and cousins. Before writing
     the description, read the sibling entries in the target `_index.md` and
     check for overlap. If another entry covers a related topic, ensure the
     new description highlights what makes *this* doc different.

   If the description fails any criterion, suggest an improved version.
   Examples of good vs. bad:
   - Bad: `authentication — read when working on auth`
   - Good: `API-layer auth: token validation, API keys, 401/403 responses — read when adding auth to endpoints or debugging API auth errors`
   - Bad: `deployment — read when deploying`
   - Good: `production deploys: release process, rollback procedures — read when cutting a release or rolling back a failed deploy`

6. **Update the local `_index.md`.** Add the entry to the `_index.md` of the
   directory where the file was placed. Only update the root CLAUDE.md docs
   section if the doc was placed at the top level of the tree. Confirm with
   the user before writing.

## Constraints

- Do not create the doc if the docs tree is not initialized. Check for
  `_index.md` in the target directory. Tell the user to run
  `/docs-kb:docs-bootstrap` first if missing.
- Warn if the target directory's `_index.md` would exceed 15 entries —
  suggest grouping into subdirectories with their own `_index.md` files.
- Warn if an existing doc would be a better home for the content.

## Doc File Template

```markdown
# [Topic Title]

[One to three sentences: what this doc covers and when to reference it.]

## [Primary Section]

[Content organized by task or concept. Use imperative sentences for rules.
Use code blocks for anything prescriptive.]

## See Also

- `docs/related-topic.md` — [brief reason to look there]

<!-- last-verified: YYYY-MM-DD -->
<!-- verify-when: src/path/to/relevant-dir/ -->
```

## Index Entry Format

```
<relative-path>|desc: <domain nouns>, <task-context nouns> — read when <concrete trigger>
```

Example: `docs/auth.md|desc: authentication, OAuth, session management — read when implementing login, signup, or token refresh`
