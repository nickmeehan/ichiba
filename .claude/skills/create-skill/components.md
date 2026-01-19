# Component Reference

## SKILL.md Structure

```markdown
---
name: [required - lowercase, hyphens, numbers only, max 64 chars]
description: [required - max 1024 chars, must include what + when]
---

# [Title]

[Body - instructions, examples, references to nested files]
```

### Frontmatter Fields

| Field         | Required | Constraints                                                                 |
|---------------|----------|-----------------------------------------------------------------------------|
| `name`        | Yes      | Lowercase, hyphens, numbers only. Max 64 chars. No "anthropic" or "claude". |
| `description` | Yes      | Max 1024 chars. Must describe WHAT it does AND WHEN to use it.              |

### Body Guidelines

1. Handle 80% of use cases in first 50 lines
2. Use clear section headers for navigation
3. Reference files explicitly with "when to use" context
4. Keep under 500 lines total
5. Write in imperative form

---

## _shared/ Directory

**Location:** Inside skill directory, beside SKILL.md.

**Purpose:** Content reused by multiple nested files within this skill.

```
skill-name/
├── SKILL.md
├── _shared/           ← Correct: inside skill
│   └── guidelines.md
├── domain-a/
│   └── domain-a.md    ← References ../_shared/guidelines.md
└── domain-b/
    └── domain-b.md    ← References ../_shared/guidelines.md
```

### Use _shared/ For

- Style guidelines applying to all domains/formats
- Error handling patterns used everywhere
- Validation rules shared across workflows
- Common terminology definitions

### Do NOT Use _shared/ For

- Domain-specific syntax (put in domain file)
- One-off instructions (put inline)
- Large reference docs (put in `references/`)

---

## scripts/ Directory

**Purpose:** Executable code for deterministic operations.

### When to Include Scripts

- Same code is rewritten repeatedly
- Deterministic reliability is required
- Complex operations prone to errors

### Script Requirements

- Include shebang (`#!/usr/bin/env python3`)
- Test by executing before finalizing
- Handle errors gracefully with clear messages
- Document usage in SKILL.md

### Referencing Scripts from SKILL.md

```markdown
## Utility Scripts

Extract text from document:
\```bash
python scripts/extract_text.py input_file output.txt
\```

Validate structure:
\```bash
python scripts/validate.py document_path
\```
```

---

## references/ Directory

**Purpose:** Documentation loaded into context as needed.

### When to Use references/

- API documentation
- Database schemas
- Domain knowledge too large for SKILL.md
- Detailed specifications

### Guidelines

- Keep SKILL.md lean; move details here
- For files >10k words, include grep patterns in SKILL.md
- Do not duplicate content between SKILL.md and references/

### Referencing from SKILL.md

```markdown
## Detailed Documentation

- API method signatures: `./references/api-docs.md`
- Database schema: `./references/schema.md`

For large files, search with:
\```bash
grep -i "relevant_term" references/api-docs.md
\```
```

---

## assets/ Directory

**Purpose:** Files used in output, not loaded into context.

### Examples

- `assets/logo.png` - Brand images
- `assets/template.pptx` - Presentation templates
- `assets/boilerplate/` - Starter code
- `assets/font.ttf` - Typography

### Usage Pattern

Assets are copied or modified during execution, not read into context.

```markdown
## Templates

Copy the starter template:
\```bash
cp -r assets/boilerplate/ /path/to/output/
\```
```
