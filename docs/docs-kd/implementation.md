# Plugin Plan: docs/ Progressive Disclosure for Claude Code

A distributable Claude Code plugin for the ichiba marketplace. Gives any project a working docs/ progressive disclosure system — install it, bootstrap your docs, and Claude navigates them automatically.

This plan synthesizes all prior research — `overview.md` (cross-industry patterns), `architecture.md` (system design), `contrarian-analysis.md` (failure modes and mitigations), `implementation-plan.md` (concrete specification), and `implementation.md` (condensed implementation guide). It was stress-tested by four critic reviews and then re-evaluated against the underlying research to ensure the critics' recommendations were actually supported by the evidence.

---

## 0. Who This Is For (And Who It Isn't)

**Use this when:** Your project has 8+ distinct documentation topics, your CLAUDE.md exceeds 150-200 lines, or Claude regularly makes preventable mistakes because it doesn't know project-specific conventions.

**Don't use this when:** Your CLAUDE.md is under 150 lines and working fine. A well-curated single CLAUDE.md with clear section headers is 80% as effective at 20% of the complexity. Subdirectory CLAUDE.md files (`.claude/rules/`, package-level CLAUDE.md) handle geographically-scoped conventions more reliably than routed docs. Start there.

**The honest tradeoff:** Progressive disclosure trades ~25-40% routing failure risk for token efficiency and scalability. For small projects (under 1,500 total lines of docs), eager loading via CLAUDE.md or `@import` is simpler and more reliable. This system earns its complexity at scale.

**Probability of improvement** (from research):
- CLAUDE.md under 150 lines: ~20% chance this helps. Likely adds friction.
- CLAUDE.md 150-500 lines: ~65% chance. Token savings are real, routing failures manageable.
- CLAUDE.md over 500 lines: ~85% chance. At this scale, monolithic files degrade performance through attention dilution.

---

## 1. What the Plugin Is

A self-contained package of Claude Code configuration files that, when installed from the ichiba marketplace into any project:

1. Teaches Claude how to discover and read a docs directory via an index in CLAUDE.md
2. Provides a traversal agent for navigating arbitrarily deep doc trees
3. Ships a rule file (symlinked into `.claude/rules/` via SessionStart hook) that triggers doc loading at the start of every task
4. Ships a bootstrapping skill that helps users create their initial docs infrastructure
5. Ships a skill for creating new docs with proper format and index registration
6. Ships a maintenance skill that audits docs for staleness
7. Provides a review agent for semantic staleness detection (code examples vs. actual code)
8. Ships a lint script for CI integration
9. Requires zero configuration for the common case (flat docs/) and supports deep nesting for large projects

### What It Is Not

- **Not a doc generator.** It does not auto-generate documentation from code. The research is clear: auto-generated docs are comprehensive but unfocused, describing what IS rather than what SHOULD BE. The plugin provides structure and tooling; humans write the content.
- **Not a replacement for CLAUDE.md.** It extends CLAUDE.md with a docs index section. The rest of CLAUDE.md (project description, quick reference, critical rules) remains user-authored.
- **Not an MCP server.** It uses Claude Code's native filesystem navigation and agent/skill/rule primitives. No external dependencies.

---

## 2. Plugin Anatomy — Directory Structure

The plugin is a self-contained directory that follows the Claude Code plugin format. All component directories (`agents/`, `skills/`, `scripts/`) live at the **plugin root**, not inside `.claude/`. Only the `plugin.json` manifest lives inside `.claude-plugin/`.

```
docs-kb/          # Plugin root (distributable unit)
├── .claude-plugin/
│   └── plugin.json                   # Plugin manifest + hooks definition
├── agents/
│   ├── doc-traversal.md              # Navigates the doc tree for complex lookups
│   └── doc-review.md                 # Audits docs for semantic staleness
├── rules/
│   └── scan-docs-index.md   # Rule file (delivered to .claude/rules/docs-kb/ by hook)
├── skills/
│   ├── docs-bootstrap/
│   │   └── SKILL.md                  # Skill: initialize docs for an existing project
│   ├── docs-add/
│   │   └── SKILL.md                  # Skill: create a new doc with conventions enforced
│   └── docs-audit/
│       └── SKILL.md                  # Skill: run the staleness audit
├── scripts/
│   ├── find-docs-root.sh             # Helper: locates root _index.md in the repo
│   ├── install-rules.sh              # SessionStart hook: symlinks rule file into project
│   └── lint-docs.sh                  # CI-ready staleness checker
├── README.md                         # Human-readable plugin overview
└── LICENSE
```

**10 files + README + LICENSE, ~390 lines of functional content.**

When installed, Claude Code copies this directory into the project's `.claude/plugins/` cache and auto-discovers the components. Agents become available as `docs-kb:doc-traversal`, skills as `/docs-kb:docs-bootstrap`, etc.

### How the Rule File Gets Loaded

Rule files live in `rules/` — following the standard naming convention for what they are. Claude Code doesn't currently auto-discover a `rules/` directory inside plugins, but the name is correct by convention. The `SessionStart` hook is what delivers them into the project.

The plugin uses a **`SessionStart` hook** defined in `plugin.json` that runs `scripts/install-rules.sh` on every session start. This script symlinks the plugin's `rules/` directory as a **subdirectory** inside the project's `.claude/rules/`:

```bash
#!/bin/bash
# install-rules.sh — Symlink plugin rules into project as a named subdirectory
# Creates .claude/rules/docs-kb/ → plugin's rules/ directory.
# The project's own .claude/rules/ files are untouched — this is an additive subdirectory.
mkdir -p .claude/rules
ln -sfn "${CLAUDE_PLUGIN_ROOT}/rules" .claude/rules/docs-kb 2>/dev/null || \
cp -r "${CLAUDE_PLUGIN_ROOT}/rules" .claude/rules/docs-kb
exit 0
```

This creates `.claude/rules/docs-kb/scan-docs-index.md` in the project. The plugin owns the entire `docs-kb/` subdirectory — the project's own rule files at `.claude/rules/*.md` are untouched. If additional rule files are added in future plugin versions, they appear automatically via the symlink. If Claude Code ever adds native `rules/` auto-discovery for plugins, the hook becomes a no-op and can be removed — the directory is already named correctly.

`${CLAUDE_PLUGIN_ROOT}` is set by Claude Code to the plugin's cached directory path. The symlink means rules always match the installed plugin version — updates flow through automatically.

### Why These Files

| File | Purpose | Research basis |
|------|---------|---------------|
| `agents/doc-traversal.md` | Agent that navigates `_index.md` routing tables at each level | Decoupling traversal from task execution eliminates the "lost agent" problem at depth (architecture.md, contrarian-analysis.md section 4). OpenAI's harness team uses this pattern across a million-line codebase. |
| `agents/doc-review.md` | Agent that audits docs for semantic staleness | OpenAI's garbage collection agents pattern (overview.md). The lint script catches structural staleness (broken paths); this catches semantic staleness (code examples that no longer match reality). Requires LLM reasoning — cannot be scripted. |
| `rules/scan-docs-index.md` | Rule file, delivered to `.claude/rules/docs-kb/` by SessionStart hook | Ensures Claude scans the docs index at task start. Without an explicit behavioral trigger, Claude treats the index as informational rather than actionable. Survives context compaction (rules are reloaded). Named `rules/` by convention — the hook delivers it. |
| `scripts/find-docs-root.sh` | Shared helper: locates root `_index.md` | Breadth-first search from repo root for the shallowest `_index.md`. Short-circuits on first match. No hardcoded directory names or env vars. Used by lint script and available to skills as a fallback. Single source of truth for "where does the doc tree start?" |
| `scripts/install-rules.sh` | SessionStart hook script | Symlinks plugin's `rules/` directory as `.claude/rules/docs-kb/`. Plugin owns the subdirectory; project's own rules are untouched. Falls back to copy if symlink fails. |
| `skills/docs-bootstrap/SKILL.md` | User-invocable skill for first-time setup | Guides setup: creates docs directory, `_index.md`, CLAUDE.md markers, README. The research emphasizes iterative adoption from real friction (implementation.md, overview.md — Hashimoto, HumanLayer, AI Hero all converge here). |
| `skills/docs-add/SKILL.md` | User-invocable skill for creating new docs | Enforces conventions that marketplace users don't know yet: description quality, naming, format, size caps, duplicate detection. Plugin authors know the conventions; plugin users need guardrails. |
| `skills/docs-audit/SKILL.md` | User-invocable skill for running staleness audit | Wraps the review agent in a discoverable interface. Named skills are findable; "just ask Claude to audit" assumes users know the prompt. |
| `.claude-plugin/plugin.json` | Plugin manifest + hooks for Claude Code / ichiba | Required for plugin discovery, marketplace distribution, and hook registration. |
| `scripts/lint-docs.sh` | CI script | The only component that catches staleness no human convention can — automated broken reference detection, orphan detection, `verify-when` path change detection. |

### Design Philosophy: Complete Product, Not Minimal Template

The critic-driven rewrite cut this to 4 files on the principle that "conventions matter more than tooling." That's true for the plugin author but wrong for the marketplace user. A marketplace plugin needs to provide a complete, polished experience:

- **`docs-add`** was cut as "over-engineering a 30-second task." But the 30-second task assumes you know the naming conventions, description format, size caps, and duplicate detection workflow. Plugin users don't. The skill IS the onboarding.
- **`docs-audit`** was cut as "a wrapper around a wrapper." But discoverable named skills are how users learn what's possible. "Just ask Claude" is not a UX — it's an assumption that users will read the plan document.
- **`doc-review`** was cut because "users can do this ad hoc." True, but the lint script only catches structural staleness. Semantic staleness (a code example that no longer matches the actual implementation) requires LLM reasoning. The review agent is the only component that does this.
- **`plugin.json`** was cut because "the marketplace doesn't exist." We're building the marketplace.

---

## 3. Core Component Specifications

### 3.1 The Traversal Agent

**File:** `agents/doc-traversal.md` (at plugin root)

This is the most critical component for projects with nested doc trees. For flat docs/ directories, the main agent reads docs directly. After plugin installation, Claude Code discovers this as `docs-kb:doc-traversal`.

```markdown
You navigate the docs directory tree to find documentation relevant to a given task.

## Process

1. Read the top-level `_index.md` in the docs directory to see topics.
2. Match the task description against each entry's description and activation trigger.
3. For matching leaf files (*.md entries), read them and include their content in your response.
4. For matching directories (*/ entries), read their `_index.md` and repeat from step 2.
5. Continue descending until you reach leaf docs in every matching branch.
6. Return: the file paths and content of all relevant leaf docs.

## Rules

- Always start at the docs directory's `_index.md`. If it does not exist, report that docs are not initialized. The docs directory may be the repo root (`.`) — in that case, `_index.md` lives at the repo root. Path handling is unchanged; paths are always relative to the repo root.
- **Err on the side of inclusion.** If you are uncertain whether an entry is relevant, read it. The cost of reading an irrelevant 200-line doc is far lower than the cost of missing a relevant one (incorrect code).
- Return the content of leaf docs, not intermediate indexes.
- If more than 7 leaf docs match, return the 7 most relevant and **report what was omitted**: "Also matched but not returned: [list of paths]." The main agent can request specific omitted docs if needed.
- Use paths relative to the repo root (e.g., `docs/architecture/services/auth.md`).
- Track visited paths. If you detect a cycle, stop and report it.
- Keep your response concise. Summarize each doc in 2-3 sentences, then include the full content.
- **Output your decision log**: list which entries you considered, which you matched, and which you skipped with a brief reason. This enables description quality improvement.
```

**Key design decisions:**

- **Inclusion-biased matching.** Silent misrouting (false negatives) is the most dangerous failure mode identified in the contrarian analysis. Reading an extra doc costs 200 lines of context; missing a relevant doc causes incorrect code.
- **7-doc return limit with transparency.** When the cap is hit, the agent reports what it dropped. The main agent can request specific omitted docs. No silent information loss.
- **Decision logging.** When routing fails, users need to see WHY to improve descriptions. This feedback loop was missing from all prior designs.
- **Cycle detection.** The contrarian analysis identified circular references as a failure mode.

### 3.2 The Progressive Disclosure Rule

**File:** `rules/scan-docs-index.md` (at plugin root, delivered to `.claude/rules/docs-kb/` by SessionStart hook)

This rule file is loaded by Claude Code on every turn, ensuring doc scanning happens automatically without relying on CLAUDE.md alone. The descriptive filename (`scan-docs-index`) says what the rule does, not which plugin it came from — leaving room for additional rule files in future versions.

```markdown
At the start of every task, scan the docs index in CLAUDE.md (between the
`DOCS-INDEX-START` and `DOCS-INDEX-END` markers). If any entry's description
matches the current task, read that file before starting work.

For entries that point to directories (ending with `/`), use the docs-kb:doc-traversal
agent to navigate the subtree rather than exploring manually.

If the task evolves and you realize you need a doc you didn't initially load,
read it at that point. Do not wait until the end.

If no doc in the index matches the current task, search for similar patterns
in the codebase using Grep before writing new code. Do not fall back to
training data for project-specific conventions.
```

**How it gets into `.claude/rules/`:** The plugin defines a `SessionStart` hook in `plugin.json` that runs `scripts/install-rules.sh`. This script symlinks the plugin's `rules/` directory as `.claude/rules/docs-kb/`, creating `.claude/rules/docs-kb/scan-docs-index.md`. The plugin owns its named subdirectory — the project's own `.claude/rules/*.md` files are untouched. Updates to the plugin automatically update all rules in the subdirectory via the symlink.

**Key design decisions:**

- **Separate rule file, not just CLAUDE.md.** Rules in `.claude/rules/` are reloaded by Claude Code on context compaction. CLAUDE.md instructions can get compressed away in long sessions. The rule file provides a reliable behavioral trigger that survives the full session lifecycle.
- **SessionStart hook for delivery.** Plugins can't directly write to `.claude/rules/`, but a hook script can create symlinks on each session start. This is the standard mechanism for plugins that need project-level rules.
- **Grep fallback instruction.** Per the contrarian analysis's hybrid approach: when no doc matches, Claude should search the codebase for patterns rather than improvising from training data. Zero cost, high value.
- **Marker-based index location.** `DOCS-INDEX-START/END` markers let the rule and tooling find the index programmatically.
- **Mid-task re-scan instruction.** Multi-step tasks where relevance emerges late are a known failure mode.
- **Directory detection heuristic.** Entries ending with `/` are subtrees; everything else is a leaf.

### 3.3 The Review Agent

**File:** `agents/doc-review.md` (at plugin root)

```markdown
You are a documentation review agent. Audit the docs directory for staleness.

## Process

1. Read every file in the docs directory recursively.
2. For every file path referenced in backticks (e.g., `src/lib/auth.ts`), verify
   the file exists. Report broken references.
3. For every code example in a fenced code block, find the referenced source file
   and check whether the example still reflects the actual implementation pattern.
   Report significant divergences.
4. Check for a `<!-- last-verified: YYYY-MM-DD -->` comment. If it is older than
   90 days, flag the file as due for review.
5. Check that every doc file is referenced in the CLAUDE.md docs index.
   Report orphaned docs.
6. Check that every entry in the CLAUDE.md docs index points to a file that exists.
   Report broken index entries.

## Output Format

Return a structured report:

### Current (no issues)
- list of files with no problems

### Needs Review
- file: issue description

### Broken References
- file: referenced path → does not exist

## Rules

- Do not modify any files. Report only.
- Read files using the Read tool, not Bash commands.
- If the docs directory does not exist or is empty, report that and stop.
```

**Why this exists alongside the lint script:** The lint script catches structural issues deterministically in CI: broken file paths, orphaned docs, stale dates, changed `verify-when` paths. The review agent catches semantic issues that require LLM reasoning: code examples that no longer match the actual implementation, guidance that contradicts current codebase patterns. These are complementary — the lint script runs automatically, the review agent runs on demand.

### 3.4 The Bootstrap Skill

**File:** `skills/docs-bootstrap/SKILL.md` (at plugin root)

```markdown
# docs-bootstrap

Initialize a docs/ progressive disclosure system for this project.

## When to Use

Use this skill when setting up docs for the first time in a project, or when
resetting a broken docs configuration.

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
```

**Key design decisions:**

- **No skeleton docs.** The research and the critics both agree: docs created speculatively rot immediately. Bootstrap creates infrastructure only.
- **Configurable docs directory.** Many projects already use `docs/` for user-facing documentation. The user picks the location at bootstrap; `find-docs-root.sh` discovers it dynamically afterward via breadth-first search for the shallowest `_index.md`. No env var or config file to drift.
- **No auto-migration.** CLAUDE.md changes are per-section, user-confirmed. Developers care deeply about their CLAUDE.md.
- **80% rule.** If Claude needs something on >80% of tasks, it stays in CLAUDE.md (always loaded, higher reliability).

### 3.5 The Add-Doc Skill

**File:** `skills/docs-add/SKILL.md` (at plugin root)

```markdown
# docs-add

Create a new doc file and register it in the docs index.

## When to Use

Use when adding a new documentation file to the docs tree.

## Arguments

- `topic` (required): The topic name for the doc (e.g., "auth", "database", "deploy")

## Process

1. **Validate the topic name.** Must be lowercase, single-word or kebab-case.
   If not, suggest a corrected name.

2. **Check for duplicates.** Read the `_index.md` tree starting from the root
   (found via the CLAUDE.md doc-traversal agent reference). If a doc already
   covers this topic, warn the user and suggest updating the existing doc.

3. **Determine the correct location.** Traverse the `_index.md` tree to find
   which subdirectory best fits the new doc's topic:
   - If a matching subdirectory exists, the doc goes there (e.g., adding an
     "auth" doc in a project with a `services/` subtree → `services/auth.md`).
   - If no subdirectory fits, place the doc at the level where the root
     `_index.md` lives.
   - When placing at the repo root (root-level mode), warn if the filename
     collides with conventional root files (`README.md`, `LICENSE.md`, etc.).

4. **Create the doc file.** Write `<target-dir>/<topic>.md` with the doc
   template: title, summary placeholder, section headers, See Also,
   `last-verified` and `verify-when` footers. Keep the template minimal —
   headers only, no TODO placeholders that accumulate as noise.

5. **Write the index description.** Ask the user: "Describe when Claude should
   read this doc. Format: `<domain nouns> — read when <task trigger>`"
   If the description is too vague (no task trigger, generic nouns only),
   suggest an improvement using situation-based language.

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
```

**Why this exists as a skill:** Plugin users don't know the conventions. The skill enforces naming format, description quality (situation-based triggers, not topic labels), duplicate detection, and index consistency. The plugin author can create docs in 30 seconds; the marketplace user needs guardrails.

### 3.6 The Audit Skill

**File:** `skills/docs-audit/SKILL.md` (at plugin root)

```markdown
# docs-audit

Run a staleness audit on all documentation in docs/.

## When to Use

Use periodically (recommended quarterly) or when suspecting docs are out of date.

## Process

1. Invoke the `doc-review` agent to scan all docs.
2. Present the results to the user in a readable format.
3. For each issue found, suggest a specific fix:
   - Broken reference → "Update the path or remove the reference"
   - Stale code example → "Compare against the current implementation and update"
   - Stale date → "Review this doc and update the last-verified date"
   - Orphaned doc → "Add to CLAUDE.md index or delete if no longer needed"
   - Missing doc → "Create the file or remove the index entry"
4. Ask the user which issues to fix now.

## Constraints

- Do not auto-fix issues. Present them and let the user decide.
- If no issues are found, report that docs are healthy.
```

**Why this exists as a skill:** Discoverability. Users who installed the plugin from ichiba need to know this capability exists. A named skill shows up in skill listings. "Just ask Claude to audit" is not discoverable — it assumes the user read the plan document.

### 3.7 The Lint Script

**File:** `scripts/lint-docs.sh` (at plugin root)

```bash
#!/bin/bash
# lint-docs.sh — CI-ready staleness checker for docs/ progressive disclosure.
# Checks five things:
#   1. File paths referenced in docs actually exist
#   2. Every doc file is referenced in an _index.md
#   3. Every reference in _index.md files points to a real file
#   4. last-verified dates older than STALENESS_DAYS
#   5. verify-when paths with changes since last-verified
#
# Exit code: 0 = clean, 1 = issues found

set -euo pipefail
shopt -s globstar nullglob

# --- Configuration ---
STALENESS_DAYS="${STALENESS_DAYS:-90}"
# ---

# Locate the docs root dynamically (no env var — find-docs-root.sh does breadth-first search)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="$(bash "$SCRIPT_DIR/find-docs-root.sh")" || {
    echo "No _index.md found. Run /docs-kb:docs-bootstrap to initialize docs."
    exit 1
}

# Files to skip when DOCS_DIR is the repo root
ROOT_SKIP_FILES="CLAUDE.md README.md LICENSE.md CONTRIBUTING.md CHANGELOG.md"

# Build the list of doc files to lint.
# When DOCS_DIR is ".", globbing would match every .md in the repo.
# Instead, recursively parse the _index.md tree to find registered doc files.
collect_docs_from_index() {
    local index_dir="$1"
    local index_file="$index_dir/_index.md"
    [ -f "$index_file" ] || return 0

    # Extract entries: `filename.md` (leaf) or `dirname/` (subtree)
    while IFS= read -r entry; do
        if [[ "$entry" == */ ]]; then
            # Subdirectory — recurse into its _index.md
            local subdir="$index_dir/${entry%/}"
            [ -d "$subdir" ] && collect_docs_from_index "$subdir"
        elif [[ "$entry" == *.md ]]; then
            local filepath="$index_dir/$entry"
            [ -f "$filepath" ] && echo "$filepath"
        fi
    done < <(grep -oE '`[a-zA-Z0-9_./-]+(/|\.md)`' "$index_file" 2>/dev/null | tr -d '`')
}

doc_files=()
if [ "$DOCS_DIR" = "." ]; then
    while IFS= read -r f; do
        doc_files+=("$f")
    done < <(collect_docs_from_index ".")
else
    for doc in "$DOCS_DIR"/*.md "$DOCS_DIR"/**/*.md; do
        [ -f "$doc" ] || continue
        basename=$(basename "$doc")
        [ "$basename" = "_index.md" ] && continue
        [ "$basename" = "README.md" ] && continue
        doc_files+=("$doc")
    done
fi

errors=0

# 1. Check that every doc file is referenced in an _index.md
# For each doc, check that its parent directory's _index.md references it
for doc in "${doc_files[@]}"; do
    parent_dir=$(dirname "$doc")
    index_file="$parent_dir/_index.md"
    basename=$(basename "$doc")
    if [ -f "$index_file" ]; then
        if ! grep -q "$basename" "$index_file" 2>/dev/null; then
            echo "ORPHAN: $doc exists but is not referenced in $index_file"
            ((errors++)) || true
        fi
    fi
done

# 2. Check that every reference in _index.md files points to a real file
# Walk all _index.md files in the docs tree
find_index_files() {
    if [ "$DOCS_DIR" = "." ]; then
        # Start from root, follow the tree
        find . -name "_index.md" -not -path "./.git/*" -not -path "./.claude/*"
    else
        find "$DOCS_DIR" -name "_index.md"
    fi
}
while IFS= read -r index_file; do
    index_dir=$(dirname "$index_file")
    while IFS= read -r entry; do
        if [[ "$entry" == */ ]]; then
            target="$index_dir/${entry%/}"
            if [ ! -d "$target" ]; then
                echo "BROKEN INDEX: $index_file references $entry which does not exist"
                ((errors++)) || true
            fi
        elif [[ "$entry" == *.md ]]; then
            target="$index_dir/$entry"
            if [ ! -f "$target" ]; then
                echo "BROKEN INDEX: $index_file references $entry which does not exist"
                ((errors++)) || true
            fi
        fi
    done < <(grep -oE '`[a-zA-Z0-9_./-]+(/|\.md)`' "$index_file" 2>/dev/null | tr -d '`')
done < <(find_index_files)

# 3. Check last-verified dates for staleness
cutoff_date=$(date -d "$STALENESS_DAYS days ago" +%Y-%m-%d 2>/dev/null || date -v-${STALENESS_DAYS}d +%Y-%m-%d 2>/dev/null || echo "")
if [ -n "$cutoff_date" ]; then
    for doc in "${doc_files[@]}"; do
        verified_date=$(grep -oE 'last-verified: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$doc" 2>/dev/null | head -1 | cut -d' ' -f2)
        if [ -z "$verified_date" ]; then
            echo "NO DATE: $doc has no <!-- last-verified: YYYY-MM-DD --> comment"
            ((errors++)) || true
        elif [[ "$verified_date" < "$cutoff_date" ]]; then
            echo "STALE: $doc last verified $verified_date (>${STALENESS_DAYS} days ago)"
            ((errors++)) || true
        fi
    done
fi

# 4. Check verify-when paths for changes since last-verified
for doc in "${doc_files[@]}"; do
    verified_date=$(grep -oE 'last-verified: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$doc" 2>/dev/null | head -1 | cut -d' ' -f2)
    verify_paths=$(grep -oE 'verify-when: .+' "$doc" 2>/dev/null | head -1 | sed 's/verify-when: //')
    if [ -n "$verified_date" ] && [ -n "$verify_paths" ]; then
        for vpath in $verify_paths; do
            if git log --since="$verified_date" --oneline -- "$vpath" 2>/dev/null | head -1 | grep -q .; then
                echo "CHANGED: $doc — watched path $vpath has changes since $verified_date"
                ((errors++)) || true
            fi
        done
    fi
done

if [ "$errors" -gt 0 ]; then
    echo ""
    echo "$errors issue(s) found."
    exit 1
else
    echo "All docs references are valid."
    exit 0
fi
```

### 3.7.1 The Docs Root Helper

**File:** `scripts/find-docs-root.sh` (at plugin root)

A shared helper that locates the root of the docs `_index.md` tree. Does a breadth-first search from the repo root — checks depth 0 first (repo root), then depth 1, and so on. Short-circuits on first match via `find -print -quit`, so it returns in milliseconds for typical repos. No hardcoded directory names, no environment variables. Sourced by the lint script and available to skills as a fallback.

```bash
#!/bin/bash
# find-docs-root.sh — Locate the root _index.md in the repo.
# Breadth-first search: finds the shallowest _index.md starting from repo root.
# Short-circuits at first match. Returns its containing directory.
# Usage: DOCS_DIR="$(bash find-docs-root.sh)"

set -euo pipefail

for depth in 0 1 2 3 4 5; do
    result=$(find . -mindepth "$depth" -maxdepth "$depth" -name "_index.md" \
             -not -path "./.git/*" -not -path "./.claude/*" -not -path "./node_modules/*" \
             -print -quit 2>/dev/null)
    if [ -n "$result" ]; then
        dirname "$result"
        exit 0
    fi
done

# Not found
echo "Docs not initialized: no _index.md found within 5 levels of repo root." >&2
exit 1
```

### 3.8 The Plugin Manifest

**File:** `.claude-plugin/plugin.json` (only file inside `.claude-plugin/`)

Claude Code plugins use a JSON manifest for discovery, metadata, and hook registration.

```json
{
  "name": "docs-kb",
  "version": "1.0.0",
  "description": "Progressive disclosure documentation system. Gives any project a docs/ directory that Claude navigates automatically based on task relevance.",
  "author": {
    "name": "TODO"
  },
  "license": "MIT",
  "keywords": [
    "documentation",
    "progressive-disclosure",
    "context-management",
    "claude-code"
  ],
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/install-rules.sh"
          }
        ]
      }
    ]
  }
}
```

The `hooks` section registers `scripts/install-rules.sh` to run on every `SessionStart` event. This symlinks the plugin's `rules/` directory as `.claude/rules/docs-kb/`, ensuring the rule files are available to Claude Code. The `${CLAUDE_PLUGIN_ROOT}` variable is set by Claude Code to the plugin's installation path.

Claude Code auto-discovers `agents/`, `skills/`, and `scripts/` from their default locations at the plugin root — no explicit path configuration needed.

**Key design decisions:**

- **JSON, not markdown.** Claude Code plugins use `.claude-plugin/plugin.json` — this is the standard format.
- **Hooks inline in manifest.** Defining the `SessionStart` hook directly in `plugin.json` keeps the plugin self-describing — no separate `hooks/hooks.json` file needed.
- **`${CLAUDE_PLUGIN_ROOT}` for portable paths.** Plugins are cached in `.claude/plugins/`, so hardcoded paths would break. The environment variable resolves to the actual cached directory.
- **Subdirectory symlink.** The hook symlinks the plugin's `rules/` directory as `.claude/rules/docs-kb/`. The plugin owns its named subdirectory — project-level rules at `.claude/rules/*.md` are untouched. Updates to the plugin flow through automatically. Future versions can add rule files to `rules/` without changing the hook. If Claude Code ever adds native `rules/` auto-discovery for plugins, the hook becomes a no-op.

---

## 4. The CLAUDE.md Integration Pattern

The plugin modifies CLAUDE.md by adding a docs index section. It does not replace or overwrite the rest of CLAUDE.md. The section uses markers for programmatic access.

### What Gets Added

```markdown
## Docs

Scan the index below on every turn. If an entry is relevant, read the file before responding.
Do not guess — retrieve first. For deeper topics, use the docs-kb:doc-traversal agent starting at `docs/_index.md`.

<!-- DOCS-INDEX-START -->
<!-- DO NOT REMOVE THESE MARKERS — used by the docs progressive disclosure plugin -->
docs/architecture.md|desc: system design, component boundaries, data flow — read when adding features or working across module boundaries
docs/conventions.md|desc: code style, naming, file structure, patterns — read when writing new files or refactoring
docs/testing.md|desc: test framework, patterns, file locations — read when writing or debugging tests
<!-- DOCS-INDEX-END -->
```

### Index Entry Format

Each entry follows a strict format for both human readability and tool parsability:

```
<relative-path>|desc: <domain nouns>, <task-context nouns> — read when <concrete trigger>
```

**Components:**
- **Path**: Relative to repo root. Leaf files end in `.md`. Subtrees end in `/`.
- **Separator**: `|desc: ` — the pipe-desc pattern enables reliable parsing.
- **Description**: Two parts joined by an em dash:
  1. Domain nouns — what the doc contains (3-6 words)
  2. Activation trigger — when Claude should read it (starts with "read when")

**Why situation-based descriptions:** The contrarian analysis found that topic-based descriptions ("database conventions") route poorly because they don't match task vocabulary. Situation-based descriptions ("read when writing migrations or adding tables") name the actions the agent is performing and route more reliably.

### Placement in CLAUDE.md

The docs section should go after Quick Reference and Critical Rules but before any project-specific sections. Position matters — instructions at the top of CLAUDE.md have higher compliance. The hierarchy:

1. Project name and description (2-3 lines)
2. Quick Reference / commands (5-8 lines)
3. Critical Rules (3-7 lines)
4. **Docs index** (the plugin's section)
5. Everything else

### Pragmatic Redundancy

The contrarian analysis found that rules appearing in both CLAUDE.md AND in the relevant doc have higher compliance than rules in only one place. For your 2-3 most critical rules (the ones where violation causes real damage), put them in both CLAUDE.md's Critical Rules section and the relevant doc file.

---

## 5. The _index.md Standard

Every directory in the doc tree has an `_index.md`. This is the traversal agent's routing table.

### Top-Level Template

```markdown
# Project Documentation

Documentation for [project name]. The doc-traversal agent reads this index
to find docs relevant to the current task.

## Contents

- `architecture.md` — system design, component boundaries, data flow. Read when adding features or working across modules.
- `conventions.md` — code style, naming, file structure. Read when writing new files or refactoring.
- `testing.md` — test framework, patterns, file locations. Read when writing or debugging tests.
```

### Subdirectory Template

```markdown
# [Topic Name]

[One-sentence description of what this subtree covers and when to descend into it.]

## Contents

- `overview.md` — [description]. Start here.
- `subtopic-a.md` — [description]. Read when [trigger].
- `subtopic-b.md` — [description]. Read when [trigger].
- `deeper-subtree/` — [description]. Descend when [trigger].
```

### Conventions

1. **Leaf files** get `.md` suffix in the listing. The traversal agent reads them directly.
2. **Subdirectories** get trailing `/`. The traversal agent descends into their `_index.md`.
3. **Every entry has a description** with an activation trigger, same format as CLAUDE.md.
4. **"Start here"** marker on the default/overview file helps the traversal agent prioritize.
5. **10-30 lines** per `_index.md`. If longer, the directory has too many children — nest further.
6. **Nesting threshold: 12+ entries.** When a flat directory exceeds 12 files, group related docs into subdirectories.

---

## 6. Doc File Standard

Every leaf doc file follows a consistent structure so Claude can predict where information lives.

### Template

```markdown
# [Topic Title]

[One to three sentences: what this doc covers and when to reference it.
This summary helps Claude verify it loaded the right doc.]

## [Primary Section]

[Content organized by task or concept. Use imperative sentences for rules.
Use code blocks for anything prescriptive.]

<!-- source: src/path/to/file.ts:42-58 -->
```[language]
// Example code that Claude should follow as a pattern
```

## [Secondary Section]

[Additional content. If this section could stand alone as its own doc,
consider splitting it out.]

## See Also

- `docs/related-topic.md` — [brief reason to look there]
- `src/path/to/key-file.ts` — [what this file implements]

<!-- last-verified: YYYY-MM-DD -->
<!-- verify-when: src/path/to/relevant-dir/ -->
```

### Hard Rules for Doc Content

1. **Lead with the most important information.** Claude's attention to instructions degrades with document length. Put hard rules in the first 30 lines.
2. **Use imperative sentences for rules.** "Use `snake_case` for database columns." Not "We typically prefer..."
3. **Use MUST/NEVER/ALWAYS for hard requirements.** Reserve these for rules where violation causes real damage.
4. **Include source file paths.** Point to where patterns are implemented. Creates verifiable links for the lint script.
5. **Annotate code blocks with source references.** Use `<!-- source: path:lines -->` above code blocks so the review agent can verify they still match.
6. **Use code blocks for prescriptive patterns.** Claude copies patterns from code blocks more reliably than from prose.
7. **Stay under 200 lines.** Soft cap. If unavoidable, add a "Quick Reference" section at the top and structure with `##` headings.
8. **Hard cap at 500 lines.** Per Anthropic's guidance for skills. Any doc exceeding this must be split.
9. **No YAML frontmatter.** Claude doesn't use it. It adds noise.
10. **No table of contents.** Claude reads the whole file or greps for sections. A TOC wastes lines.
11. **End with `<!-- last-verified: YYYY-MM-DD -->`** for staleness tracking.
12. **Add `<!-- verify-when: <paths> -->`** listing source paths that, when changed, mean this doc needs review.

### What NOT to Write

1. **Do not describe what code does.** Describe what the developer (or Claude) should do differently from what they would guess.
2. **Do not document obvious patterns.** If the codebase demonstrates the pattern consistently, a doc adds nothing. Document the exceptions.
3. **Do not write history.** Write current rules. If Claude needs to know why, one sentence of rationale, not a paragraph.

---

## 7. Installation and Distribution

### How Claude Code Plugins Install

Claude Code plugins are self-contained directories. When installed, the entire plugin directory is copied into the project's `.claude/plugins/` cache. Claude Code auto-discovers the plugin's components (`agents/`, `skills/`, `scripts/`) from within that cached directory. Components are namespaced by the plugin name — e.g., `/docs-kb:docs-bootstrap`.

The plugin's files do NOT get scattered into the project's `.claude/agents/`, `.claude/skills/`, etc. They stay together inside the plugin directory.

### Primary: ichiba Marketplace

The plugin is designed for distribution through the ichiba marketplace. The `.claude-plugin/plugin.json` manifest provides the metadata ichiba needs to display and manage the plugin.

**Install flow:**
1. User finds the plugin on ichiba
2. User runs `/plugin install docs-kb` in Claude Code
3. Claude Code copies the plugin directory into `.claude/plugins/` cache
4. Plugin agents and skills become available (namespaced by plugin name)
5. User runs `/docs-kb:docs-bootstrap` to initialize their docs

**Uninstall flow:**
1. User runs `/plugin uninstall docs-kb`
2. Claude Code removes the cached plugin directory
3. User-written docs/ content is NOT affected
4. User manually removes the DOCS-INDEX section from CLAUDE.md

**Upgrade flow:**
1. New version published to ichiba
2. User updates via `/plugin update docs-kb`
3. Claude Code replaces the cached plugin directory with the new version

### Fallback: Local Directory

For development or distribution without ichiba:

```bash
# Install from a local directory
claude --plugin-dir ./path/to/docs-kb

# Or add to project settings
# In .claude/settings.json:
{
  "enabledPlugins": ["./path/to/docs-kb"]
}
```

### Fallback: Git Repository

The plugin directory can be hosted as a Git repository and installed directly:

```bash
# Users add the marketplace that hosts the plugin
/plugin add-marketplace <marketplace-url>

# Then install
/plugin install docs-kb
```

### For Monorepo Distribution

- Install the plugin once at the repo root
- Each package can have its own docs directory with its own `_index.md`
- The root CLAUDE.md points to package-level doc trees
- Each package's CLAUDE.md (auto-discovered by Claude Code) indexes its own docs

---

## 8. Complementary Patterns (Not Part of the Plugin)

The plugin handles docs/ progressive disclosure. These complementary patterns handle adjacent concerns and should be adopted alongside it:

### Subdirectory CLAUDE.md Files

For area-specific conventions that are geographically scoped (frontend/, backend/, infra/), use subdirectory CLAUDE.md files rather than docs/ entries. Claude Code auto-loads these when working in the directory — no routing needed, no description to get wrong, 100% reliable.

Use docs/ for cross-cutting concerns. Use subdirectory CLAUDE.md for directory-scoped rules.

### PR Checklist for Doc Maintenance

The single highest-leverage maintenance mechanism. Add to your PR template:

```markdown
## Checklist
- [ ] If this PR changes a code pattern or convention, I updated the relevant docs/ file
```

Prevention beats detection. PR-time doc updates are primary; quarterly audits via `/docs-kb:docs-audit` are secondary.

### The `verify-when` Workflow

Each doc can declare which source paths it depends on:

```markdown
<!-- verify-when: src/db/ src/models/ prisma/ -->
```

The lint script checks whether those paths have git commits newer than `last-verified`. This bridges the gap between structural staleness (broken file paths) and semantic staleness (code changed behavior but files still exist).

---

## 9. Configuration and Customization

### Zero-Config Defaults

| Setting | Default | Rationale |
|---------|---------|-----------|
| Max docs returned by traversal agent | 7 | Prevents context bloat. Reports omissions transparently. |
| Staleness threshold | 90 days | Balances freshness vs. maintenance burden. Configurable via `STALENESS_DAYS`. |
| Doc file size soft cap | 200 lines | Long enough to be useful, short enough for full attention. |
| Index format | `path\|desc:` | Readable by Claude, parsable by tools. |
| Nesting threshold | 12+ files in a directory | Below this, flat is simpler. |
| Docs directory | `docs/` | Configurable at bootstrap time. Any subfolder name or root-level. Discovered dynamically by `find-docs-root.sh` (breadth-first search for shallowest `_index.md`) — no env var needed. |

### What Users Can Customize

1. **Index descriptions.** Highest-leverage customization. The traversal agent's decision log helps identify poor descriptions.
2. **Doc content.** The plugin provides structure; users provide knowledge.
3. **Docs directory name.** Set at bootstrap time. Any subfolder or root-level. Discovered dynamically afterward — no configuration to maintain.
4. **Lint script source directories.** Configured at bootstrap, editable afterward.
5. **Staleness threshold.** Set `STALENESS_DAYS` environment variable.
6. **Traversal agent doc limit.** Power users can edit the 7-doc limit.
7. **Nesting structure.** Starts flat. Users add subdirectories with `_index.md` files as docs grow.

### What Users Should NOT Customize

1. **The `_index.md` convention.** Changing the routing table filename breaks the traversal agent.
2. **The `DOCS-INDEX-START/END` markers.** Changing these breaks the lint script and docs-add skill.
3. **The rule directory.** `.claude/rules/docs-kb/` is symlinked from the plugin. Do not delete it, modify its contents, or replace the symlink with a local copy (updates would stop flowing). Add project-specific rules at `.claude/rules/*.md` instead.

---

## 10. Failure Modes and Mitigations

### Failure: Agent doesn't read a doc it should have

**Cause:** Vague description, vocabulary mismatch between task and description.

**Mitigation:**
- Traversal agent errs on the side of inclusion (reads uncertain matches)
- Traversal agent outputs a decision log for description improvement
- Rule file includes mid-task re-scan and grep fallback
- Index instruction uses the strong trigger "Do not guess — retrieve first"
- Pragmatic redundancy: 2-3 most critical rules in both CLAUDE.md and the relevant doc

### Failure: Agent reads too many docs

**Cause:** Overly broad descriptions, too many index entries.

**Mitigation:**
- Traversal agent caps returns at 7 docs with transparent omission reporting
- The `/docs-kb:docs-add` skill warns when index exceeds 15 entries
- The 12-entry nesting threshold prevents flat indexes from growing unbounded

### Failure: Docs go stale

**Cause:** Code changes without corresponding doc updates.

**Mitigation (layered):**
1. **Prevention (strongest):** PR checklist — "did this PR change a documented pattern?"
2. **Proactive detection:** `verify-when` paths in lint script
3. **Structural detection:** Broken file reference checking in lint script
4. **Periodic detection:** `last-verified` date checking (90-day threshold)
5. **Semantic detection:** `/docs-kb:docs-audit` with the review agent catches code examples that diverge from reality

### Failure: Context compaction drops the index

**Cause:** Long sessions compress early context including CLAUDE.md.

**Mitigation:** The rule file lives in `.claude/rules/docs-kb/` (symlinked from the plugin by the SessionStart hook), which Claude Code reloads on compaction. The index in CLAUDE.md is positioned near the top for higher primacy. Double coverage: the rule triggers scanning, and the CLAUDE.md section provides the index data.

### Failure: Chain navigation breaks at depth

**Cause:** Main agent navigates doc chains itself and loses task context.

**Mitigation:** The traversal agent handles all multi-hop navigation. The rule file explicitly instructs "use the doc-traversal agent" for directory entries. The main agent only reads known leaf files directly (1 hop).

### Failure: Circular references between docs

**Mitigation:** The traversal agent tracks visited paths and breaks cycles.

### Failure: `docs/` directory already exists

**Mitigation:** Bootstrap detects existing content and asks the user for an alternative name, or offers root-level mode.

### Failure: New team member doesn't know the system exists

**Mitigation:** `docs/README.md` explains the system. The CLAUDE.md docs section is visible. `_index.md` files are self-documenting.

---

## 11. Testing the Plugin

After installation and bootstrap:

**Test 1: Basic routing.**
Ask Claude: "Help me write a new test." Claude should read `docs/testing.md` before writing code. If it doesn't, check the traversal agent's decision log and improve the description.

**Test 2: Cross-domain task.**
Ask Claude: "Add a new API endpoint with database access." Claude should read relevant docs for both domains. If it reads all docs, descriptions are too broad.

**Test 3: No-doc task.**
Ask Claude: "Fix this typo in the README." Claude should NOT read any docs.

**Test 4: Deep traversal (if using nesting).**
Ask Claude about a topic in a nested subtree. Verify the traversal agent finds and returns the relevant leaf docs.

**Test 5: Lint script.**
Run `scripts/lint-docs.sh`. Verify it reports broken references, orphaned docs, stale dates, and changed `verify-when` paths.

**Test 6: Grep fallback.**
Ask Claude about a topic with no matching doc. Verify it searches the codebase rather than improvising.

**Test 7: Audit.**
Run `/docs-kb:docs-audit`. Verify it invokes the review agent and presents actionable results.

**Test 8: Add doc.**
Run `/docs-kb:docs-add auth`. Verify it enforces naming, creates the file with proper template, asks for a situation-based description, and updates both indexes.

---

## 12. Versioning

### v1.0 (This Plan)

- 10 functional files: traversal agent, review agent, rule file, hook script, docs-root helper, bootstrap skill, add skill, audit skill, plugin.json manifest, lint script
- Rule files delivered via subdirectory symlink (`.claude/rules/docs-kb/`) — auto-loads every turn, updates flow through on upgrade, project's own rules untouched
- ~390 lines total
- Self-contained plugin directory following Claude Code plugin format
- Flat docs by default, nesting supported
- Configurable docs directory (any subfolder or root-level), discovered dynamically via `find-docs-root.sh` — no env var
- `verify-when` metadata and lint integration
- `.claude-plugin/plugin.json` manifest for Claude Code / ichiba marketplace
- Discoverability via `docs/README.md`

### v1.1 (Driven by observed marketplace friction)

- Cycle detection in lint script
- Description quality scoring in the traversal agent's decision log
- Git hook integration for lint-docs.sh
- Framework-specific doc templates (if marketplace users request them)

### v2.0 (ichiba platform integration)

- One-command install/uninstall via ichiba CLI
- Upgrade diffing: detect user customizations before overwriting
- Full monorepo support (per-package bootstrap, cross-package traversal)
- Usage analytics: which docs get loaded most often, which never get loaded
- Community-contributed doc templates for common frameworks

---

## 13. Summary

| # | File (at plugin root) | Lines | Purpose |
|---|------|-------|---------|
| 1 | `agents/doc-traversal.md` | ~30 | Navigate doc trees with inclusion-biased matching and decision logging |
| 2 | `agents/doc-review.md` | ~30 | Audit docs for semantic staleness (code examples vs. reality) |
| 3 | `rules/scan-docs-index.md` | ~15 | Auto-trigger: scan docs index at task start, grep fallback |
| 4 | `scripts/find-docs-root.sh` | ~15 | Breadth-first search for shallowest `_index.md` — no hardcoded names or env vars |
| 5 | `scripts/install-rules.sh` | ~10 | SessionStart hook: symlinks `rules/` as `.claude/rules/docs-kb/` |
| 6 | `skills/docs-bootstrap/SKILL.md` | ~90 | First-time infrastructure setup, root-level support, no skeleton docs |
| 7 | `skills/docs-add/SKILL.md` | ~50 | Create new docs with tree-aware placement and conventions enforced |
| 8 | `skills/docs-audit/SKILL.md` | ~25 | Run staleness audit via review agent |
| 9 | `.claude-plugin/plugin.json` | ~25 | Plugin manifest + SessionStart hook registration |
| 10 | `scripts/lint-docs.sh` | ~100 | CI-ready lint with `_index.md` tree parsing and `verify-when` support |

**Total plugin footprint: ~390 lines across 10 functional files.**

The plugin is a self-contained directory following Claude Code's plugin format. When installed, components are namespaced (e.g., `/docs-kb:docs-bootstrap`). The plugin's `rules/` directory is symlinked as `.claude/rules/docs-kb/` by a `SessionStart` hook — so rules auto-load on every turn, updates flow through on upgrade, and the project's own `.claude/rules/` files are untouched.

This is a marketplace product, not a minimal template. The 10 files provide a complete experience for users who install from ichiba and don't know the conventions. The traversal agent, review agent, and lint script do things no convention document can. The three skills (bootstrap, add, audit) are the onboarding and maintenance UX. The SessionStart hook + subdirectory symlink pattern keeps rules auto-updating without touching the project's own rule files.

The plugin supports any docs directory location — a subfolder (default `docs/`), a custom-named folder, or the repo root for knowledge-base-style projects. After bootstrap, `find-docs-root.sh` discovers the docs root dynamically via breadth-first search for the shallowest `_index.md`. No environment variables or hardcoded directory names — the `_index.md` tree is the single source of truth.

Every design decision traces back to the research:
- Progressive disclosure over eager loading — but honest about when NOT to use it (section 0)
- Traversal agent for depth — inclusion-biased with decision logging (contrarian-analysis.md, section 4)
- Review agent for semantic staleness — OpenAI garbage collection pattern (overview.md)
- Situation-based descriptions (contrarian-analysis.md, section 1)
- Iterative adoption from friction — no speculative skeletons (implementation.md, step 6)
- Layered staleness prevention: PR checklist > verify-when > lint > review agent (contrarian-analysis.md, section 5)
- Flat by default, nest when earned (architecture.md, section 7)
- Grep fallback for uncovered topics (contrarian-analysis.md, section 6)
- Plugin directory structure follows Claude Code's plugin format: `.claude-plugin/plugin.json` manifest, components at root, auto-discovery
- SessionStart hook + subdirectory symlink for rule delivery: `.claude/rules/docs-kb/` owned by plugin, project rules untouched, auto-updates on upgrade

Quality improvements from critic review are incorporated into every component — they made the product better even where their framing (cut to minimum, disclaim marketplace) was wrong.

<!-- last-verified: 2026-02-28 -->