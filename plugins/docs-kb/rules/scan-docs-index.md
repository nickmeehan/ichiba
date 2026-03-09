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
