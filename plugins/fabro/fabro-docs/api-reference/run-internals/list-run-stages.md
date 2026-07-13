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
      properties:
        id:
          type: string
          description: StageId in "node_id@visit" form, e.g. verify@2.
          example: verify@2
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
            1-based visit count; bumped each time the workflow re-enters this
            node.
          example: 2
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
            - $ref: '#/components/schemas/BillingSpeed'
            - type: 'null'
    ReasoningEffort:
      description: Native reasoning-effort level requested for an LLM call.
      type: string
      enum:
        - low
        - medium
        - high
        - xhigh
        - max
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