# Writing Descriptions

## Formula

```
[What it does - action verbs] + [When to use - trigger conditions and keywords]
```

## Requirements Checklist

- [ ] States specific capabilities (verbs: extract, generate, analyze, create)
- [ ] Includes domain keywords users would mention
- [ ] Specifies trigger conditions ("Use when…")
- [ ] Under 1024 characters
- [ ] Written in third person

## Good Examples

```yaml
description: >
  Extract text and tables from PDF files, fill forms, merge documents.
  Use when working with PDF files or when user mentions PDFs, forms,
  or document extraction.

description: >
  Generate descriptive commit messages by analyzing git diffs.
  Use when user asks for help writing commit messages or reviewing
  staged changes.

description: >
  Create, edit, and analyze Word documents with tracked changes, comments,
  and formatting preservation. Use when working with .docx files or when
  user mentions Word documents, track changes, or document editing.
```

## Bad Examples

```yaml
# Too vague - cannot determine when to trigger
description: Helps with documents

# Missing "when to use"
description: Processes PDF files

# Too broad
description: Does stuff with data
```
