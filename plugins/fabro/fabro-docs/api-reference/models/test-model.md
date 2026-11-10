> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Test Model

> Runs the lithos-llm probe and returns its versioned report, including the canonical route, outcome, elapsed time and token usage. Unknown or unavailable models and provider failures produce HTTP 200 reports with a failed outcome. Invalid query options remain HTTP 400 errors.



## OpenAPI

````yaml /api-reference/fabro-api.yaml post /api/v1/models/{id}/test
openapi: 3.1.0
info:
  title: Fabro Run API
  version: 0.2.0
  description: HTTP API for managing Fabro workflow run executions.
servers: []
security:
  - BearerAuth: []
  - SessionCookie: []
tags:
  - name: Discovery
    description: API discovery and health
  - name: Install
    description: First-run browser install workflow
  - name: Integrations
    description: External provider callbacks and integration endpoints
  - name: Auth
    description: Browser authentication
  - name: Runs
    description: Run management operations
  - name: Automations
    description: Server-managed automation definitions and automation-triggered runs
  - name: Environments
    description: Server-managed execution environment catalog
  - name: MCP Servers
    description: >-
      Server-managed MCP server definitions referenced by id from workflow
      configs
  - name: Sandboxes
    description: Provider-backed sandbox inventory
  - name: Sessions
    description: Ask Fabro sessions bound to runs
  - name: Human-in-the-Loop
    description: Questions, answers, and steering for runs
  - name: Run Outputs
    description: Files produced by runs
  - name: Run Internals
    description: Internal run details (stages, turns, context, configuration)
  - name: Workflows
    description: Workflow definitions and execution
  - name: Workflow Versions
    description: Immutable, content-addressed workflow packages
  - name: Usage
    description: Token counts and costs
  - name: Insights
    description: SQL query editor and history
  - name: Models
    description: Available LLM models
  - name: Completions
    description: Single-turn LLM completions
  - name: Settings
    description: Platform configuration
  - name: System
    description: Server runtime, maintenance, and event streaming
paths:
  /api/v1/models/{id}/test:
    post:
      tags:
        - Models
      summary: Test Model
      description: >-
        Runs the lithos-llm probe and returns its versioned report, including
        the canonical route, outcome, elapsed time and token usage. Unknown or
        unavailable models and provider failures produce HTTP 200 reports with a
        failed outcome. Invalid query options remain HTTP 400 errors.
      operationId: testModel
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: >-
            A model selector resolved by lithos-llm (canonical ID, alias or
            provider-qualified selector).
        - $ref: '#/components/parameters/ModelTestProviderParam'
        - $ref: '#/components/parameters/ModelTestModeParam'
        - $ref: '#/components/parameters/ModelTestReasoningEffortParam'
      responses:
        '200':
          description: Probe report (passed, failed or incorrect)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProbeReport'
        '400':
          description: Invalid test mode or reasoning effort
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
components:
  parameters:
    ModelTestProviderParam:
      name: provider
      in: query
      required: false
      description: |
        Pin the test to this provider's offering. When omitted, the server
        selects among ready providers by catalog priority.
      schema:
        $ref: '#/components/schemas/ProviderId'
      example: openrouter
    ModelTestModeParam:
      name: mode
      in: query
      required: false
      description: Test mode for the single-model test endpoint. Defaults to `basic`.
      schema:
        $ref: '#/components/schemas/ModelTestMode'
      example: basic
    ModelTestReasoningEffortParam:
      name: reasoning_effort
      in: query
      required: false
      description: Optional native reasoning-effort level for the model test.
      schema:
        $ref: '#/components/schemas/ReasoningEffort'
      example: high
  schemas:
    ProbeReport:
      description: >-
        The lithos-llm version-1 probe report. The route is the canonical
        provider/model selected by the probe, or null if selection failed. Probe
        failures are findings in a successful HTTP response; API authentication,
        malformed options and server setup failures remain HTTP errors. Provider
        errors are redacted at the server disclosure boundary.
      type: object
      required:
        - version
        - route
        - outcome
        - latency_ms
        - usage
      properties:
        version:
          type: integer
          enum:
            - 1
        route:
          type:
            - string
            - 'null'
          pattern: ^[^/]+/.+$
        outcome:
          $ref: '#/components/schemas/ProbeOutcome'
        latency_ms:
          type: integer
          format: uint64
          minimum: 0
        usage:
          $ref: '#/components/schemas/TokenCounts'
    ErrorResponse:
      description: Standard error response containing one or more error entries.
      type: object
      required:
        - errors
      properties:
        errors:
          type: array
          description: List of error entries.
          items:
            $ref: '#/components/schemas/ErrorResponseEntry'
        request_id:
          type: string
          format: uuid
          description: >-
            Server-generated request identifier; matches the x-request-id
            response header.
        leftover_env_keys:
          type: array
          description: >-
            Optional list of runtime env keys that were written before an
            install failure. Currently populated by `POST /install/finish`
            failure responses only.
          items:
            type: string
        removed_env_keys:
          type: array
          description: >-
            Optional list of runtime env keys that were actually removed before
            an install failure. Currently populated by `POST /install/finish`
            failure responses only.
          items:
            type: string
    ProviderId:
      description: LLM provider identifier.
      type: string
      example: anthropic
    ModelTestMode:
      description: Single-model test mode.
      type: string
      enum:
        - basic
        - deep
    ReasoningEffort:
      description: Native reasoning-effort level requested for an LLM call.
      type: string
      enum:
        - minimal
        - low
        - medium
        - high
        - xhigh
        - max
    ProbeOutcome:
      oneOf:
        - $ref: '#/components/schemas/ProbePassed'
        - $ref: '#/components/schemas/ProbeFailed'
        - $ref: '#/components/schemas/ProbeIncorrect'
      discriminator:
        propertyName: status
        mapping:
          passed: '#/components/schemas/ProbePassed'
          failed: '#/components/schemas/ProbeFailed'
          incorrect: '#/components/schemas/ProbeIncorrect'
    TokenCounts:
      description: >
        lithos `TokenCounts`: five disjoint token buckets. Every token is
        counted in exactly one, so their plain sum is the total. `input`
        excludes cache reads and writes, while `output` excludes reasoning
        tokens when the provider reports them separately. A bucket that is
        absent reads as zero.
      type: object
      properties:
        input:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          description: Prompt tokens that were neither read from nor written to a cache.
        output:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          description: Completion tokens that are not reasoning tokens.
        reasoning:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          description: Completion tokens spent on reasoning, priced at the output rate.
        cache_read:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          description: Prompt tokens served from a provider cache.
        cache_write:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          description: Prompt tokens written into a provider cache.
    ErrorResponseEntry:
      description: A single error entry in an error response.
      type: object
      required:
        - status
        - title
        - detail
      properties:
        status:
          type: string
          description: HTTP status code as a string.
          example: '404'
        title:
          type: string
          description: Short error classification.
          example: Not Found
        detail:
          type: string
          description: Human-readable error description.
          example: Run not found.
        code:
          type: string
          description: Optional machine-readable error code for structured client handling.
          example: access_token_expired
        request_id:
          type: string
          format: uuid
          description: >-
            Server-generated request identifier; matches the x-request-id
            response header.
        meta:
          type: object
          additionalProperties: true
          description: >-
            Optional structured details specific to the error `code`, for
            clients that act on them. Each code documents the members it sets.
    ProbePassed:
      type: object
      required:
        - status
      properties:
        status:
          type: string
          enum:
            - passed
    ProbeFailed:
      type: object
      required:
        - status
        - error
      properties:
        status:
          type: string
          enum:
            - failed
        error:
          $ref: '#/components/schemas/LlmErrorData'
    ProbeIncorrect:
      type: object
      required:
        - status
        - detail
      properties:
        status:
          type: string
          enum:
            - incorrect
        detail:
          type: string
    LlmErrorData:
      description: >-
        Structured lithos-llm failure, subject to the server's disclosure
        policy.
      type: object
      required:
        - kind
        - message
        - retry
      properties:
        kind:
          $ref: '#/components/schemas/LlmErrorKind'
        message:
          type: string
        provider:
          $ref: '#/components/schemas/ProviderId'
        status:
          type: integer
          minimum: 0
          maximum: 65535
        provider_code:
          type: string
        retry:
          $ref: '#/components/schemas/LlmRetryClassification'
        raw_data:
          description: Provider response data; omitted by the model-test endpoint.
        provider_retry_after_millis:
          type: integer
          format: uint64
          minimum: 0
        source_message:
          type: string
          description: Internal source detail; omitted by the model-test endpoint.
    LlmErrorKind:
      description: >-
        The model layer's stable failure category. Known values are
        `configuration`, `model_selection`, `authentication`, `access_denied`,
        `not_found`, `invalid_request`, `context_length`, `rate_limit`,
        `quota_exceeded`, `content_filter`, `server`, `provider`, `network`,
        `timeout`, `stream_decode`, `response_decode`, `resource_limit`,
        `middleware`, and `cancelled`. A category written by a newer model layer
        is carried as its own spelling.
      type: string
      example: rate_limit
    LlmRetryClassification:
      description: Whether repeating the same resolved model call is safe.
      oneOf:
        - $ref: '#/components/schemas/LlmRetryClassificationNever'
        - $ref: '#/components/schemas/LlmRetryClassificationSafe'
        - $ref: '#/components/schemas/LlmRetryClassificationAfter'
      discriminator:
        propertyName: type
        mapping:
          never: '#/components/schemas/LlmRetryClassificationNever'
          safe: '#/components/schemas/LlmRetryClassificationSafe'
          after: '#/components/schemas/LlmRetryClassificationAfter'
    LlmRetryClassificationNever:
      description: Repeating the call cannot succeed.
      type: object
      required:
        - type
      properties:
        type:
          type: string
          enum:
            - never
    LlmRetryClassificationSafe:
      description: Repeating the call is safe on the caller's own schedule.
      type: object
      required:
        - type
      properties:
        type:
          type: string
          enum:
            - safe
    LlmRetryClassificationAfter:
      description: Repeating the call is safe after the given delay.
      type: object
      required:
        - type
        - after_millis
      properties:
        type:
          type: string
          enum:
            - after
        after_millis:
          type: integer
          format: uint64
          minimum: 0
          description: The delay in milliseconds.
  headers:
    XRequestId:
      description: >
        Server-generated request identifier emitted on every response and
        referenced on standard error responses for correlating client errors
        with server logs.
      schema:
        type: string
        format: uuid
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: opaque
      description: >
        Raw dev token passed as `Authorization: Bearer fabro_dev_...` when
        `server.auth.methods` includes `dev-token`.
    SessionCookie:
      type: apiKey
      in: cookie
      name: __fabro_session
      description: >
        Private session cookie issued after a successful web login. The server
        verifies and decodes the cookie before authenticating the request.

````

This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.