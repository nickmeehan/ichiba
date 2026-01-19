# Error Recovery

## IF SKILL.md exceeds 500 lines

1. Identify logical split points (by domain, workflow, or complexity)
2. Extract sections into nested files
3. Replace extracted content with references in SKILL.md
4. Add "when to use" context to each reference

## IF description exceeds 1024 chars

1. Remove redundant phrases
2. Consolidate similar trigger conditions
3. Focus on most common use cases
4. Keep essential keywords

## IF nested files reference each other (creating depth > 1)

1. Flatten structure
2. Move shared content to `_shared/`
3. Have both files reference `_shared/` instead of each other

## IF path already exists when creating skill

1. Ask user: overwrite existing or choose new name?
2. If overwrite: backup existing first
3. If new name: suggest `[skill-name]-v2` or similar
