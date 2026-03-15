# Naming Conventions

Consistent naming makes the codebase easier to navigate and reduces cognitive overhead during code review. These conventions apply across all Nimbus packages.

## Summary Table

| Context | Convention | Example |
|---------|-----------|---------|
| Variables and functions | camelCase | `taskCount`, `getActiveProjects()` |
| React components | PascalCase | `TaskCard`, `ProjectSidebar` |
| Classes and types | PascalCase | `TaskService`, `ProjectResponse` |
| Interfaces | PascalCase (no `I` prefix) | `TaskRepository`, not `ITaskRepository` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT`, `DEFAULT_PAGE_SIZE` |
| Enum members | UPPER_SNAKE_CASE | `Priority.HIGH`, `Status.IN_PROGRESS` |
| Files and directories | kebab-case | `task-card.tsx`, `project-service.ts` |
| Database tables | snake_case, plural | `tasks`, `project_members` |
| Database columns | snake_case | `created_at`, `tenant_id` |
| Environment variables | UPPER_SNAKE_CASE | `DATABASE_URL`, `STRIPE_SECRET_KEY` |
| CSS classes | kebab-case (Tailwind) | `task-card-header` (rarely used; prefer Tailwind utilities) |

## Variable and Function Names

Use descriptive names that reveal intent:

```typescript
// Good
const activeTaskCount = tasks.filter(t => t.status === 'active').length;
const isOverdue = task.dueDate < new Date();
function calculateCompletionPercentage(project: Project): number { ... }

// Bad
const cnt = tasks.filter(t => t.status === 'active').length;
const flag = task.dueDate < new Date();
function calc(p: Project): number { ... }
```

Boolean variables and functions should use `is`, `has`, `can`, or `should` prefixes:
- `isActive`, `hasPermission`, `canEdit`, `shouldRefetch`

## Component Names

React components use PascalCase and match their file name:

```
TaskCard.tsx       → export function TaskCard() { ... }
ProjectSidebar.tsx → export function ProjectSidebar() { ... }
```

Component files export a single component as a named export (not default export).

## File Names

All files use kebab-case:

```
task-card.tsx              # React component
task-card.test.tsx         # Test file
task.service.ts            # Service class
task.service.test.ts       # Service test
use-tasks.ts               # Custom hook
create-task.schema.ts      # Zod schema
```

Suffixes indicate the file's role: `.service.ts`, `.controller.ts`, `.schema.ts`, `.factory.ts`, `.test.ts`.

## Abbreviations

Avoid abbreviations except for well-known ones:

| Allowed | Not allowed |
|---------|------------|
| `id`, `url`, `api`, `db` | `cnt`, `mgr`, `svc`, `btn` |
| `env`, `config`, `auth` | `proj`, `desc`, `qty` |

When in doubt, spell it out.

## See Also

- [File Structure](file-structure.md) — where to put files
- [Database Conventions](database-conventions.md) — database-specific naming
- [TypeScript Style](typescript-style.md) — type naming patterns

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: naming conventions change or new file types are introduced -->
