> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Create automation

> Creates a new automation definition.



## OpenAPI

````yaml /api-reference/fabro-api.yaml post /api/v1/automations
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
  /api/v1/automations:
    post:
      tags:
        - Automations
      summary: Create automation
      description: Creates a new automation definition.
      operationId: createAutomation
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateAutomationRequest'
      responses:
        '201':
          description: Automation created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Automation'
        '400':
          description: Malformed JSON request body
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '409':
          description: Automation id already exists
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
components:
  schemas:
    CreateAutomationRequest:
      description: Request body for creating an automation.
      type: object
      additionalProperties: false
      required:
        - id
        - name
        - environment_id
        - target
        - workflow
        - triggers
      properties:
        id:
          type: string
          pattern: ^[a-z0-9][a-z0-9-]{0,62}$
          example: nightly-deps
        name:
          type: string
          example: Nightly dependency update
        description:
          type:
            - string
            - 'null'
          example: Keeps dependencies fresh.
        environment_id:
          type: string
          description: >-
            Server-managed Docker or Daytona environment selected when the
            automation fires.
          example: daytona-smoke
        target:
          $ref: '#/components/schemas/RunTarget'
        workflow:
          type: string
          description: Workflow slug or path resolved in the selected repository checkout.
          example: dependency-update
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
        - environment_id
        - last_error
        - target
        - workflow
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
        environment_id:
          type:
            - string
            - 'null'
          description: |
            Server-managed Docker or Daytona environment selected when the
            automation fires. Null only for an incomplete definition migrated
            from a release that predated environment selection.
          example: daytona-smoke
        last_error:
          type:
            - string
            - 'null'
          description: >-
            Most recent scheduled-run failure, cleared after a scheduled run is
            queued successfully.
        target:
          $ref: '#/components/schemas/RunTarget'
        workflow:
          type: string
          description: Workflow slug or path resolved in the selected repository checkout.
          example: dependency-update
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
    RunTarget:
      description: Workspace content and location requested for a run.
      oneOf:
        - $ref: '#/components/schemas/GitRunTarget'
        - $ref: '#/components/schemas/NoneRunTarget'
        - $ref: '#/components/schemas/FolderRunTarget'
      discriminator:
        propertyName: kind
        mapping:
          git:
            $ref: '#/components/schemas/GitRunTarget'
          none:
            $ref: '#/components/schemas/NoneRunTarget'
          folder:
            $ref: '#/components/schemas/FolderRunTarget'
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
    GitRunTarget:
      description: >-
        Public github.com repository target. The branch names the attached
        working branch. An optional tag selects a release at worker start, and
        an optional exact SHA is authoritative when both are present.
      type: object
      additionalProperties: false
      required:
        - kind
        - repo
        - branch
      properties:
        kind:
          type: string
          enum:
            - git
        repo:
          type: string
          description: GitHub repository slug in `owner/name` form.
          example: acme/my-app
        branch:
          type: string
          description: Required attached working branch name, preserved exactly.
          example: feature/foo
        tag:
          type: string
          minLength: 1
          description: >-
            Optional bare tag name. Prefixes such as `refs/tags/` and `tags/`
            are rejected. Without `sha`, the worker resolves this tag when the
            sandbox starts and fails if it is unavailable.
          example: v1.2.3
        sha:
          type: string
          pattern: ^[0-9A-Fa-f]{40}$
          description: >-
            Optional exact commit. The server lowercase-normalizes its syntax
            but does not resolve it, prove branch ancestry, or prove that it
            matches an accompanying tag. When present, this exact commit wins.
    NoneRunTarget:
      description: >-
        Empty workspace with no repository. Docker and Daytona accept this
        target and suppress cloning even when workflow settings enable it. Local
        environments reject it; Local scratch allocation is a separate future
        capability.
      type: object
      additionalProperties: false
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - none
    FolderRunTarget:
      description: >-
        Existing directory on the Fabro server, executed in place by a Local
        environment. The submitted path must be absolute and name an existing
        directory; Fabro resolves symlinks and persists its canonical UTF-8
        path. This target is intended for trusted single-tenant deployments.
        Docker and Daytona environments always reject it. This target does not
        add Local Git cloning or Local scratch workspaces. Folder runs execute
        in place without Fabro Git checkpoints, so fork and rewind are
        unavailable.
      type: object
      additionalProperties: false
      required:
        - kind
        - path
      properties:
        kind:
          type: string
          enum:
            - folder
        path:
          type: string
          minLength: 1
          description: Absolute path on the Fabro server, not on the API caller's machine.
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