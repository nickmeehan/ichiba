> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Replace environment

> Replaces an environment definition when `If-Match` matches the current
environment revision. The path id is authoritative; the request body
omits `id`.




## OpenAPI

````yaml /api-reference/fabro-api.yaml put /api/v1/environments/{id}
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
  /api/v1/environments/{id}:
    put:
      tags:
        - Environments
      summary: Replace environment
      description: |
        Replaces an environment definition when `If-Match` matches the current
        environment revision. The path id is authoritative; the request body
        omits `id`.
      operationId: replaceEnvironment
      parameters:
        - $ref: '#/components/parameters/EnvironmentId'
        - $ref: '#/components/parameters/IfMatch'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ReplaceEnvironmentRequest'
      responses:
        '200':
          description: Environment replaced
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Environment'
        '400':
          description: >-
            Malformed JSON request body, invalid environment id, or invalid
            revision header
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: Environment not found
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '409':
          description: Environment revision mismatch or protected environment conflict
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '422':
          description: Environment failed domain validation
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
        '500':
          description: Environment store operation failed
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
components:
  parameters:
    EnvironmentId:
      name: id
      in: path
      required: true
      description: Unique environment identifier.
      schema:
        type: string
        pattern: ^[a-z0-9][a-z0-9-]{0,62}$
      example: docker
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
    ReplaceEnvironmentRequest:
      description: >-
        Request body for replacing a server-managed environment. The path id is
        authoritative.
      type: object
      additionalProperties: false
      required:
        - provider
        - image
        - resources
        - network
        - lifecycle
        - labels
        - env
      properties:
        provider:
          $ref: '#/components/schemas/EnvironmentProvider'
        cwd:
          type:
            - string
            - 'null'
          description: >-
            Local-provider command working directory for this environment.
            Docker and Daytona ignore this value.
          example: /srv/fabro/workspaces/team-a
        image:
          $ref: '#/components/schemas/EnvironmentApiImageSettings'
        resources:
          $ref: '#/components/schemas/EnvironmentResourcesSettings'
        network:
          $ref: '#/components/schemas/EnvironmentNetworkSettings'
        lifecycle:
          $ref: '#/components/schemas/EnvironmentLifecycleSettings'
        labels:
          $ref: '#/components/schemas/StringMap'
        env:
          type: object
          additionalProperties:
            $ref: '#/components/schemas/InterpString'
    Environment:
      description: Public server-managed environment definition.
      type: object
      additionalProperties: false
      required:
        - id
        - revision
        - provider
        - image
        - resources
        - network
        - lifecycle
        - labels
        - env
      properties:
        id:
          type: string
          pattern: ^[a-z0-9][a-z0-9-]{0,62}$
          example: docker
        revision:
          type: string
          pattern: ^[0-9a-f]{64}$
          description: Stable revision used with `If-Match` for optimistic concurrency.
          example: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
        provider:
          $ref: '#/components/schemas/EnvironmentProvider'
        cwd:
          type:
            - string
            - 'null'
          description: >-
            Local-provider command working directory for this environment.
            Docker and Daytona ignore this value.
          example: /srv/fabro/workspaces/team-a
        image:
          $ref: '#/components/schemas/EnvironmentApiImageSettings'
        resources:
          $ref: '#/components/schemas/EnvironmentResourcesSettings'
        network:
          $ref: '#/components/schemas/EnvironmentNetworkSettings'
        lifecycle:
          $ref: '#/components/schemas/EnvironmentLifecycleSettings'
        labels:
          $ref: '#/components/schemas/StringMap'
        env:
          type: object
          additionalProperties:
            $ref: '#/components/schemas/InterpString'
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
    EnvironmentProvider:
      description: Desired environment provider.
      type: string
      enum:
        - local
        - docker
        - daytona
    EnvironmentApiImageSettings:
      description: >-
        REST-safe environment image settings. Dockerfile sources are
        inline-only; local paths are rejected by the REST API.
      type: object
      additionalProperties: false
      required:
        - docker
        - dockerfile
      properties:
        docker:
          type:
            - string
            - 'null'
        dockerfile:
          oneOf:
            - $ref: '#/components/schemas/EnvironmentApiDockerfileSourceInline'
            - type: 'null'
    EnvironmentResourcesSettings:
      type: object
      required:
        - cpu
        - memory
        - disk
      properties:
        cpu:
          type:
            - integer
            - 'null'
          format: int32
        memory:
          type:
            - string
            - 'null'
        disk:
          type:
            - string
            - 'null'
    EnvironmentNetworkSettings:
      type: object
      required:
        - mode
        - allow
      properties:
        mode:
          $ref: '#/components/schemas/EnvironmentNetworkMode'
        allow:
          type: array
          items:
            type: string
    EnvironmentLifecycleSettings:
      type: object
      required:
        - preserve
        - stop_on_terminal
        - auto_stop
      properties:
        preserve:
          type: boolean
        stop_on_terminal:
          type: boolean
        auto_stop:
          type:
            - string
            - 'null'
    StringMap:
      type: object
      additionalProperties:
        type: string
    InterpString:
      description: Resolved config string that may contain env interpolation tokens.
      type: string
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
    EnvironmentApiDockerfileSourceInline:
      type: object
      additionalProperties: false
      required:
        - type
        - value
      properties:
        type:
          type: string
          enum:
            - inline
        value:
          type: string
    EnvironmentNetworkMode:
      type: string
      enum:
        - allow_all
        - block
        - cidr_allow_list
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