# docs-kb Eval Suite

Evaluation harness for the docs-kb plugin's `doc-traversal` agent. Tests how well the agent finds relevant docs from a 188-doc synthetic corpus.

## Repo Structure

```
docs/              # 188-doc fictional "Nimbus" SaaS corpus (test data)
  _index.md        # Root index — the agent's entry point
  api/             # 51 endpoint docs (width stress test)
  architecture/    # 7-level nesting (depth stress test)
  conventions/     # 10 coding standards
  data/            # 9 data layer docs
  frontend/        # 11 UI docs
  guides/          # 14 guides (deployment, security)
  ops/             # 8 ops docs
  testing/         # 10 testing docs
agents/
  doc-traversal.md # The agent under test (copy from docs-kb plugin)
eval/
  eval-config.json # 6 test queries with must/may/must_not include sets
  run-eval.md      # Runner instructions (use as a prompt)
  trial-prompt.md  # Template prompt for each trial
  score-results.py # Scorer: recall, precision, cap, consistency
  parse-agent-output.py  # Extracts eval-results blocks from agent transcripts
  batch-parse.sh   # Batch wrapper for parse-agent-output.py
  results/         # Trial output JSONs (60 files from last run)
```

## Running Evals

### 1. Run trials

Use `eval/run-eval.md` as a prompt. It spawns 10 trials per query (6 queries = 60 trials) using `doc-traversal` agent with `model: haiku`.

The agent reads `docs/_index.md` and navigates the tree to find docs relevant to each query.

### 2. Score results

```bash
python3 eval/score-results.py eval/results/
```

### Metrics

| Metric | Target | Description |
|--------|--------|-------------|
| Recall | 1.0 | All must_include docs found |
| Precision | >0.8 | Few docs outside must/may sets |
| Cap adherence | 100% | Never exceeds 7-doc hard cap |
| Consistency | >0.7 | Jaccard similarity across trials for same query |

### 3. Compare runs

To compare before/after when changing the agent or descriptions:

1. Copy `eval/results/` to `eval/results-baseline/`
2. Make your changes to `agents/doc-traversal.md` or `docs/**/_index.md`
3. Re-run trials (step 1)
4. Score both: `python3 eval/score-results.py eval/results/` vs `eval/results-baseline/`
5. Compare metrics — look for recall/precision/consistency improvements without regressions

## Test Queries

| ID | Type | Query | Key challenge |
|----|------|-------|---------------|
| narrow-oauth | narrow | "implementing OAuth token refresh" | Find 3 specific docs in deep tree |
| wide-api | wide | "setting up a new API endpoint" | Navigate 51-entry API index |
| broad-deploy | broad | "deploying the application" | Gather docs across multiple categories |
| cross-auth-debug | cross-category | "debugging auth issues" | Auth docs span API, architecture, guides |
| deep-okta | deep | "configuring Okta SSO SCIM provisioning" | 7 levels deep in tree |
| negative-ml | negative | "machine learning model training" | Should return ~0 docs (nothing relevant) |

## Updating the Agent

The `agents/doc-traversal.md` file is a **copy** of the agent from the docs-kb plugin (`plugins/docs-kb/agents/doc-traversal.md` in the ichiba repo). When testing changes:

1. Edit `agents/doc-traversal.md` here
2. Run evals to validate improvement
3. Copy the improved version back to the plugin repo
