# docs-kb Plugin — Phase 1: Core Progressive Disclosure

Phase 1 delivers the minimum viable plugin: install, bootstrap, create docs, and have Claude navigate them automatically.

## Scope — 7 Files

| # | File | ~Lines | Purpose |
|---|------|--------|---------|
| 1 | `.claude-plugin/plugin.json` | ~25 | Plugin manifest with SessionStart hook registration |
| 2 | `agents/doc-traversal.md` | ~30 | Navigate doc trees with inclusion-biased matching and decision logging |
| 3 | `rules/scan-docs-index.md` | ~15 | Auto-trigger: scan docs index at task start, grep fallback |
| 4 | `scripts/find-docs-root.sh` | ~15 | BFS for shallowest `_index.md` — no hardcoded names or env vars |
| 5 | `scripts/install-rules.sh` | ~10 | SessionStart hook: symlinks `rules/` as `.claude/rules/docs-kb/` |
| 6 | `skills/docs-bootstrap/SKILL.md` | ~90 | First-time infrastructure setup, root-level support, no skeleton docs |
| 7 | `skills/docs-add/SKILL.md` | ~50 | Create new docs with tree-aware placement and conventions enforced |

## Component Specs

### Traversal Agent (`agents/doc-traversal.md`)

The core engine for projects with nested doc trees. For flat docs/ directories, the main agent reads docs directly.

- Reads `_index.md` routing tables at each directory level
- Matches entries against the current task description and activation triggers
- **Inclusion-biased**: reads uncertain matches rather than skipping them
- Caps returns at 7 docs, reports omissions transparently
- Outputs a decision log for description quality improvement
- Tracks visited paths for cycle detection

### Rule File (`rules/scan-docs-index.md`)

Delivered to `.claude/rules/docs-kb/` by the SessionStart hook. Loaded by Claude Code on every turn — survives context compaction.

- Scans CLAUDE.md docs index (between `DOCS-INDEX-START`/`DOCS-INDEX-END` markers)
- Delegates directory entries to the traversal agent
- Includes mid-task re-scan instruction
- Falls back to Grep search when no doc matches

### Helper Scripts

**`find-docs-root.sh`**: Breadth-first search from repo root for the shallowest `_index.md`. Checks depths 0-5, short-circuits on first match. No hardcoded directory names.

**`install-rules.sh`**: SessionStart hook script. Symlinks the plugin's `rules/` directory as `.claude/rules/docs-kb/`. Falls back to copy if symlink fails. Project's own `.claude/rules/` files are untouched.

### Bootstrap Skill (`skills/docs-bootstrap/SKILL.md`)

First-time setup for docs infrastructure:
1. Check for existing `DOCS-INDEX-START/END` markers
2. Ask where docs live (subfolder or repo root)
3. Assess project structure
4. Apply 80% rule for CLAUDE.md content migration candidates
5. Create `_index.md` and optional `README.md` — no skeleton docs
6. Update CLAUDE.md with docs index markers (user-confirmed)

### Docs-Add Skill (`skills/docs-add/SKILL.md`)

Convention-enforced doc creation:
1. Validate topic name (lowercase, kebab-case)
2. Check for duplicates in the `_index.md` tree
3. Tree-aware placement (finds best-fit subdirectory)
4. Create doc with template (title, sections, `last-verified`/`verify-when` footers)
5. Enforce situation-based descriptions ("read when" triggers, not topic labels)
6. Update local `_index.md` and optionally root CLAUDE.md

## Key Design Decisions

- **No skeleton docs.** Bootstrap creates infrastructure only. Docs created speculatively rot immediately.
- **Configurable docs directory.** Set at bootstrap time, discovered dynamically by `find-docs-root.sh` afterward.
- **Situation-based descriptions.** "Read when writing migrations" routes better than "database conventions".
- **Pragmatic redundancy.** 2-3 most critical rules should appear in both CLAUDE.md and the relevant doc for higher compliance.
- **Rules via symlink subdirectory.** Plugin owns `.claude/rules/docs-kb/`, project's own rules untouched. Updates flow through automatically.

## Verification

1. `./bin/validate-plugin.sh "plugins/docs-kb"` passes
2. All JSON files parse correctly
3. Shell scripts are executable and pass `bash -n` syntax check
4. Version `1.0.0` in both `plugin.json` and `marketplace.json`

## What's NOT in Phase 1

See `phase-2.md` for the deferred maintenance and quality tooling.
