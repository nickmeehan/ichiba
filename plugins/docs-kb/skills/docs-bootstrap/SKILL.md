---
name: docs-bootstrap
description: >
  Initialize a docs/ progressive disclosure system for a project. Use when
  setting up docs for the first time, or when resetting a broken docs
  configuration. Creates _index.md, CLAUDE.md markers, and README — no
  skeleton doc files. Supports subfolder or repo-root placement.
---

# docs-bootstrap

Initialize a docs/ progressive disclosure system for this project.

## When to Use

- "set up docs for this project"
- "initialize docs"
- "bootstrap docs"
- "create a docs system"
- Resetting a broken docs configuration

## Allowed Tools

- `Bash(ls:*)`
- `Bash(cat:*)`
- `Bash(mkdir:*)`
- Read
- Write
- Edit
- Glob
- Grep
- AskUserQuestion

## Process

1. **Check prerequisites.** Read the current CLAUDE.md. If it already has
   `DOCS-INDEX-START`/`DOCS-INDEX-END` markers, warn that docs appear to be
   already initialized and ask whether to proceed.

2. **Ask where docs should live.** Present two options:
   - **A subfolder** (default `docs/`) — standard for most projects. Ask
     the user for the folder name; default to `docs/` if they don't specify.
   - **The repo root** — when the project IS the knowledge base and docs
     live across the entire repo (e.g., a personal OS, wiki, or monorepo
     where the repo root is the natural starting point)

   No hardcoded list of directory names — the user provides the name.
   After bootstrap, `find-docs-root.sh` discovers the docs root dynamically
   by finding the shallowest `_index.md` in the repo.

   If the user chooses root-level:
   - Skip creating a top-level directory (the root already exists)
   - Create `_index.md` at the repo root
   - Ask which existing subdirectories should be indexed, and create
     `_index.md` files inside each one
   - Skip `docs/README.md` (or create `README-docs.md` if user wants one)
   - CLAUDE.md template references `_index.md` instead of `docs/_index.md`

3. **Assess the project.** Read the project structure (package.json or
   equivalent, src/ directory listing, test configuration). Identify:
   - The language(s) and framework(s)
   - The test runner and test file locations
   - The build system and key commands
   - Whether there's an existing CLAUDE.md with instructions
   - Source directory names for lint script configuration

4. **Decide what belongs where.** For each piece of existing guidance in
   CLAUDE.md, ask: will Claude need this on more than 80% of tasks? If yes,
   it stays in CLAUDE.md. If no, it's a candidate for a docs/ file. Do NOT
   auto-migrate content — present the candidates and let the user decide
   per-section.

5. **Create the docs infrastructure.** If root-level mode (`.`):
   - Create `_index.md` at repo root (empty Contents section)
   - Create `_index.md` inside each subdirectory the user chose to index
   - Skip `docs/README.md` or offer `README-docs.md` as alternative
   - NO skeleton doc files

   Otherwise (subdirectory mode):
   - Create the docs directory with `_index.md` (empty Contents section)
   - `docs/README.md` explaining the system to human team members:
     what docs/ is for, that it's for Claude Code, how to add a doc,
     key conventions (no frontmatter, 200-line cap, `last-verified` footer)
   - NO skeleton doc files. The user creates their first doc when they
     actually hit friction. Docs created speculatively rot immediately.

6. **Update CLAUDE.md.** Add the docs index section with `DOCS-INDEX-START/END`
   markers. Enforce section ordering:
   1. Project name and description
   2. Quick Reference / commands
   3. Critical Rules
   4. Docs index
   5. Everything else
   Always ask the user to confirm before modifying CLAUDE.md.

7. **Report.** Show the user what was created. Emphasize: "Create your
   first doc when Claude makes a preventable mistake. Don't try to write
   everything now. Run `/docs-kb:docs-add <topic>` to
   create docs with the right format."

## Constraints

- Never create skeleton doc files. Create only the infrastructure
  (_index.md, README.md, CLAUDE.md markers).
- Always ask the user to confirm before modifying CLAUDE.md.
- If the existing CLAUDE.md is under 100 lines with no obvious need for docs/,
  suggest they may not need this yet and explain the threshold (>150-200 lines,
  distinct task domains, repeated agent failures). Recommend subdirectory
  CLAUDE.md files and @import as simpler alternatives.
- The docs directory MUST be configurable at bootstrap time.
  Default to `docs/`, accept any user-provided subfolder name,
  or support root-level for knowledge-base-style projects.
  No hardcoded directory name list — `find-docs-root.sh` discovers
  the docs root dynamically after bootstrap.

## CLAUDE.md Docs Section Template

```markdown
## Docs

Scan the index below on every turn. If an entry is relevant, read the file before responding.
Do not guess — retrieve first. For deeper topics, use the docs-kb:doc-traversal agent starting at `docs/_index.md`.

<!-- DOCS-INDEX-START -->
<!-- DO NOT REMOVE THESE MARKERS — used by the docs progressive disclosure plugin -->
<!-- DOCS-INDEX-END -->
```

## _index.md Template

```markdown
# Project Documentation

Documentation for [project name]. The doc-traversal agent reads this index
to find docs relevant to the current task.

## Contents

```

Entries use the format: `- \`filename.md\` — description. Read when trigger.`
