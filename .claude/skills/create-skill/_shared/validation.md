# Validation Checklist

Run before finalizing any skill. Use the automated validator for faster checks:

```bash
ruby scripts/validate_skill.rb <path-to-skill-directory>
```

Or verify manually with the checklist below.

## Structure Validation

```
[ ] SKILL.md exists at skill root
[ ] No files deeper than one level from SKILL.md
[ ] _shared/ is inside skill directory (not at skills/ root)
[ ] No unused example files/directories remain
[ ] No auxiliary docs (README.md, CHANGELOG.md, etc.)
```

## Frontmatter Validation

```
[ ] name: present, lowercase, hyphens/numbers only, ≤64 chars
[ ] name: does not contain "anthropic" or "claude"
[ ] description: present, ≤1024 chars
[ ] description: includes what it does (action verbs)
[ ] description: includes when to use (trigger conditions)
[ ] description: includes relevant keywords users would say
[ ] No extra frontmatter fields beyond name and description
```

## Body Validation

```
[ ] SKILL.md is ≤500 lines
[ ] 80% of use cases handled in first 50 lines
[ ] All nested file references include "when to use" context
[ ] All nested file references use correct relative paths
[ ] Instructions use imperative form
[ ] No duplicated content between SKILL.md and references/
[ ] No TODO placeholders remaining
[ ] Conciseness check: does each paragraph justify its token cost?
```

## Scripts Validation

```
[ ] All scripts have been executed and tested
[ ] Scripts have proper shebangs (#!/usr/bin/env ruby, etc.)
[ ] Script errors produce clear messages
[ ] Script usage documented in SKILL.md
```

## Path Validation

Test all relative paths:

```bash
# Automated: run the validator
ruby scripts/validate_skill.rb <path-to-skill-directory>

# Manual: from skill root, verify each referenced path exists
ls -la ./[referenced-path]
ls -la ./_shared/[file]
ls -la ./[domain]/[file].md
```
