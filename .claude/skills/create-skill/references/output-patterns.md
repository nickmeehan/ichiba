# Output Patterns

Use these patterns when a skill needs to produce consistent, high-quality output.

## Template Pattern

Provide templates for output format. Match strictness to your needs.

**Strict requirements** (API responses, data formats):

```markdown
## Report Structure

ALWAYS use this exact template:

# [Analysis Title]

## Executive Summary
[One-paragraph overview of key findings]

## Key Findings
- Finding 1 with supporting data
- Finding 2 with supporting data

## Recommendations
1. Specific actionable recommendation
2. Specific actionable recommendation
```

**Flexible guidance** (when adaptation is useful):

```markdown
## Report Structure

Sensible default format — use your best judgment:

# [Analysis Title]

## Executive Summary
[Overview]

## Key Findings
[Adapt sections based on what you discover]

## Recommendations
[Tailor to the specific context]

Adjust sections as needed for the specific analysis type.
```

## Examples Pattern

When output quality depends on seeing examples, provide input/output pairs:

```markdown
## Commit Message Format

Generate commit messages following these examples:

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware

**Example 2:**
Input: Fixed bug where dates displayed incorrectly in reports
Output:
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently across report generation
```

Examples help Claude understand desired style and detail level more
effectively than descriptions alone.

## Choosing a Pattern

- **Template**: Use when structure must be consistent across outputs
- **Examples**: Use when tone, style, or judgment matters more than structure
- **Both**: Use when you need consistent structure AND a specific voice
