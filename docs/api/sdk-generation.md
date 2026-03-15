# SDK Generation

Nimbus generates typed client SDKs from the OpenAPI specification. SDKs are available for multiple languages and are published automatically when the API spec changes.

## OpenAPI Spec as Source

All SDKs are generated from the canonical OpenAPI 3.1 specification at:

```
GET /v1/openapi.json
GET /v1/openapi.yaml
```

The spec is the single source of truth for request/response types, endpoint signatures, and validation rules.

## Code Generation Pipeline

The SDK generation pipeline runs automatically on every API release:

1. The OpenAPI spec is validated for completeness and correctness
2. Language-specific generators produce client code
3. Generated code is linted and formatted per language conventions
4. Automated tests run against a staging API instance
5. Passing SDKs are published to package registries

The pipeline uses a customized fork of OpenAPI Generator with Nimbus-specific templates for error handling, pagination, and authentication.

## Language Targets

| Language | Package | Registry |
|----------|---------|----------|
| TypeScript | `@nimbus/api-client` | npm |
| Python | `nimbus-api` | PyPI |
| Go | `github.com/nimbus/api-go` | Go modules |
| Java | `io.nimbus:api-client` | Maven Central |
| Ruby | `nimbus-api` | RubyGems |
| C# | `Nimbus.ApiClient` | NuGet |

## SDK Features

All generated SDKs include:

- **Typed request/response models** with full IDE autocompletion
- **Built-in authentication** — configure once, applied to all requests
- **Automatic pagination** — iterator helpers for cursor-based pagination
- **Retry logic** — exponential backoff with idempotency key support
- **Rate limit handling** — automatic wait-and-retry on 429 responses
- **Error types** — typed error classes matching the error catalog

## SDK Versioning

SDKs follow the API version they target. The SDK version format is `{api_version}.{sdk_patch}`:

- `1.0.0` — first release for API v1
- `1.0.1` — bug fix in SDK code (no API change)
- `2.0.0` — SDK for API v2

Breaking SDK changes only occur with major API version changes.

## Custom SDK Generation

Enterprise customers can generate custom SDKs with:

- Custom base URLs for on-premise deployments
- Additional authentication methods
- Workspace-specific custom field types baked into models

## See Also

- [OpenAPI Spec](openapi-spec.md) — the source specification
- [Versioning](versioning.md) — API version lifecycle
- [REST Overview](rest-overview.md) — API conventions the SDK encapsulates
- [Authentication](authentication.md) — auth methods supported by SDKs

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: supported languages, SDK features, or generation pipeline changes -->
