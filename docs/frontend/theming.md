# Theming

Nimbus supports light and dark modes, tenant-customizable brand colors, and a design token system built on CSS custom properties. The theming layer ensures visual consistency while allowing tenants to apply their own branding to the interface.

## CSS Variables Architecture

All visual values flow through CSS custom properties defined at three levels:

1. **Global tokens** (`--nimbus-*`): Semantic, context-independent values. Defined in `tokens/global.css`.
2. **Alias tokens** (`--color-*`, `--spacing-*`, `--radius-*`): Semantic aliases that reference global tokens. These change between light/dark mode.
3. **Component tokens** (`--button-*`, `--card-*`): Component-specific variables that reference alias tokens.

```css
:root {
  --nimbus-blue-500: #3b82f6;
  --color-primary: var(--nimbus-blue-500);
  --button-bg: var(--color-primary);
}

[data-theme="dark"] {
  --color-primary: var(--nimbus-blue-400);
  --color-surface: var(--nimbus-gray-900);
  --color-text: var(--nimbus-gray-100);
}
```

## Dark and Light Mode

Mode switching is handled by the `ThemeProvider` component, which sets a `data-theme` attribute on the document root. The user's preference is stored in their profile and synced across devices.

Detection priority:
1. Explicit user setting (stored in profile)
2. System preference via `prefers-color-scheme` media query
3. Default to light mode

The transition between modes uses `transition: background-color 200ms, color 200ms` on the body to avoid jarring flashes. During SSR, the mode is injected as a blocking script to prevent flash of wrong theme.

## Tenant-Customizable Themes

Enterprise tenants can configure brand colors through the admin panel. Customizable properties include:

| Property | Token | Default |
|----------|-------|---------|
| Primary color | `--color-primary` | `#3b82f6` |
| Primary hover | `--color-primary-hover` | `#2563eb` |
| Logo | Uploaded asset | Nimbus logo |
| Favicon | Uploaded asset | Nimbus favicon |
| Login background | Uploaded asset | Default gradient |

Tenant theme overrides are loaded at app initialization and injected as inline CSS variables. The `useTenantTheme` hook provides access to tenant branding in components.

Custom colors are validated server-side to ensure WCAG AA contrast ratios against both light and dark backgrounds. If a tenant's primary color fails contrast checks, the admin panel shows a warning and suggests adjusted alternatives.

## Design Tokens

Tokens are defined in `packages/tokens/` as TypeScript objects and compiled to CSS variables, JSON, and Figma plugin format. Token categories:

- **Colors**: Palette, semantic, and component-level colors
- **Typography**: Font families (Inter for UI, JetBrains Mono for code), sizes, weights, line heights
- **Spacing**: 4px base unit scale (4, 8, 12, 16, 20, 24, 32, 40, 48, 64)
- **Radii**: `sm` (4px), `md` (8px), `lg` (12px), `full` (9999px)
- **Shadows**: `sm`, `md`, `lg`, `xl` elevation levels
- **Transitions**: Duration and easing presets

## Theme Provider API

The `ThemeProvider` wraps the app root and exposes theme utilities via context:

```tsx
const { mode, setMode, toggleMode, tenantTheme } = useTheme();
```

Components should never hard-code colors or spacing values. Always reference tokens via CSS variables or the `useTheme` hook.

## See Also

- [Component Library](component-library.md) for how components consume design tokens
- [Accessibility](accessibility.md) for color contrast requirements
- [Performance](performance.md) for CSS variable performance considerations

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: design tokens are restructured or tenant theming capabilities are expanded -->
