# Doc-Traversal Agent Eval Runner

Run this as a prompt to execute the full eval suite. It spawns doc-traversal agent trials in parallel batches, collects results, and scores them.

## Instructions

1. Read `plugins/docs-kb/eval/eval-config.json` to load test definitions.
2. Create `plugins/docs-kb/eval/results/` directory for output.
3. For each test, run N trials (configured in eval-config.json) by spawning doc-traversal agents.
4. **Parallelization**: Run all 6 tests in parallel per round. Run 10 rounds sequentially.
5. For each agent response, parse the `eval-results` block and save a JSON result file.
6. After all trials complete, run `python3 plugins/docs-kb/eval/score-results.py plugins/docs-kb/eval/results/` to compute scores.

## Agent Prompt Template

For each trial, spawn an Agent with `subagent_type: Explore` and `model: haiku` using this prompt (replace {{QUERY}} with the test query):

```
You are acting as the doc-traversal agent. Your task: find documentation relevant to "{{QUERY}}".

Follow this process exactly:
1. Read docs/_index.md to see all top-level topics
2. Match the task against each entry's description and activation trigger
3. For matching leaf files (*.md), read them
4. For matching directories (*/), read their _index.md and recurse
5. Continue until you reach leaf docs in every matching branch
6. Return file paths and content of all relevant leaf docs

Rules:
- Err on the side of inclusion
- Return only leaf docs, not intermediate indexes
- Hard cap: return at most 7 leaf docs. If more than 7 match, return 7 most relevant and report omissions
- Use paths relative to repo root
- Track visited paths to detect cycles
- Output a decision log: which entries considered, matched, skipped with brief reason
- Minimize read calls: read _index.md first, only read leaf docs after confirming relevance

**IMPORTANT**: At the very end of your response, output a machine-parseable summary block in exactly this format:

\```eval-results
RETURNED_DOCS: path1.md, path2.md, path3.md
READ_COUNT: <number of Read tool calls you made>
CAP_RESPECTED: true|false
\```

Start at docs/_index.md. This is a RESEARCH task — do NOT edit any files.
```

## Parsing Results

From each agent's response, extract:
- `RETURNED_DOCS`: comma-separated list of doc paths
- `READ_COUNT`: integer
- `CAP_RESPECTED`: boolean

Save as JSON: `results/{test_id}-trial-{N}.json`

```json
{
  "test_id": "narrow-oauth",
  "trial": 1,
  "query": "implementing OAuth token refresh",
  "returned_docs": ["docs/path1.md", "docs/path2.md"],
  "read_count": 15,
  "cap_respected": true
}
```
