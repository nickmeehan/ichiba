---
name: create-skill
description: >
  Create well-structured skills with proper organization, progressive disclosure,
  and effective descriptions. Use when asked to create a skill, build a skill,
  make a new capability, add a skill to .claude/skills, create a plugin skill,
  or extend Claude's capabilities with specialized knowledge or workflows.
---

# Skill Authoring Guide

Create effective, well-structured skills. Inspired by [Anthropic's skill-creator](https://github.com/anthropics/skills).

## Skill Creation Process

Follow these steps in order, skipping only when there's a clear reason:

1. **Discover** — Understand the skill with concrete examples: `./discovery.md`
2. **Plan** — Identify reusable contents (scripts, references, assets)
3. **Initialize** — Scaffold the skill directory:
   ```bash
   ruby scripts/init_skill.rb <skill-name> --path <output-directory>
   ```
4. **Build** — Implement resources and write SKILL.md
5. **Validate** — Run pre-publish checks:
   ```bash
   ruby scripts/validate_skill.rb <path-to-skill-directory>
   ```
6. **Iterate** — Test with real tasks, refine based on usage

## Core Principles

### Concise is Key

The context window is a shared resource. Claude is already very smart — only
add context it doesn't already have. Challenge each piece of information:
"Does Claude really need this?" and "Does this paragraph justify its token cost?"

Prefer concise examples over verbose explanations.

### Progressive Disclosure

Skills use three-layer loading to minimize context usage:

| Layer | Content                | Token Cost  | When Loaded         |
|-------|------------------------|-------------|---------------------|
| 1     | `name` + `description` | ~100 tokens | Always              |
| 2     | SKILL.md body          | Variable    | When skill triggers |
| 3     | Nested files, references | Variable  | On demand           |

**Optimization:**
1. Put trigger keywords in description (Layer 1)
2. Handle 80% of cases in SKILL.md body (Layer 2)
3. Move edge cases and deep details to nested files (Layer 3)
4. Scripts execute without context cost (only output counted)

### Set Appropriate Degrees of Freedom

Match specificity to the task's fragility:

- **High freedom** (text instructions): Multiple valid approaches, context-dependent
- **Medium freedom** (pseudocode/parameterized scripts): Preferred pattern exists, some variation OK
- **Low freedom** (specific scripts, few params): Fragile operations, consistency critical

## Skill Structure

```
[skill-name]/
├── SKILL.md          # Required: Entry point and routing
├── _shared/          # Optional: Content reused by nested files
├── scripts/          # Optional: Executable code
├── references/       # Optional: Large documentation
└── assets/           # Optional: Files for output (images, templates)
```

## Step-by-Step Details

### Step 1: Discover

Gather concrete examples before building. See `./discovery.md` for key questions
and techniques. Conclude when there's a clear sense of functionality, triggers,
and concrete tasks.

### Step 2: Plan

Analyze each concrete example:
1. How would you execute this from scratch?
2. What scripts, references, or assets would help when doing this repeatedly?

Build a list of reusable resources to include.

### Step 3: Initialize

For new skills, run the scaffold generator:

```bash
ruby scripts/init_skill.rb <skill-name> --path <output-directory>
```

This creates a template directory with SKILL.md and example resource directories.
Skip if iterating on an existing skill.

### Step 4: Build

Write the skill content. Consult these guides based on your needs:

| Need | Guide |
|------|-------|
| Multi-step processes | `./references/workflows.md` |
| Consistent output formats | `./references/output-patterns.md` |
| Picking a template structure | `./templates.md` |
| How to structure a skill | `./decision-logic.md` |
| Writing good descriptions | `./descriptions.md` |
| Directory purposes | `./components.md` |

**Building order:**
1. Start with reusable resources (scripts, references, assets)
2. Test scripts by executing them
3. Write SKILL.md — frontmatter first, then body
4. Delete any unused example files from initialization

**What NOT to include:** README.md, CHANGELOG.md, INSTALLATION_GUIDE.md, or
other auxiliary documentation. Skills are for an AI agent, not human onboarding.

### Step 5: Validate

Run the validation script:

```bash
ruby scripts/validate_skill.rb <path-to-skill-directory>
```

Or use the manual checklist: `./_shared/validation.md`

Fix any errors and re-run until clean.

### Step 6: Iterate

1. Use the skill on real tasks
2. Notice struggles or inefficiencies
3. Update SKILL.md or resources
4. Re-validate and test again

## Quick Reference

| Need | Guide |
|------|-------|
| Key questions for discovery | `./discovery.md` |
| What to always/never do | `./constraints.md` |
| How to structure a skill | `./decision-logic.md` |
| Starter templates | `./templates.md` |
| Directory purposes | `./components.md` |
| Writing good descriptions | `./descriptions.md` |
| Workflow design patterns | `./references/workflows.md` |
| Output format patterns | `./references/output-patterns.md` |
| Fixing common issues | `./error-recovery.md` |
| Full working examples | `./examples.md` |
| Pre-publish checklist | `./_shared/validation.md` |
