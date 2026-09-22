> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# List Run Stages

> Returns the ordered list of stages in a run's workflow graph with their current status and timing. Stages are bounded by the workflow graph size, typically fewer than 20.



## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/runs/{id}/stages
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
  /api/v1/runs/{id}/stages:
    get:
      tags:
        - Run Internals
      summary: List Run Stages
      description: >-
        Returns the ordered list of stages in a run's workflow graph with their
        current status and timing. Stages are bounded by the workflow graph
        size, typically fewer than 20.
      operationId: listRunStages
      parameters:
        - $ref: '#/components/parameters/RunId'
        - $ref: '#/components/parameters/PageLimit'
        - $ref: '#/components/parameters/PageOffset'
      responses:
        '200':
          description: Array of run stages
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PaginatedRunStageList'
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
    PaginatedRunStageList:
      description: Paginated list of run stages.
      type: object
      required:
        - data
        - meta
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/RunStage'
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
    RunStage:
      description: A single stage in a run's workflow graph.
      type: object
      required:
        - id
        - name
        - handler
        - status
        - node_id
        - visit
        - usage
      properties:
        id:
          $ref: '#/components/schemas/StageId'
        name:
          type: string
          description: Human-readable stage name.
          example: Propose Changes
        handler:
          $ref: '#/components/schemas/StageHandler'
        status:
          $ref: '#/components/schemas/StageState'
        wall_time_ms:
          type: integer
          format: uint64
          minimum: 0
          description: >-
            Wall-clock time the latest attempt spent in this stage, in
            milliseconds.
          example: 154000
        node_id:
          type: string
          description: >-
            Node id in the workflow graph; multiple stages with different visits
            share the same node_id.
          example: verify
        visit:
          type: integer
          format: uint32
          minimum: 1
          description: >-
            1-based stage execution ordinal, the numeric component of `id`. It
            increments each time the node produces a new observable execution:
            graph re-entry (loops) and replay of post-checkpoint work after
            resume. Automatic in-place retries do not increment it.
          example: 2
        graph_visit:
          type:
            - integer
            - 'null'
          format: uint32
          minimum: 1
          description: >-
            1-based count of how many times workflow control entered this node
            (drives `max_visits`). Differs from `visit` when a post-checkpoint
            execution is replayed after resume. Absent for stages recorded
            before execution identity was tracked.
          example: 1
        resumed_from_stage_id:
          oneOf:
            - $ref: '#/components/schemas/StageId'
            - type: 'null'
          description: >-
            StageId of the prior post-checkpoint execution superseded by this
            replay after the run was resumed.
          example: verify@1
        parallel_group_id:
          allOf:
            - $ref: '#/components/schemas/StageId'
          description: >-
            Exact StageId of the parent parallel execution. Clients can compare
            this directly with the `id` of a parallel stage. Omitted for stages
            that are not parallel branches.
          example: review_fork@1
        parallel_branch_index:
          type: integer
          format: uint32
          minimum: 0
          description: >-
            Zero-based outgoing-edge index within the parent parallel execution.
            Omitted for stages that are not parallel branches.
          example: 1
        provider_used:
          oneOf:
            - $ref: '#/components/schemas/StageModelUsage'
            - type: 'null'
          description: >-
            Provider, model, and request controls recorded for the latest stage
            attempt.
        started_at:
          type:
            - string
            - 'null'
          format: date-time
          description: Wall-clock time the latest attempt of this stage started, if known.
          example: '2026-04-29T12:34:56Z'
        usage:
          $ref: '#/components/schemas/Usage'
          description: >-
            Usage for this stage execution alone. `cost` sums what lithos-llm
            attached to each answer: the provider's reported cost when there is
            one, otherwise the catalog's price for the route — the same figures
            the `/runs/{id}/usage` rows sum. All-zero counts mean the stage made
            no model calls. Unlike the usage rows, which sum every visit of a
            node, this covers only this visit.
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
    StageId:
      description: Canonical stage execution identifier in `node_id@visit` form.
      type: string
      example: verify@2
    StageHandler:
      description: Canonical workflow stage handler kind.
      type: string
      enum:
        - start
        - exit
        - agent
        - prompt
        - command
        - human
        - conditional
        - parallel
        - parallel.fan_in
        - stack.manager_loop
        - wait
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
    StageModelUsage:
      description: >-
        Provider, model, and request-control metadata recorded for a stage
        attempt.
      type: object
      required:
        - mode
      properties:
        mode:
          type: string
          description: Source of the stage's model usage metadata.
          example: agent
        provider:
          type:
            - string
            - 'null'
          example: openai
        model:
          type:
            - string
            - 'null'
          example: gpt-5.5
        reasoning_effort:
          oneOf:
            - $ref: '#/components/schemas/ReasoningEffort'
            - type: 'null'
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