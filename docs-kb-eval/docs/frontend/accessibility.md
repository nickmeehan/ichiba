# Accessibility

Nimbus targets WCAG 2.1 Level AA compliance across all features. Accessibility is a first-class requirement, not an afterthought. Every pull request that touches UI must pass automated accessibility checks before merging, and manual testing is required for new interaction patterns.

## WCAG 2.1 AA Requirements

The key success criteria we focus on:

- **1.1.1 Non-text Content**: All images, icons, and charts have meaningful alt text or are marked decorative with `aria-hidden="true"`.
- **1.3.1 Info and Relationships**: Headings follow a logical hierarchy (no skipping levels). Forms use `<label>` elements associated with inputs.
- **1.4.3 Contrast (Minimum)**: Text has a contrast ratio of at least 4.5:1 against its background. Large text (18px+ bold or 24px+ regular) requires 3:1.
- **2.1.1 Keyboard**: All interactive elements are reachable and operable via keyboard alone.
- **2.4.7 Focus Visible**: Focused elements have a clearly visible focus indicator (2px blue ring using our `--focus-ring` token).
- **4.1.2 Name, Role, Value**: Custom components expose correct ARIA roles and properties.

## ARIA Patterns

We follow WAI-ARIA Authoring Practices for all custom widgets. Common patterns in Nimbus:

- **Kanban board**: Uses `role="listbox"` for columns and `role="option"` for cards. Drag-and-drop operations have keyboard alternatives (arrow keys to move, Enter to drop).
- **Task detail modal**: Uses `role="dialog"` with `aria-labelledby` pointing to the task title. Focus is trapped inside the modal.
- **Notification dropdown**: Uses `role="menu"` with `aria-live="polite"` for new notification announcements.
- **Data tables**: Use native `<table>` elements with `<th scope="col">` and `<th scope="row">`. Sortable columns use `aria-sort`.

## Keyboard Navigation

All features must be fully operable using only a keyboard:

- **Tab order** follows the visual layout (left-to-right, top-to-bottom). Use `tabIndex={0}` only on custom interactive elements; avoid positive tabindex values.
- **Focus management**: When opening a modal, focus moves to the first focusable element inside. When closing, focus returns to the trigger element.
- **Keyboard shortcuts**: Global shortcuts (e.g., `Cmd+K` for command palette, `N` for new task) are documented in the help menu and can be disabled per user.
- **Skip links**: A "Skip to main content" link is the first focusable element on every page.

## Screen Reader Testing

Before releasing new features, test with at least one screen reader:

| Platform | Screen Reader | Browser |
|----------|--------------|---------|
| macOS | VoiceOver | Safari |
| Windows | NVDA | Firefox |
| Windows | JAWS | Chrome |

Focus on: landmark navigation, heading structure, form labels, dynamic content updates, and error announcements.

## Color Contrast

All color pairings are validated against WCAG AA contrast ratios using our design tokens. The theming system enforces minimum contrast by construction. When adding new colors:

1. Check contrast with the WebAIM Contrast Checker
2. Add the color to the `tokens/colors.ts` file with its intended background pairing
3. The CI pipeline runs `axe-core` and will fail if contrast violations are detected

Do not rely solely on color to convey information. Always pair color with text labels, icons, or patterns (e.g., status badges show both a colored dot and a text label).

## Automated Testing

- **Storybook a11y addon**: Runs `axe-core` on every story. Violations are shown inline.
- **CI pipeline**: `jest-axe` tests run on every rendered page. Any new violation fails the build.
- **Lighthouse**: Accessibility audits run on key pages nightly. Scores below 95 trigger alerts.

## See Also

- [Component Library](component-library.md) for accessible component patterns via Radix UI
- [Theming](theming.md) for color contrast enforcement in design tokens
- [Forms](forms.md) for accessible form field labeling and error announcements

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: WCAG guidelines are updated or accessibility audit findings require changes -->
