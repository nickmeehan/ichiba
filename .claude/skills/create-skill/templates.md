# Skill Templates

## Template A: Simple Skill (Single File)

**Use when:** < 200 lines, single linear workflow, no branching logic.

```
[skill-name]/
└── SKILL.md
```

**SKILL.md:**

```markdown
---
name: [lowercase-hyphenated-name]
description: >
  [What it does - use action verbs].
  Use when [specific trigger conditions and keywords users would say].
---

# [Skill Title]

## Instructions

[Core instructions - handle 80% of cases in first 50 lines]

## Examples

**Input**: [example input]
**Output**: [example output]
```

---

## Template B: Complex Skill (Multiple Domains)

**Use when:** Multiple distinct domains/formats, shared guidelines across all.

```
[skill-name]/
├── SKILL.md
├── _shared/
│   └── guidelines.md
├── [domain-a]/
│   └── [domain-a].md
├── [domain-b]/
│   └── [domain-b].md
└── scripts/
    └── [utility].py
```

**SKILL.md:**

```markdown
---
name: [skill-name]
description: >
  [Capability for domain-a], [capability for domain-b], [capability for domain-c].
  Use when working with [domain-a files], [domain-b files], or [domain-c files],
  or when user mentions [trigger keywords].
---

# [Skill Title]

## Shared Standards

Before working with any [domain type], read: `./_shared/guidelines.md`

## Domain-Specific Guides

- **[Domain A]** ([keywords]): `./[domain-a]/[domain-a].md`
- **[Domain B]** ([keywords]): `./[domain-b]/[domain-b].md`

## Quick Reference

| Task | Guide |
|------|-------|
| [Task 1] | `./[domain-a]/[domain-a].md` |
| [Task 2] | `./[domain-b]/[domain-b].md` |

## Utility Scripts

[Description of script]:
\```bash
python scripts/[utility].py [args]
\```
```

**_shared/guidelines.md:**

```markdown
# Shared [Domain] Guidelines

## Output Standards

All generated [outputs] must:
- [Standard 1]
- [Standard 2]
- [Standard 3]

## Error Handling

When operations fail:
1. [Step 1]
2. [Step 2]
3. [Step 3]
```

**Nested domain file ([domain-a]/[domain-a].md):**

```markdown
# [Domain A] Processing

## Prerequisites

Follow shared guidelines: `../_shared/guidelines.md`

## Instructions

[Domain-specific instructions]

## Examples

[Domain-specific examples]
```

---

## Template C: Workflow-Based Skill

**Use when:** Distinct operational modes (create vs edit, import vs export).

```
[skill-name]/
├── SKILL.md
├── _shared/
│   └── validation.md
├── [workflow-a]/
│   └── [workflow-a].md
└── [workflow-b]/
    └── [workflow-b].md
```

**SKILL.md:**

```markdown
---
name: [skill-name]
description: >
  [Workflow A capability] and [workflow B capability] for [domain].
  Use when user wants to [workflow A trigger] or [workflow B trigger].
---

# [Skill Title]

## Determine Workflow

**[Workflow A condition]?** → Read `./[workflow-a]/[workflow-a].md`
**[Workflow B condition]?** → Read `./[workflow-b]/[workflow-b].md`

Both workflows require: `./_shared/validation.md`
```

---

## Template D: Complexity-Based Skill

**Use when:** Beginner and advanced paths, tiered functionality.

```
[skill-name]/
├── SKILL.md
├── quickstart.md
├── advanced/
│   ├── [topic-a].md
│   └── [topic-b].md
└── references/
    └── [full-spec].md
```

**SKILL.md:**

```markdown
---
name: [skill-name]
description: >
  [Core capability] with [advanced features].
  Use when [trigger conditions].
---

# [Skill Title]

## Quick Start

For basic usage: `./quickstart.md`

## Advanced Topics

- [Topic A description]: `./advanced/[topic-a].md`
- [Topic B description]: `./advanced/[topic-b].md`

## Full Reference

Complete specification: `./references/[full-spec].md`
```
