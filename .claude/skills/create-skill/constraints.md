# Constraints

## Philosophy

**Claude is already very smart.** Only add context it doesn't already have.

- Challenge each paragraph: "Does this justify its token cost?"
- Prefer concise examples over verbose explanations
- The context window is a shared resource — skills share it with system prompt,
  conversation history, other skills, and the user's actual request
- Think of skills as "onboarding guides" — procedural knowledge that no model
  can fully possess, not general knowledge Claude already has

## ALWAYS

- Include `name` and `description` in SKILL.md frontmatter
- Include BOTH "what it does" AND "when to use" in description
- Use relative paths for file references (`./path`, `../path`)
- Place `_shared/` inside the skill directory, beside SKILL.md
- Keep SKILL.md as the routing document for complex skills
- Write instructions in imperative form ("Extract X" not "You should extract X")
- Reference nested files with context ("For rate limiting, see `./advanced.md`")
- Keep all referenced files one level deep from SKILL.md
- Test scripts by executing them before finalizing
- Delete unused example files/directories

## NEVER

- Create SKILL.md files over 500 lines (split if longer)
- Use "anthropic" or "claude" in skill names
- Put `_shared/` at the `skills/` root level
- Create nesting deeper than one level from SKILL.md
- Reference files without explaining when to read them
- Use vague file names (`file1.md`, `stuff.md`, `misc.md`)
- Include README.md, CHANGELOG.md, or other auxiliary documentation
- Duplicate information between SKILL.md and reference files
- Include "when to use" information only in the body (put it in description)
