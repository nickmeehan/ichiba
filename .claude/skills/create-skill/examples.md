# Complete Examples

## Example 1: Simple Skill

**Use case:** Commit message generator

```
commit-helper/
└── SKILL.md
```

**SKILL.md** (78 lines):

```markdown
---
name: commit-helper
description: >
  Generate descriptive commit messages by analyzing git diffs.
  Use when user asks for help writing commit messages, reviewing
  staged changes, or mentions git commit.
---

# Commit Message Helper

## Instructions

1. Run `git diff --staged` to see changes
2. Analyze the diff:
   - What files changed
   - What the changes accomplish
   - Any breaking changes
3. Generate message in format below

## Message Format

\```
type(scope): brief description

Detailed explanation of changes
\```

## Type Reference

| Type | Use For |
|------|---------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation |
| refactor | Code restructuring |
| test | Adding tests |
| chore | Maintenance |

## Examples

**Input**: Added JWT authentication middleware
**Output**:
\```
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware
\```

**Input**: Fixed date display bug in reports
**Output**:
\```
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently across report generation
\```
```

---

## Example 2: Complex Skill (Multiple Domains)

**Use case:** Document processing with multiple formats

```
document-tools/
├── SKILL.md
├── _shared/
│   ├── guidelines.md
│   └── validation.md
├── docx/
│   ├── docx.md
│   └── tracked-changes.md
├── pdf/
│   ├── pdf.md
│   └── forms.md
├── xlsx/
│   └── xlsx.md
└── scripts/
    ├── extract_text.py
    └── validate_document.py
```

**SKILL.md** (95 lines):

```markdown
---
name: document-tools
description: >
  Create, edit, and analyze Word documents, PDFs, and Excel spreadsheets.
  Supports tracked changes, form filling, and data extraction.
  Use when working with .docx, .pdf, or .xlsx files, or when user
  mentions documents, spreadsheets, forms, or track changes.
---

# Document Tools

## Shared Standards

Before working with any document, read: `./_shared/guidelines.md`

After changes, validate with: `./_shared/validation.md`

## Format-Specific Guides

### Word Documents (.docx)
- Basic operations: `./docx/docx.md`
- Tracked changes and redlining: `./docx/tracked-changes.md`

### PDF Files (.pdf)
- Basic operations: `./pdf/pdf.md`
- Form filling: `./pdf/forms.md`

### Excel Spreadsheets (.xlsx)
- All operations: `./xlsx/xlsx.md`

## Quick Reference

| Task | Guide |
|------|-------|
| Create Word doc | `./docx/docx.md` |
| Edit with track changes | `./docx/tracked-changes.md` |
| Extract PDF text | `./pdf/pdf.md` |
| Fill PDF form | `./pdf/forms.md` |
| Analyze spreadsheet | `./xlsx/xlsx.md` |

## Utility Scripts

Extract text from any document:
\```bash
python scripts/extract_text.py input_file output.txt
\```

Validate document structure:
\```bash
python scripts/validate_document.py document_path
\```
```

**_shared/guidelines.md** (42 lines):

```markdown
# Shared Document Guidelines

## Output Standards

All generated documents must:
- Use UTF-8 encoding
- Include metadata (author, date, title)
- Pass validation before delivery

## Error Handling

When document operations fail:
1. Log the specific error
2. Attempt recovery if possible
3. Report clear error message to user

## File Naming

- Use descriptive names: `quarterly-report-2025-q1.docx`
- Avoid spaces: use hyphens or underscores
- Include date for versioned documents
```

**docx/docx.md** (68 lines):

```markdown
# Word Document Processing

## Prerequisites

Follow shared guidelines: `../_shared/guidelines.md`

## Creating New Documents

Use python-docx library:

\```python
from docx import Document
from docx.shared import Inches

doc = Document()
doc.add_heading('Title', 0)
doc.add_paragraph('Content here.')
doc.save('output.docx')
\```

## Editing Existing Documents

\```python
doc = Document('existing.docx')
for para in doc.paragraphs:
    # Process paragraphs
    pass
doc.save('modified.docx')
\```

## Common Operations

### Add Table

\```python
table = doc.add_table(rows=2, cols=2)
table.cell(0, 0).text = 'Header 1'
\```

### Add Image

\```python
doc.add_picture('image.png', width=Inches(2))
\```

For tracked changes, see: `./tracked-changes.md`
```
