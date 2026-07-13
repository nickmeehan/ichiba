> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Replace automation

> Replaces an automation definition when `If-Match` matches the current automation revision.



## OpenAPI

````yaml /api-reference/fabro-api.yaml put /api/v1/automations/{id}
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
  /api/v1/automations/{id}:
    put:
      tags:
        - Automations
      summary: Replace automation
      description: >-
        Replaces an automation definition when `If-Match` matches the current
        automation revision.
      operationId: replaceAutomation
      parameters:
        - $ref: '#/components/parameters/AutomationId'
        - $ref: '#/components/parameters/IfMatch'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ReplaceAutomationRequest'
      responses:
        '200':
          description: Automation replaced
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Automation'
        '400':
          description: Malformed JSON request body or invalid revision header
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: Automation not found
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '409':
          description: Automation revision mismatch
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '422':
          description: Automation failed domain validation
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '428':
          description: Missing required `If-Match` header
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
components:
  parameters:
    AutomationId:
      name: id
      in: path
      required: true
      description: Unique automation identifier.
      schema:
        type: string
        pattern: ^[a-z0-9][a-z0-9-]{0,62}$
      example: nightly-deps
    IfMatch:
      name: If-Match
      in: header
      required: true
      description: >-
        Current resource revision used for optimistic concurrency, as returned
        in the `ETag` response header.
      schema:
        type: string
      example: '"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"'
  schemas:
    ReplaceAutomationRequest:
      description: Request body for replacing an automation.
      type: object
      additionalProperties: false
      required:
        - name
        - target
        - triggers
      properties:
        name:
          type: string
          example: Nightly dependency update
        description:
          type:
            - string
            - 'null'
          example: Keeps dependencies fresh.
        target:
          $ref: '#/components/schemas/AutomationTarget'
        triggers:
          type: array
          items:
            $ref: '#/components/schemas/AutomationTrigger'
    Automation:
      description: Public automation definition.
      type: object
      additionalProperties: false
      required:
        - id
        - revision
        - name
        - description
        - target
        - triggers
      properties:
        id:
          type: string
          pattern: ^[a-z0-9][a-z0-9-]{0,62}$
          example: nightly-deps
        revision:
          type: string
          pattern: ^[0-9a-f]{64}$
          description: Stable revision used with `If-Match` for optimistic concurrency.
          example: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
        name:
          type: string
          example: Nightly dependency update
        description:
          type:
            - string
            - 'null'
          example: Keeps dependencies fresh.
        target:
          $ref: '#/components/schemas/AutomationTarget'
        triggers:
          type: array
          items:
            $ref: '#/components/schemas/AutomationTrigger'
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
    AutomationTarget:
      description: Repository and workflow selected by an automation.
      type: object
      additionalProperties: false
      required:
        - repository
        - ref
        - workflow
      properties:
        repository:
          type: string
          description: GitHub repository slug in `owner/repo` form.
          example: fabro-sh/fabro
        ref:
          type: string
          description: Branch, tag, or SHA selector resolved when materializing a run.
          example: main
        workflow:
          type: string
          description: Workflow slug or path resolved in the target repository.
          example: dependency-update
    AutomationTrigger:
      description: |
        Automation trigger configuration. Unknown `type` discriminator values
        are reported by handlers as domain validation errors with HTTP 422.
      oneOf:
        - $ref: '#/components/schemas/AutomationApiTrigger'
        - $ref: '#/components/schemas/AutomationScheduleTrigger'
      discriminator:
        propertyName: type
        mapping:
          api:
            $ref: '#/components/schemas/AutomationApiTrigger'
          schedule:
            $ref: '#/components/schemas/AutomationScheduleTrigger'
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
    AutomationApiTrigger:
      description: Trigger that allows callers to create runs through the automation API.
      type: object
      additionalProperties: false
      required:
        - id
        - type
        - enabled
      properties:
        id:
          type: string
          pattern: ^[a-z0-9][a-z0-9_-]{0,62}$
          example: manual
        type:
          type: string
          enum:
            - api
        enabled:
          type: boolean
          example: true
    AutomationScheduleTrigger:
      description: Cron schedule trigger evaluated in UTC.
      type: object
      additionalProperties: false
      required:
        - id
        - type
        - enabled
        - expression
      properties:
        id:
          type: string
          pattern: ^[a-z0-9][a-z0-9_-]{0,62}$
          example: nightly
        type:
          type: string
          enum:
            - schedule
        enabled:
          type: boolean
          example: true
        expression:
          type: string
          description: Five-field cron expression evaluated in UTC.
          example: 0 3 * * *
  headers:
    ETag:
      description: >-
        Current resource revision for optimistic concurrency. Supply this value
        via `If-Match` on subsequent mutating requests.
      schema:
        type: string
      example: '"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"'
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