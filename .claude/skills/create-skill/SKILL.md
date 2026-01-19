---
name: create-skill
description: >
  Create well-structured skills with proper organization, progressive disclosure,
  and effective descriptions. Use when asked to create a skill, build a skill,
  make a new capability, add a skill to .claude/skills, create a plugin skill,
  or extend Claude's capabilities with specialized knowledge or workflows.
---

# Skill Authoring Guide

Instructions for creating effective, well-structured skills.

## Quick Start

1. Read constraints first: `./constraints.md`
2. Determine structure using: `./decision-logic.md`
3. Pick a template from: `./templates.md`
4. Validate before finalizing: `./_shared/validation.md`

## Core Principles

- SKILL.md is the entry point; keep it under 500 lines
- Handle 80% of use cases in the first 50 lines
- Use nested files for conditional/advanced content
- Write instructions in imperative form
- Include BOTH "what it does" AND "when to use" in descriptions

## Skill Structure Overview

```
[skill-name]/
├── SKILL.md          # Required: Entry point and routing
├── _shared/          # Optional: Content reused by nested files
├── scripts/          # Optional: Executable code
├── references/       # Optional: Large documentation
└── assets/           # Optional: Files for output (images, templates)
```

## Progressive Disclosure

Skills use three-layer loading to minimize context usage:

| Layer | Content                | Token Cost  | When Loaded         |
|-------|------------------------|-------------|---------------------|
| 1     | `name` + `description` | ~100 tokens | Always              |
| 2     | SKILL.md body          | Variable    | When skill triggers |
| 3     | Nested files, references | Variable  | On demand           |

**Optimization Rules:**
1. Put trigger keywords in description (Layer 1)
2. Handle 80% of cases in SKILL.md body (Layer 2)
3. Move edge cases and deep details to nested files (Layer 3)
4. Scripts execute without context cost (only output counted)

## Reference Guides

| Need | Guide |
|------|-------|
| What to always/never do | `./constraints.md` |
| How to structure a skill | `./decision-logic.md` |
| Starter templates | `./templates.md` |
| Directory purposes | `./components.md` |
| Writing good descriptions | `./descriptions.md` |
| Fixing common issues | `./error-recovery.md` |
| Full working examples | `./examples.md` |
| Pre-publish checklist | `./_shared/validation.md` |
