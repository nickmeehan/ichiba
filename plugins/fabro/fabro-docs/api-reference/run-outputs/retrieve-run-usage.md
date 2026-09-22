> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Retrieve Run Usage

> Returns token counts and costs broken down by stage and model for a specific run.



## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/runs/{id}/usage
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
  /api/v1/runs/{id}/usage:
    get:
      tags:
        - Run Outputs
      summary: Retrieve Run Usage
      description: >-
        Returns token counts and costs broken down by stage and model for a
        specific run.
      operationId: retrieveRunUsage
      parameters:
        - $ref: '#/components/parameters/RunId'
      responses:
        '200':
          description: Usage data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/RunUsage'
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
    RunUsage:
      description: Complete usage breakdown for a single run.
      type: object
      required:
        - stages
        - totals
        - by_model
      properties:
        stages:
          type: array
          description: >-
            Per-node usage breakdown. Each row sums usage and runtime across all
            visits of that node.
          items:
            $ref: '#/components/schemas/RunUsageStage'
        totals:
          $ref: '#/components/schemas/RunUsageTotals'
        by_model:
          type: array
          description: Usage grouped by model.
          items:
            $ref: '#/components/schemas/UsageByModel'
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
    RunUsageStage:
      description: >-
        Token counts and cost for one workflow node within a run. Rows are
        grouped by node; usage and timing sum every visit of that node.
      type: object
      required:
        - stage
        - model
        - usage
        - timing
      properties:
        stage:
          $ref: '#/components/schemas/UsageStageRef'
        model:
          description: >-
            Latest usage-bearing visit model for this node; null when no visit
            used an LLM model.
          oneOf:
            - $ref: '#/components/schemas/UsageModelRef'
            - type: 'null'
        usage:
          $ref: '#/components/schemas/Usage'
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
    RunUsageTotals:
      description: Aggregate usage totals across all stages of a run.
      type: object
      required:
        - timing
        - usage
      properties:
        timing:
          $ref: '#/components/schemas/RunTiming'
          description: |
            Run-level timing rollup. `wall_time_ms` is summed across stage
            visits; active timing sums work across visits.
        usage:
          $ref: '#/components/schemas/Usage'
          description: >-
            Tokens and cost summed across every stage visit. The cost is known
            only when every visit that used tokens was priced.
    UsageByModel:
      description: Usage grouped by model.
      type: object
      required:
        - model
        - stages
        - usage
      properties:
        model:
          $ref: '#/components/schemas/UsageModelRef'
        stages:
          type: integer
          description: Number of usage-bearing stage visits that used this model.
          example: 2
        usage:
          $ref: '#/components/schemas/Usage'
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
    UsageStageRef:
      description: Reference to a workflow node in a usage stage row.
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
    UsageModelRef:
      description: >-
        Provider-qualified model identity a usage is grouped under. Carries the
        requested speed tier because providers price tiers differently.
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
            - $ref: '#/components/schemas/Speed'
            - type: 'null'
    Usage:
      description: >-
        lithos `Usage`: token counts and, when known, what they cost. `cost` is
        absent when there is no cost data, never zero. A sum has a cost only
        when every part that used tokens was priced; its `source` is the parts'
        shared source, or `application` when they differ.
      type: object
      required:
        - tokens
      properties:
        tokens:
          $ref: '#/components/schemas/TokenCounts'
        cost:
          $ref: '#/components/schemas/Cost'
    StageTiming:
      description: |
        Timing breakdown for one stage visit. Fields are all milliseconds.
        `wall_time_ms` is elapsed clock time; `inference_time_ms` is Fabro-
        observed LLM request/stream elapsed time; `tool_time_ms` is tool or
        command execution elapsed time; `active_time_ms` equals
        `inference_time_ms + tool_time_ms`.

        For a terminal stage these come from the worker's own stopwatch and are
        authoritative. For a stage still in flight they are a live estimate
        reconstructed from the event log, and `active_time_ms` is clamped to
        `wall_time_ms`. The estimate is replaced by the authoritative
        breakdown when the stage reaches a terminal event.
      type: object
      required:
        - wall_time_ms
        - inference_time_ms
        - tool_time_ms
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

        For a running run, stages still in flight contribute a live estimate
        rather than nothing, so wall and active both advance continuously.
        Unlike `StageTiming`, active is not clamped to wall here — concurrent
        branches can legitimately sum past run wall time.
      type: object
      required:
        - wall_time_ms
        - inference_time_ms
        - tool_time_ms
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
    Speed:
      description: 'lithos `Speed`: the requested latency or cost tier.'
      type: string
      enum:
        - fast
        - balanced
        - economical
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
    Cost:
      description: 'lithos `Cost`: a USD amount in micros and where it came from.'
      type: object
      required:
        - usd_micros
        - source
      properties:
        usd_micros:
          type: integer
          format: uint64
          minimum: 0
        source:
          $ref: '#/components/schemas/CostSource'
    CostSource:
      type: string
      description: >
        Where a cost came from: `catalog` (estimated from catalog prices),
        `provider` (the provider's own reported cost), or `application` (a sum
        the caller assembled from differently sourced parts).
      enum:
        - catalog
        - provider
        - application
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