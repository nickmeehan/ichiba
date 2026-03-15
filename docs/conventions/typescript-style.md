# TypeScript Style

Nimbus uses TypeScript in strict mode across all packages. This guide covers type patterns, conventions, and rules enforced by the compiler and ESLint.

## Strict Mode

All `tsconfig.json` files extend the base config with `strict: true`. This enables:

- `strictNullChecks`: No implicit `null` or `undefined`.
- `noImplicitAny`: Every value must have a type.
- `strictFunctionTypes`: Proper variance checking for function parameters.
- `strictPropertyInitialization`: Class properties must be initialized.

Never add `// @ts-ignore` or `// @ts-expect-error` without a justification comment and a Linear ticket to fix it.

## Type vs. Interface

Use `type` for most type definitions. Use `interface` only when you need declaration merging (rare).

```typescript
// Preferred: type alias
type Task = {
  id: string;
  title: string;
  status: TaskStatus;
  createdAt: Date;
};

// Also fine: type for unions and intersections
type TaskStatus = 'active' | 'completed' | 'archived';
type TaskWithProject = Task & { project: Project };
```

Use `interface` for:
- Extending third-party library types (declaration merging).
- Defining class contracts (rare, since we prefer plain functions).

## Generic Constraints

Use generics with constraints to keep types flexible but safe:

```typescript
// Good: constrained generic
function findById<T extends { id: string }>(items: T[], id: string): T | undefined {
  return items.find(item => item.id === id);
}

// Bad: unconstrained, too permissive
function findById<T>(items: T[], id: string): T | undefined { ... }
```

## Utility Types

Leverage TypeScript's built-in utility types:

| Utility | Use case |
|---------|---------|
| `Partial<T>` | Update input where all fields are optional |
| `Required<T>` | Ensure all optional fields are present |
| `Pick<T, K>` | Select specific fields from a type |
| `Omit<T, K>` | Exclude specific fields |
| `Record<K, V>` | Typed key-value maps |
| `NonNullable<T>` | Remove `null` and `undefined` |

Custom utility types are defined in `packages/shared/src/types/utils.ts`.

## No `any` Rule

The `any` type is banned by ESLint (`@typescript-eslint/no-explicit-any`). Use these alternatives:

| Instead of `any` | Use |
|-----------------|-----|
| Unknown JSON input | `unknown` (then narrow with Zod) |
| Generic callback | `(...args: unknown[]) => unknown` |
| Error caught in catch | `unknown` (then `instanceof` check) |
| Third-party untyped lib | Write a `.d.ts` declaration file |

## Discriminated Unions

Use discriminated unions for state modeling:

```typescript
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: AppError };

function renderTaskList(state: AsyncState<Task[]>) {
  switch (state.status) {
    case 'idle': return null;
    case 'loading': return <Spinner />;
    case 'success': return <TaskList tasks={state.data} />;
    case 'error': return <ErrorMessage error={state.error} />;
  }
}
```

The compiler enforces exhaustive handling of all variants.

## See Also

- [Naming Conventions](naming.md) — type and interface naming
- [Error Handling Patterns](error-handling-patterns.md) — Result type with discriminated unions
- [React Patterns](react-patterns.md) — typing React components and hooks

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: TypeScript version, tsconfig settings, or ESLint type rules change -->
