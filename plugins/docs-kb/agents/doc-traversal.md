---
name: doc-traversal
description: >
  Navigate the docs directory tree to find documentation relevant to a given
  task. Reads _index.md routing tables at each level, matches entries against
  the task, and returns relevant leaf docs. Use for any docs/ lookup that
  involves nested directories or when the rule file delegates traversal.
---

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
