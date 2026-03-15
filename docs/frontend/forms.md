# Forms

Nimbus uses React Hook Form for all form state management, paired with Zod schemas for validation. This combination provides type-safe validation, minimal re-renders, and a consistent developer experience across the application.

## React Hook Form Setup

Every form uses the `useForm` hook with a Zod resolver. Form values are typed from the Zod schema using `z.infer`, which keeps the schema and TypeScript types in sync automatically.

```tsx
const schema = z.object({
  title: z.string().min(1, "Title is required").max(200),
  description: z.string().max(5000).optional(),
  assigneeId: z.string().uuid().nullable(),
  dueDate: z.coerce.date().min(new Date(), "Due date must be in the future").optional(),
  priority: z.enum(["low", "medium", "high", "urgent"]),
});

type TaskFormValues = z.infer<typeof schema>;

const form = useForm<TaskFormValues>({
  resolver: zodResolver(schema),
  defaultValues: { title: "", priority: "medium", assigneeId: null },
});
```

## Zod Validation Schemas

Validation schemas live in `src/schemas/` alongside the domain they validate. Shared schemas (email, URL, phone) are in `src/schemas/common.ts`.

Guidelines:
- Always provide human-readable error messages via the second argument to validators
- Use `.transform()` to normalize data (e.g., trimming whitespace, lowercasing emails)
- Use `.refine()` for cross-field validation (e.g., end date must be after start date)
- Reuse schemas between frontend and API using the shared `packages/schemas` package

## Field Components

Nimbus provides a set of form-aware field components that integrate with React Hook Form's `Controller`:

| Component | Usage |
|-----------|-------|
| `TextField` | Single-line text input with label, error, and helper text |
| `TextArea` | Multi-line text input with character count |
| `SelectField` | Dropdown selection backed by Radix Select |
| `DatePicker` | Date selection with calendar popover |
| `UserPicker` | Async user search with avatar display |
| `CheckboxField` | Single checkbox with label |
| `RadioGroup` | Radio button group with options |
| `FileUpload` | Drag-and-drop file upload with preview |

All field components accept a `name` prop and use `useFormContext()` internally, so they must be rendered inside a `FormProvider`.

## Multi-Step Forms

Complex flows like project creation and onboarding use the `MultiStepForm` component. Each step is a separate component with its own partial Zod schema. Validation runs per-step, and the final submission merges all step data.

```tsx
<MultiStepForm
  steps={[
    { label: "Basics", component: ProjectBasicsStep, schema: basicsSchema },
    { label: "Team", component: ProjectTeamStep, schema: teamSchema },
    { label: "Settings", component: ProjectSettingsStep, schema: settingsSchema },
  ]}
  onSubmit={handleCreate}
/>
```

Step progress is shown in a horizontal stepper. Users can navigate back to previous steps without losing data. Draft state is auto-saved to `sessionStorage` every 10 seconds.

## Form Submission

Forms submit via React Query mutations. The pattern is:

1. Call `form.handleSubmit(onSubmit)` on the form element
2. In `onSubmit`, call the mutation's `mutateAsync`
3. On success, show a toast and navigate or close the modal
4. On error, map API validation errors back to form fields using `form.setError`

## See Also

- [Data Validation](../data/validation.md) for shared Zod schemas between frontend and backend
- [Component Library](component-library.md) for field component details
- [Accessibility](accessibility.md) for form accessibility requirements

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: React Hook Form or Zod is upgraded to a new major version -->
