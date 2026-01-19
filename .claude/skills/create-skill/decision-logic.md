# Decision Logic

## Determine Skill Structure

```
IF estimated_total_lines < 200:
  → Create single SKILL.md
  → STOP

IF estimated_total_lines >= 200 AND estimated_total_lines <= 500:
  IF has_conditional_workflows OR has_multiple_capabilities:
    → Split into nested files
  ELSE:
    → Single SKILL.md acceptable

IF estimated_total_lines > 500:
  → MUST split into nested files
```

## Determine What to Split

```
IF same guidelines apply to multiple sections:
  → Create _shared/guidelines.md

IF multiple distinct domains (e.g., finance, sales, product):
  → Create domain/ subdirectories with domain.md files

IF conditional workflows (if X do Y, if Z do W):
  → Create separate files for each workflow branch

IF beginner vs advanced paths:
  → Create quickstart.md and advanced/ directory
```

## Determine File Placement

```
IF content is always needed:
  → Put in SKILL.md body

IF content is needed only sometimes:
  → Create nested file, reference from SKILL.md with context

IF executable code for deterministic operations:
  → Put in scripts/

IF large reference material (API docs, schemas):
  → Put in references/

IF templates, images, fonts for output:
  → Put in assets/

IF reused across multiple nested files within this skill:
  → Put in _shared/
```

## Determine Freedom Level

```
IF multiple valid approaches, context-dependent decisions:
  → Use text-based instructions (high freedom)

IF preferred pattern exists but some variation acceptable:
  → Use pseudocode or parameterized scripts (medium freedom)

IF operations are fragile, consistency critical, specific sequence required:
  → Use specific scripts with few parameters (low freedom)
```
