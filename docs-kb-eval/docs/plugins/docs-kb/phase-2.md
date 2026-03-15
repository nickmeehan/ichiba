# docs-kb Plugin — Phase 2: Maintenance & Quality Tooling

Phase 2 adds the ongoing doc health layer: semantic staleness detection, a discoverable audit skill, and a CI-ready lint script. Build this after Phase 1 is validated in real usage.

## Scope — 3 Files

| # | File | ~Lines | Purpose |
|---|------|--------|---------|
| 1 | `agents/doc-review.md` | ~30 | Audit docs for semantic staleness (code examples vs. reality) |
| 2 | `skills/docs-audit/SKILL.md` | ~25 | Run staleness audit via review agent |
| 3 | `scripts/lint-docs.sh` | ~100 | CI-ready lint with `_index.md` tree parsing and `verify-when` support |

## Component Specs

### Review Agent (`agents/doc-review.md`)

Audits the docs directory for semantic staleness — things the lint script can't catch because they require LLM reasoning.

**Process:**
1. Read every file in the docs directory recursively
2. Verify file paths referenced in backticks exist
3. Check code examples in fenced blocks against actual source files for divergence
4. Flag files with `last-verified` dates older than 90 days
5. Check every doc is referenced in an `_index.md` (orphan detection)
6. Check every `_index.md` entry points to a real file (broken index detection)

**Output:** Structured report with sections: Current (no issues), Needs Review, Broken References.

**Rules:** Report only — never modify files.

### Audit Skill (`skills/docs-audit/SKILL.md`)

Discoverable wrapper around the review agent. Named skills show up in skill listings — "just ask Claude to audit" is not discoverable for marketplace users.

**Process:**
1. Invoke the `doc-review` agent to scan all docs
2. Present results in a readable format
3. Suggest specific fixes for each issue type
4. Ask the user which issues to fix now

**Rules:** Do not auto-fix. Present and let the user decide.

### Lint Script (`scripts/lint-docs.sh`)

CI-ready structural staleness checker. Deterministic — no LLM needed.

**Checks:**
1. Every doc file is referenced in its parent `_index.md` (orphan detection)
2. Every `_index.md` entry points to a real file/directory (broken index)
3. `last-verified` dates older than configurable threshold (default 90 days)
4. `verify-when` paths with git commits since `last-verified`

**Key implementation details:**
- Uses `find-docs-root.sh` to locate the docs root dynamically
- When docs live at repo root, parses the `_index.md` tree to find registered docs (avoids globbing every `.md` in the repo)
- Configurable staleness threshold via `STALENESS_DAYS` env var
- Exit code 0 = clean, 1 = issues found

## Why Phase 2 Is Separate

These components aren't needed to use the progressive disclosure system — they're needed to **maintain** it over time. Users won't need audit/lint tooling until they've been using the system for a while and have docs that could go stale.

Phase 1 provides the complete read/write loop: bootstrap docs, create docs, and Claude navigates them. Phase 2 adds the feedback loop: detect when docs drift from reality.

## Dependencies on Phase 1

- `lint-docs.sh` calls `find-docs-root.sh` (Phase 1)
- `docs-audit` skill wraps `doc-review` agent (both Phase 2, but references Phase 1 conventions)
- All components assume the `_index.md` tree structure established by bootstrap

## Version Bump

When Phase 2 ships, bump to `1.1.0` (minor — new capabilities, no breaking changes) in both:
1. `plugins/docs-kb/.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`

Update the `components` object in `plugin.json` to reflect the new agent and skill.

## Source of Truth

Full specs for all Phase 2 components are in `implementation.md`:
- Review agent: Section 3.3
- Audit skill: Section 3.6
- Lint script: Section 3.7 (includes full bash source)
- Find-docs-root helper: Section 3.7.1 (already shipped in Phase 1)
