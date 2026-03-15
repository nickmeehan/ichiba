# Conventions

Coding standards, patterns, and conventions used across the Nimbus platform. Following these conventions ensures consistency and makes code reviews faster.

## Available Guides

| Convention | When to reference it |
|-----------|---------------------|
| [Naming](naming.md) | You are naming a variable, function, component, file, or database column and want to follow team standards. |
| [File Structure](file-structure.md) | You are creating a new feature, module, or package and need to know where files should go. |
| [Git Workflow](git-workflow.md) | You are creating a branch, writing a commit message, or merging code to `main`. |
| [PR Process](pr-process.md) | You are opening a pull request and need to follow the template and automation requirements. |
| [Error Handling Patterns](error-handling-patterns.md) | You need to handle, propagate, or display errors following the team's established patterns. |
| [Logging](logging.md) | You are adding log statements and need to follow structured logging conventions. |
| [TypeScript Style](typescript-style.md) | You need guidance on type definitions, generics, or TypeScript-specific patterns. |
| [React Patterns](react-patterns.md) | You are building React components and want to follow the team's component design patterns. |
| [API Design](api-design.md) | You are designing a new REST API endpoint or modifying an existing one. |
| [Database Conventions](database-conventions.md) | You are creating tables, columns, indexes, or migrations in the Prisma schema. |

## Enforcing Conventions

Most conventions are enforced automatically:

- **ESLint**: Naming rules, import ordering, React patterns.
- **Prettier**: Code formatting (no debates).
- **TypeScript strict mode**: Type safety at compile time.
- **PR template**: Checklist items remind authors of key conventions.
- **Husky pre-commit hook**: Runs lint and type-check before commit.

Conventions not enforceable by tooling are checked during code review.

## See Also

- [Guides](../guides/_index.md) — how-to guides for common tasks
- [Testing](../testing/_index.md) — test-specific conventions and tools
- [Code Review](../guides/code-review.md) — how conventions are verified in review

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: new convention is added or existing convention is significantly updated -->
