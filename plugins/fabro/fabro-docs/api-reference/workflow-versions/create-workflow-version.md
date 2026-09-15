> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Create Workflow Version

> Validates and stores an immutable workflow package in content-addressed storage. Repeating the same canonical content returns the same identifier. Requires an authenticated user or a worker token with the `agent:run_tools` capability. Ordinary worker tokens cannot register versions. Registration creates no run and starts no execution.



## OpenAPI

````yaml /api-reference/fabro-api.yaml post /api/v1/workflow-versions
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
  /api/v1/workflow-versions:
    post:
      tags:
        - Workflow Versions
      summary: Create Workflow Version
      description: >-
        Validates and stores an immutable workflow package in content-addressed
        storage. Repeating the same canonical content returns the same
        identifier. Requires an authenticated user or a worker token with the
        `agent:run_tools` capability. Ordinary worker tokens cannot register
        versions. Registration creates no run and starts no execution.
      operationId: createWorkflowVersion
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/WorkflowVersion'
      responses:
        '201':
          description: Workflow version stored or already present
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CreateWorkflowVersionResponse'
        '400':
          description: Malformed JSON (`invalid_json`)
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '413':
          description: Request body exceeds 2 MiB (`workflow_version_too_large`)
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '422':
          description: >-
            Invalid workflow content (`workflow_version_invalid`) or an absent,
            invalid, or non-canonical dependency
            (`workflow_version_dependency_not_found`)
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Workflow version storage failed
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
components:
  schemas:
    WorkflowVersion:
      description: >-
        Complete immutable package for one rooted workflow. It contains at most
        512 files and 512 workflow dependencies, each file is at most 512 KiB of
        UTF-8 content, and its compact canonical JSON representation is at most
        2 MiB.
      type: object
      additionalProperties: false
      required:
        - entrypoint
        - files
        - workflow_dependencies
      properties:
        entrypoint:
          $ref: '#/components/schemas/WorkflowPath'
        files:
          type: object
          description: >-
            Workflow-local text files keyed by canonical path. Keys receive
            stricter domain validation than OpenAPI can express; each value is
            limited to 512 KiB of UTF-8 bytes.
          maxProperties: 512
          propertyNames:
            $ref: '#/components/schemas/WorkflowPath'
          additionalProperties:
            type: string
        workflow_dependencies:
          type: object
          description: >-
            Exact stored workflow-version IDs keyed by resolved child-workflow
            path. Keys receive stricter domain validation than OpenAPI can
            express.
          maxProperties: 512
          propertyNames:
            $ref: '#/components/schemas/WorkflowPath'
          additionalProperties:
            $ref: '#/components/schemas/WorkflowVersionId'
    CreateWorkflowVersionResponse:
      description: Identity of the stored immutable workflow version.
      type: object
      additionalProperties: false
      required:
        - workflow_version_id
      properties:
        workflow_version_id:
          $ref: '#/components/schemas/WorkflowVersionId'
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
    WorkflowPath:
      description: >-
        Canonical portable path inside one workflow version. Paths are UTF-8,
        relative, at most 240 bytes and 16 components, and cannot contain empty,
        dot, parent, backslash, control, tilde-root, or drive-letter segments.
        Map keys receive stricter byte and structural validation in the domain
        model than OpenAPI can express.
      type: string
      minLength: 1
      maxLength: 240
      example: graphs/main.fabro
    WorkflowVersionId:
      description: >-
        SHA-256 identity of validated canonical workflow-version bytes. Hex
        input is case-insensitive; Fabro emits the canonical lowercase form.
      type: string
      pattern: ^[0-9A-Fa-f]{64}$
      example: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
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