> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Retrieve Run Billing

> Returns token counts and billed totals broken down by stage and model for a specific run.



## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/runs/{id}/billing
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
  /api/v1/runs/{id}/billing:
    get:
      tags:
        - Run Outputs
      summary: Retrieve Run Billing
      description: >-
        Returns token counts and billed totals broken down by stage and model
        for a specific run.
      operationId: retrieveRunBilling
      parameters:
        - $ref: '#/components/parameters/RunId'
      responses:
        '200':
          description: Billing data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/RunBilling'
        '404':
          description: Run not found
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
components:
  parameters:
    RunId:
      name: id
      in: path
      required: true
      description: Unique run identifier (ULID).
      schema:
        type: string
      example: 01JNQVR7M0EJ5GKAT2SC4ERS1Z
  schemas:
    RunBilling:
      description: Complete billing breakdown for a single run.
      type: object
      required:
        - stages
        - totals
        - by_model
      properties:
        stages:
          type: array
          description: >-
            Per-node billing breakdown. Each row sums billing and runtime across
            all visits of that node.
          items:
            $ref: '#/components/schemas/RunBillingStage'
        totals:
          $ref: '#/components/schemas/RunBillingTotals'
        by_model:
          type: array
          description: Billing grouped by model.
          items:
            $ref: '#/components/schemas/BillingByModel'
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
    RunBillingStage:
      description: >-
        Token counts and billed totals for one workflow node within a run. Rows
        are grouped by node; billing and timing sum every visit of that node.
      type: object
      required:
        - stage
        - model
        - billing
        - timing
      properties:
        stage:
          $ref: '#/components/schemas/BillingStageRef'
        model:
          description: >-
            Latest usage-bearing visit model for this node; null when no visit
            used an LLM model.
          oneOf:
            - $ref: '#/components/schemas/BillingModelRef'
            - type: 'null'
        billing:
          $ref: '#/components/schemas/BilledTokenCounts'
        timing:
          $ref: '#/components/schemas/StageTiming'
          description: |
            Per-node timing summed across every visit. `wall_time_ms` is the
            sum of visit wall times; the active breakdown sums work timing.
        started_at:
          type:
            - string
            - 'null'
          format: date-time
          description: Wall-clock time the latest attempt of this stage started, if known.
          example: '2026-04-29T12:34:56Z'
        state:
          oneOf:
            - $ref: '#/components/schemas/StageState'
            - type: 'null'
          description: >-
            Lifecycle state of the stage. Use to detect in-flight rows for
            client-side runtime ticking.
    RunBillingTotals:
      description: Aggregate billing totals across all stages of a run.
      type: object
      required:
        - timing
        - input_tokens
        - output_tokens
        - total_tokens
        - reasoning_tokens
        - cache_read_tokens
        - cache_write_tokens
      properties:
        timing:
          $ref: '#/components/schemas/RunTiming'
          description: |
            Run-level timing rollup. `wall_time_ms` is summed across stage
            visits; active timing sums work across visits.
        input_tokens:
          type: integer
          description: Total input tokens consumed.
          example: 71540
        output_tokens:
          type: integer
          description: Total output tokens generated.
          example: 21080
        total_tokens:
          type: integer
          description: Total tokens aggregated across all billing categories.
          example: 92620
        reasoning_tokens:
          type: integer
          description: Total reasoning tokens.
          example: 3400
        cache_read_tokens:
          type: integer
          description: Total cache read tokens.
          example: 22000
        cache_write_tokens:
          type: integer
          description: Total cache write tokens.
          example: 4500
        total_usd_micros:
          type:
            - integer
            - 'null'
          format: int64
          description: Total billed USD amount in micros.
          example: 2260000
    BillingByModel:
      description: Billing statistics grouped by model.
      type: object
      required:
        - model
        - stages
        - billing
      properties:
        model:
          $ref: '#/components/schemas/BillingModelRef'
        stages:
          type: integer
          description: Number of usage-bearing stage visits that used this model.
          example: 2
        billing:
          $ref: '#/components/schemas/BilledTokenCounts'
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
    BillingStageRef:
      description: Reference to a workflow node in a billing stage row.
      type: object
      required:
        - id
        - name
      properties:
        id:
          type: string
          description: Stage identifier (slug).
          example: propose-changes
        name:
          type: string
          description: Human-readable stage name.
          example: Propose Changes
    BillingModelRef:
      description: Provider-qualified billing model identity used for cost estimates.
      type: object
      required:
        - provider
        - model_id
      properties:
        provider:
          $ref: '#/components/schemas/ProviderId'
        model_id:
          type: string
        speed:
          oneOf:
            - $ref: '#/components/schemas/BillingSpeed'
            - type: 'null'
    BilledTokenCounts:
      description: Token counts with optional billed USD micros totals.
      type: object
      required:
        - input_tokens
        - output_tokens
        - total_tokens
        - reasoning_tokens
        - cache_read_tokens
        - cache_write_tokens
      properties:
        input_tokens:
          type: integer
          format: int64
          description: Number of input tokens consumed.
          example: 28640
        output_tokens:
          type: integer
          format: int64
          description: Number of output tokens generated.
          example: 8750
        total_tokens:
          type: integer
          format: int64
          description: Total billable tokens aggregated across categories.
          example: 37390
        reasoning_tokens:
          type: integer
          format: int64
          description: Number of reasoning tokens.
          example: 1200
        cache_read_tokens:
          type: integer
          format: int64
          description: Number of cache read tokens.
          example: 4800
        cache_write_tokens:
          type: integer
          format: int64
          description: Number of cache write tokens.
          example: 1500
        total_usd_micros:
          type:
            - integer
            - 'null'
          format: int64
          description: Billed USD amount in micros.
          example: 720000
    StageTiming:
      description: |
        Timing breakdown for one stage visit. Fields are all milliseconds.
        `wall_time_ms` is elapsed clock time; `inference_time_ms` is Fabro-
        observed LLM request/stream elapsed time; `tool_time_ms` is tool or
        command execution elapsed time; `active_time_ms` equals
        `inference_time_ms + tool_time_ms`.
      type: object
      required:
        - wall_time_ms
        - active_time_ms
      properties:
        wall_time_ms:
          type: integer
          format: uint64
          minimum: 0
          example: 1500
        inference_time_ms:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          example: 900
        tool_time_ms:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          example: 200
        active_time_ms:
          type: integer
          format: uint64
          minimum: 0
          description: Equals `inference_time_ms + tool_time_ms`.
          example: 1100
    StageState:
      description: Lifecycle projection state of a workflow stage.
      type: string
      enum:
        - pending
        - running
        - retrying
        - succeeded
        - partially_succeeded
        - failed
        - skipped
        - cancelled
    RunTiming:
      description: |
        Timing rollup for an entire run. Active fields sum work across stage
        visits, so `active_time_ms` can exceed `wall_time_ms` when parallel
        branches run concurrently.
      type: object
      required:
        - wall_time_ms
        - active_time_ms
      properties:
        wall_time_ms:
          type: integer
          format: uint64
          minimum: 0
          example: 420000
        inference_time_ms:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          example: 120000
        tool_time_ms:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          example: 60000
        active_time_ms:
          type: integer
          format: uint64
          minimum: 0
          description: Equals `inference_time_ms + tool_time_ms`.
          example: 180000
    ProviderId:
      description: LLM provider identifier.
      type: string
      example: anthropic
    BillingSpeed:
      description: Optional provider-specific model speed tier used for cost estimates.
      type: string
      enum:
        - standard
        - fast
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