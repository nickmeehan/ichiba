> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# List Models

> Returns a paginated list of available LLM models from the built-in catalog.



## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/models
openapi: 3.1.0
info:
  title: Fabro Run API
  version: 0.1.0
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
  - name: Billing
    description: Token counts and billed totals
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
  /api/v1/models:
    get:
      tags:
        - Models
      summary: List Models
      description: >-
        Returns a paginated list of available LLM models from the built-in
        catalog.
      operationId: listModels
      parameters:
        - $ref: '#/components/parameters/ModelProviderFilter'
        - $ref: '#/components/parameters/ModelQueryFilter'
        - $ref: '#/components/parameters/PageLimit'
        - $ref: '#/components/parameters/PageOffset'
      responses:
        '200':
          description: Paginated list of models
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PaginatedModelList'
        '400':
          description: Invalid filter value
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
components:
  parameters:
    ModelProviderFilter:
      name: provider
      in: query
      required: false
      description: >-
        Filter models by provider ID. Unknown provider IDs return an empty
        result set.
      schema:
        $ref: '#/components/schemas/ProviderId'
      example: anthropic
    ModelQueryFilter:
      name: query
      in: query
      required: false
      description: >-
        Case-insensitive substring search across `id`, `display_name`, and
        `aliases`.
      schema:
        type: string
      example: opus
    PageLimit:
      name: page[limit]
      in: query
      required: false
      description: Maximum number of items to return per page.
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20
      example: 20
    PageOffset:
      name: page[offset]
      in: query
      required: false
      description: Number of items to skip before returning results.
      schema:
        type: integer
        minimum: 0
        default: 0
      example: 0
  schemas:
    PaginatedModelList:
      description: Paginated list of models.
      type: object
      required:
        - data
        - meta
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/Model'
        meta:
          $ref: '#/components/schemas/PaginationMeta'
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
    Model:
      description: An available LLM model from the built-in catalog.
      type: object
      required:
        - id
        - provider
        - family
        - display_name
        - limits
        - training
        - knowledge_cutoff
        - features
        - costs
        - estimated_output_tps
        - aliases
        - default
        - small_default
        - configured
      properties:
        id:
          type: string
          description: Unique model identifier.
          example: claude-opus-4-6
        provider:
          $ref: '#/components/schemas/ProviderId'
        family:
          type: string
          description: Model family grouping.
          example: claude-4
        display_name:
          type: string
          description: Human-readable model name.
          example: Claude Opus 4.6
        limits:
          $ref: '#/components/schemas/ModelLimits'
        training:
          type:
            - string
            - 'null'
          description: Training data cutoff date (YYYY-MM-DD).
          example: '2025-08-01'
        knowledge_cutoff:
          type:
            - string
            - 'null'
          description: Public knowledge cutoff label, if known.
          example: May 2025
        features:
          $ref: '#/components/schemas/ModelFeatures'
        costs:
          $ref: '#/components/schemas/ModelCosts'
        estimated_output_tps:
          type:
            - number
            - 'null'
          format: double
          description: Estimated output tokens per second.
        aliases:
          type: array
          items:
            type: string
          description: Alternative names that resolve to this model.
          example:
            - opus
        default:
          type: boolean
          description: Whether this is the default model for its provider.
        small_default:
          type: boolean
          description: Whether this is the provider's small/default utility model.
        configured:
          type: boolean
          description: >
            Whether credential material is present for this model's provider on
            the

            server (vault entry or environment variable). Does NOT imply the

            credential is valid or that requests will succeed; call

            `POST /models/{id}/test` to verify usability.
    PaginationMeta:
      description: Pagination metadata included in every paginated response.
      type: object
      required:
        - has_more
      properties:
        has_more:
          type: boolean
          description: Whether additional pages of results are available.
        total:
          type: integer
          format: int64
          minimum: 0
          description: |
            Total number of items matching the current filters. Optional —
            only populated by endpoints that compute the full count cheaply
            (e.g. in-memory filtering). When omitted, clients should rely on
            `has_more` and cursor through pages.
          example: true
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
    ModelLimits:
      description: Token limits for a model.
      type: object
      required:
        - context_window
        - max_output
      properties:
        context_window:
          type: integer
          format: int64
          description: Maximum context window size in tokens.
          example: 1000000
        max_output:
          type:
            - integer
            - 'null'
          format: int64
          description: Maximum output tokens, if known.
          example: 128000
    ModelFeatures:
      description: Capability flags for a model.
      type: object
      required:
        - tools
        - vision
        - reasoning
        - reasoning_effort
        - prompt_cache
        - sampling_params
      properties:
        tools:
          type: boolean
          description: Whether the model supports tool use.
        vision:
          type: boolean
          description: Whether the model supports vision/image inputs.
        reasoning:
          type: boolean
          description: Whether the model supports extended reasoning.
        reasoning_effort:
          $ref: '#/components/schemas/ReasoningEffortFeature'
        prompt_cache:
          type: boolean
          description: Whether the model endpoint supports prompt caching.
        sampling_params:
          type: boolean
          description: >-
            Whether the model accepts classic sampling parameters (temperature,
            top_p).
    ModelCosts:
      description: Pricing per million tokens in USD.
      type: object
      required:
        - input_cost_per_mtok
        - output_cost_per_mtok
        - cache_input_cost_per_mtok
      properties:
        input_cost_per_mtok:
          type:
            - number
            - 'null'
          format: double
          description: Cost per million input tokens in USD.
          example: 15
        output_cost_per_mtok:
          type:
            - number
            - 'null'
          format: double
          description: Cost per million output tokens in USD.
          example: 75
        cache_input_cost_per_mtok:
          type:
            - number
            - 'null'
          format: double
          description: Cost per million cached input tokens in USD.
          example: 1.5
    ReasoningEffortFeature:
      description: >-
        Whether the model endpoint supports a native reasoning-effort parameter.
        `levels` accepts discrete effort levels; `always_adaptive` accepts
        effort levels with natively always-on adaptive thinking; `none` has no
        native effort parameter.
      type: string
      enum:
        - levels
        - always_adaptive
        - none
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