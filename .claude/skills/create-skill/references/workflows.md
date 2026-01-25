# Workflow Patterns

Use these patterns when a skill involves multi-step processes or branching logic.

## Sequential Workflows

Break complex tasks into clear, numbered steps. Give Claude an overview
of the full process near the top of SKILL.md:

```markdown
Filling a PDF form involves these steps:

1. Analyze the form (run analyze_form.rb)
2. Create field mapping (edit fields.json)
3. Validate mapping (run validate_fields.rb)
4. Fill the form (run fill_form.rb)
5. Verify output (run verify_output.rb)
```

## Conditional Workflows

For tasks with branching logic, guide Claude through decision points:

```markdown
1. Determine the modification type:
   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow: [steps]
3. Editing workflow: [steps]
```

## Combining Workflows

Most real skills combine sequential and conditional patterns:

```markdown
## Process

1. Determine document type
   - **PDF**: See `./references/pdf-workflow.md`
   - **DOCX**: See `./references/docx-workflow.md`
2. Extract content (all types use the same extraction step)
3. Transform based on output format
4. Validate result
```
