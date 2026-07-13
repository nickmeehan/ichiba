> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# List Run Questions

> Returns pending human-in-the-loop questions for a run. Questions are generated when the workflow needs user input to proceed.



## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/runs/{id}/questions
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
  /api/v1/runs/{id}/questions:
    get:
      tags:
        - Human-in-the-Loop
      summary: List Run Questions
      description: >-
        Returns pending human-in-the-loop questions for a run. Questions are
        generated when the workflow needs user input to proceed.
      operationId: listRunQuestions
      parameters:
        - $ref: '#/components/parameters/RunId'
        - $ref: '#/components/parameters/PageLimit'
        - $ref: '#/components/parameters/PageOffset'
      responses:
        '200':
          description: Array of pending questions
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PaginatedApiQuestionList'
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
    PaginatedApiQuestionList:
      description: Paginated list of pending questions.
      type: object
      required:
        - data
        - meta
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/ApiQuestion'
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
    ApiQuestion:
      description: A pending human-in-the-loop question generated by a workflow stage.
      type: object
      required:
        - id
        - text
        - stage
        - question_type
        - options
        - allow_freeform
      properties:
        id:
          type: string
          description: Unique question identifier.
          example: q-001
        text:
          type: string
          description: The question text displayed to the user.
          example: Should we proceed with the proposed changes?
        stage:
          type: string
          description: Workflow stage identifier that produced the question.
          example: gate
        question_type:
          $ref: '#/components/schemas/QuestionType'
        options:
          type: array
          description: >-
            Available options for selection-based questions. Empty for freeform
            questions.
          items:
            $ref: '#/components/schemas/InterviewOption'
        allow_freeform:
          type: boolean
          description: >-
            Whether the user may provide freeform text in addition to selecting
            options.
          example: true
        timeout_seconds:
          type:
            - number
            - 'null'
          format: double
          description: Timeout for the question when configured by the workflow.
          example: 30
        context_display:
          type:
            - string
            - 'null'
          description: Optional contextual text shown alongside the question.
          example: Latest draft
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
    QuestionType:
      description: The interaction type of a human-in-the-loop question.
      type: string
      enum:
        - yes_no
        - multiple_choice
        - multi_select
        - freeform
        - confirmation
    InterviewOption:
      description: Option stored with an interview question in the event log.
      type: object
      required:
        - key
        - label
      properties:
        key:
          type: string
          description: Machine-readable option key used when submitting an answer.
        label:
          type: string
          description: Human-readable label displayed to the user.
        description:
          type:
            - string
            - 'null'
          description: Optional untrusted model-authored option description for display.
        preview:
          type:
            - string
            - 'null'
          description: >-
            Optional untrusted model-authored option preview captured for
            clients.
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