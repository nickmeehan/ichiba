# Component Library

Nimbus uses a custom design system built on top of Radix UI primitives. Components follow atomic design methodology and are documented in Storybook. All shared components live in `packages/ui` and are consumed by the main application and any micro-frontends.

## Design System Foundation

The design system is organized into four tiers following atomic design:

- **Atoms**: Basic building blocks like `Button`, `Input`, `Badge`, `Avatar`, `Tooltip`. These wrap Radix UI primitives and apply Nimbus design tokens.
- **Molecules**: Combinations of atoms such as `SearchInput` (Input + Icon), `UserChip` (Avatar + Text), and `StatusBadge` (Badge + color logic).
- **Organisms**: Complex components like `TaskCard`, `ProjectHeader`, `CommentThread`, and `ActivityFeed`. These compose molecules and include business logic.
- **Templates**: Page-level layout components like `DashboardLayout`, `SettingsLayout`, and `KanbanBoard` that define content regions.

## Radix UI Integration

We use Radix UI for all interactive primitives (Dialog, Popover, DropdownMenu, Tabs, Accordion, Select, etc.) because it provides:

- Fully accessible components out of the box (keyboard navigation, focus management, ARIA attributes)
- Unstyled primitives that accept our design tokens without fighting default styles
- Composable APIs that allow custom rendering via `asChild`

When wrapping a Radix primitive, always re-export the `Root`, `Trigger`, and `Content` parts under Nimbus-specific names. For example, `NimbusDialog` wraps `Dialog.Root` with our default overlay and animation.

## Component API Conventions

All components follow these conventions:

1. **Props interface**: Export a `ComponentNameProps` type. Extend native HTML attributes where appropriate.
2. **Ref forwarding**: All components use `React.forwardRef`.
3. **Variant props**: Use a `variant` prop for visual variants (e.g., `primary`, `secondary`, `ghost`). Define variants using `cva` (class-variance-authority).
4. **Size props**: Use `size` with values `sm`, `md`, `lg`. Default to `md`.
5. **Composition**: Prefer compound component patterns (e.g., `Card.Root`, `Card.Header`, `Card.Body`) over prop drilling.
6. **Data attributes**: Expose `data-state` and `data-variant` for CSS targeting.

```tsx
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "danger";
  size?: "sm" | "md" | "lg";
  loading?: boolean;
}
```

## Storybook

Every component must have a Storybook story covering:

- Default state
- All variants and sizes
- Interactive states (hover, focus, disabled, loading)
- Edge cases (long text, empty state, error state)

Run Storybook locally with `pnpm storybook`. Stories are auto-deployed to `https://storybook.nimbus.internal` on merge to `main`.

## Adding a New Component

1. Create the component in `packages/ui/src/components/<tier>/<ComponentName>/`
2. Add `index.tsx`, `ComponentName.tsx`, and `ComponentName.stories.tsx`
3. Export from `packages/ui/src/index.ts`
4. Write at least one Storybook story per variant
5. Ensure the component passes accessibility checks via the Storybook a11y addon

## See Also

- [Theming](theming.md) for design tokens and CSS variable architecture
- [Accessibility](accessibility.md) for ARIA and keyboard navigation requirements
- [Forms](forms.md) for form-specific field components

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: design system packages are upgraded or new component tiers are introduced -->
