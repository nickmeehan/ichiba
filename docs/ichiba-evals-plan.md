# ichiba-evals: Centralized Eval Repo Plan

## Problem

Evals currently live ad-hoc (e.g. `docs-kb-eval/` in ichiba itself). As plugins grow, we need a single place to run, score, and compare evals across all plugins.

## Decision

One centralized repo (`nickmeehan/ichiba-evals`) rather than per-plugin eval repos.

**Why centralized:**
- Shared test harness, scoring, and CI — no duplication
- Cross-plugin eval coverage (e.g. test plugin interactions)
- Single place to update when eval tooling changes
- Mirrors ichiba's own single-marketplace structure

## Repo Structure

```
ichiba-evals/
├── CLAUDE.md                    # Repo-level instructions
├── README.md
├── shared/                      # Common eval infrastructure
│   ├── scoring.py               # Generic scoring (recall, precision, consistency)
│   ├── runner.py                # Trial runner utilities
│   ├── parse-output.py          # Extract structured results from agent transcripts
│   └── config-schema.json       # JSON schema for eval-config files
│
├── plugins/                     # Per-plugin eval suites
│   ├── docs-kb/
│   │   ├── CLAUDE.md            # Plugin-eval-specific instructions
│   │   ├── agents/
│   │   │   └── doc-traversal.md # Working copy of agent under test
│   │   ├── docs/                # 188-doc synthetic Nimbus corpus (test data)
│   │   │   └── _index.md
│   │   ├── eval/
│   │   │   ├── eval-config.json # Queries with must/may/must_not sets
│   │   │   ├── run-eval.md      # Runner prompt
│   │   │   ├── trial-prompt.md  # Per-trial template
│   │   │   └── results/         # Trial output JSONs
│   │   └── baselines/           # Named baseline snapshots for comparison
│   │       └── v1.0.2/          # Results from docs-kb@1.0.2
│   │
│   ├── dev-workflow/
│   │   ├── CLAUDE.md
│   │   ├── eval/
│   │   │   ├── eval-config.json # Queries testing commit, git skills
│   │   │   ├── run-eval.md
│   │   │   └── results/
│   │   └── baselines/
│   │
│   └── <future-plugin>/
│       └── ...
│
├── marketplace/                 # Marketplace-level evals
│   ├── plugin-interaction/      # Cross-plugin behavior tests
│   └── install-update/          # Plugin install/update flow tests
│
└── ci/                          # CI/CD configuration
    ├── run-all.sh               # Run all plugin evals
    ├── run-plugin.sh            # Run evals for a single plugin
    └── compare.sh               # Compare current vs baseline
```

## Migration Plan

### Phase 1: Scaffold repo and migrate docs-kb evals

1. Create `nickmeehan/ichiba-evals` repo
2. Move `ichiba/docs-kb-eval/` content into `plugins/docs-kb/`
3. Extract reusable scoring/parsing code into `shared/`
4. Verify existing docs-kb evals run identically from new location
5. Remove `docs-kb-eval/` from ichiba (or leave a pointer README)

### Phase 2: Shared infrastructure

1. Generalize `score-results.py` → `shared/scoring.py` with plugin-agnostic interface
2. Generalize `parse-agent-output.py` → `shared/parse-output.py`
3. Create `shared/config-schema.json` to validate eval-config files
4. Build `ci/run-plugin.sh` — runs evals for a named plugin, outputs scored results
5. Build `ci/compare.sh` — diffs current results against a named baseline

### Phase 3: dev-workflow evals

1. Define eval queries for dev-workflow skills (commit formatting, git operations)
2. Create `plugins/dev-workflow/eval/eval-config.json`
3. Write runner prompt and trial template
4. Run initial baseline and store in `baselines/v1.0.1/`

### Phase 4: Marketplace-level evals

1. `marketplace/plugin-interaction/` — test that plugins don't conflict
2. `marketplace/install-update/` — test plugin install and update flows

## Eval Config Convention

Every plugin eval suite must have an `eval/eval-config.json` following this shape:

```json
{
  "plugin": "docs-kb",
  "plugin_version": "1.0.2",
  "model": "haiku",
  "trials_per_query": 10,
  "queries": [
    {
      "id": "narrow-oauth",
      "type": "narrow",
      "prompt": "implementing OAuth token refresh",
      "must_include": ["api/auth/oauth.md"],
      "may_include": ["api/auth/_index.md"],
      "must_not_include": ["frontend/components/button.md"]
    }
  ]
}
```

## Scoring Convention

All plugin evals report these standard metrics (extended per-plugin as needed):

| Metric       | Target | Description                                    |
|------------- |--------|------------------------------------------------|
| Recall       | 1.0    | All must_include items found                   |
| Precision    | >0.8   | Few items outside must/may sets                |
| Consistency  | >0.7   | Jaccard similarity across trials for same query|

## Workflow: Developing a Plugin with Evals

1. **Start in ichiba-evals** — sync latest agent/skill from ichiba
2. **Run baseline** — `ci/run-plugin.sh docs-kb && cp results baselines/current`
3. **Edit** the agent/skill working copy in `plugins/<name>/`
4. **Re-run evals** — `ci/run-plugin.sh docs-kb`
5. **Compare** — `ci/compare.sh docs-kb baselines/current`
6. **If improved** — copy changes back to ichiba, bump versions per CLAUDE.md rules
