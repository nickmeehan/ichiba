# XSS Prevention

Cross-site scripting (XSS) is a top web security risk. Nimbus has multiple layers of defense to prevent XSS attacks across the application.

## React Built-In Escaping

React automatically escapes values embedded in JSX, which prevents the most common XSS vector:

```tsx
// Safe: React escapes the task title
<h1>{task.title}</h1>

// Safe: Attribute values are also escaped
<div data-name={task.title} />
```

This protection covers the vast majority of rendering in Nimbus. Developers do not need to manually escape values in JSX expressions.

## dangerouslySetInnerHTML Policy

Use of `dangerouslySetInnerHTML` is **prohibited** without explicit security review. The only approved use case is rendering sanitized rich text content (task descriptions and comments that support formatting).

When `dangerouslySetInnerHTML` is required:

1. Sanitize the HTML server-side using `sanitize-html` with the approved configuration.
2. The approved config allows only: `p`, `br`, `b`, `i`, `em`, `strong`, `ul`, `ol`, `li`, `a` (with `href` and `rel="noopener"`).
3. Add a code comment explaining why raw HTML is needed and linking to this guide.
4. The PR must be approved by a senior engineer.

```typescript
import sanitizeHtml from 'sanitize-html';
import { ALLOWED_HTML_CONFIG } from '@nimbus/shared/security';

const cleanHtml = sanitizeHtml(rawHtml, ALLOWED_HTML_CONFIG);
```

## Content Security Policy (CSP)

Nimbus sets a strict Content Security Policy header to prevent inline script execution:

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https://nimbus-uploads.s3.amazonaws.com;
  connect-src 'self' https://api.nimbus.io wss://api.nimbus.io;
  frame-ancestors 'none';
```

Key restrictions:
- **No inline scripts**: All scripts must be loaded from the same origin or have a valid nonce.
- **No eval**: `eval()` and `Function()` constructors are blocked.
- **No framing**: `frame-ancestors 'none'` prevents clickjacking.

The nonce is generated per request by the Next.js server and injected into `<script>` tags.

## Sanitization for Rich Text

The rich text editor (Tiptap) produces HTML that is sanitized at two points:

1. **Client-side**: Before submission, the editor output is sanitized for preview.
2. **Server-side**: The API sanitizes HTML before storing it in the database. This is the authoritative sanitization layer.

Never trust client-side sanitization alone. The server-side sanitization in `apps/api/src/middleware/sanitize.ts` is the security boundary.

## See Also

- [Input Validation](input-validation.md) — validating input before processing
- [CSRF Protection](csrf-protection.md) — complementary request forgery prevention
- [Threat Model](threat-model.md) — XSS in the broader threat landscape

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: CSP policy, sanitization library, or rich text editor changes -->
