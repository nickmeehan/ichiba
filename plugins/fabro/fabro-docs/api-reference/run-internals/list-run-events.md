> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# List Run Events

> Returns a paginated JSON list of stored run events.



## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/runs/{id}/events
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
  /api/v1/runs/{id}/events:
    get:
      tags:
        - Run Internals
      summary: List Run Events
      description: Returns a paginated JSON list of stored run events.
      operationId: listRunEvents
      parameters:
        - $ref: '#/components/parameters/RunId'
        - $ref: '#/components/parameters/SinceSeq'
        - $ref: '#/components/parameters/EventLimit'
      responses:
        '200':
          description: Paginated list of run events
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PaginatedEventList'
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
    SinceSeq:
      name: since_seq
      in: query
      required: false
      description: First event sequence number to include.
      schema:
        type: integer
        minimum: 1
        default: 1
      example: 42
    EventLimit:
      name: limit
      in: query
      required: false
      description: Maximum number of events to return.
      schema:
        type: integer
        minimum: 1
        maximum: 1000
        default: 100
      example: 100
  schemas:
    PaginatedEventList:
      description: Paginated list of stored run events.
      type: object
      required:
        - data
        - meta
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/EventEnvelope'
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
    EventEnvelope:
      description: >
        Stored event envelope with assigned sequence number. On the wire the
        envelope is flattened: seq sits alongside the RunEvent payload fields at
        the top level of the JSON object.
      allOf:
        - $ref: '#/components/schemas/EventSeq'
        - $ref: '#/components/schemas/RunEvent'
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
    EventSeq:
      description: Assigned sequence number component of a stored event envelope.
      type: object
      required:
        - seq
      properties:
        seq:
          type: integer
          description: Assigned event sequence number.
          example: 42
    RunEvent:
      description: >
        Internal RunEvent-compatible JSON payload. The server validates this
        body by deserializing into the typed RunEvent struct.
      type: object
      required:
        - id
        - ts
        - run_id
        - event
      properties:
        id:
          type: string
        ts:
          type: string
          format: date-time
        run_id:
          type: string
        node_id:
          type:
            - string
            - 'null'
        node_label:
          type:
            - string
            - 'null'
        stage_id:
          type:
            - string
            - 'null'
          description: Stage execution identity, formatted as "{node_id}@{visit}".
        parallel_group_id:
          type:
            - string
            - 'null'
          description: >
            Durable identity of one execution of a parallel node, formatted as
            "{node_id}@{visit}".
        parallel_branch_id:
          type:
            - string
            - 'null'
          description: >
            Durable identity of one branch within a parallel execution,
            formatted as "{parallel_group_id}:{index}".
        session_id:
          type:
            - string
            - 'null'
        parent_session_id:
          type:
            - string
            - 'null'
        tool_call_id:
          type:
            - string
            - 'null'
          description: >
            Stable identifier for a tool call, present on agent.tool.* events
            and other durable events that directly describe the same tool call.
        actor:
          oneOf:
            - $ref: '#/components/schemas/Principal'
            - type: 'null'
        event:
          type: string
          description: Event type discriminator.
          example: stage.started
        properties:
          type: object
          additionalProperties: true
      additionalProperties: true
    Principal:
      oneOf:
        - $ref: '#/components/schemas/PrincipalUser'
        - $ref: '#/components/schemas/PrincipalWorker'
        - $ref: '#/components/schemas/PrincipalWebhook'
        - $ref: '#/components/schemas/PrincipalSlack'
        - $ref: '#/components/schemas/PrincipalAgent'
        - $ref: '#/components/schemas/PrincipalSystem'
      discriminator:
        propertyName: kind
        mapping:
          user:
            $ref: '#/components/schemas/PrincipalUser'
          worker:
            $ref: '#/components/schemas/PrincipalWorker'
          webhook:
            $ref: '#/components/schemas/PrincipalWebhook'
          slack:
            $ref: '#/components/schemas/PrincipalSlack'
          agent:
            $ref: '#/components/schemas/PrincipalAgent'
          system:
            $ref: '#/components/schemas/PrincipalSystem'
    PrincipalUser:
      type: object
      required:
        - kind
        - identity
        - login
        - auth_method
      properties:
        kind:
          type: string
          enum:
            - user
        identity:
          $ref: '#/components/schemas/IdpIdentity'
        login:
          type: string
        auth_method:
          $ref: '#/components/schemas/AuthMethod'
        avatar_url:
          type:
            - string
            - 'null'
    PrincipalWorker:
      type: object
      required:
        - kind
        - run_id
      properties:
        kind:
          type: string
          enum:
            - worker
        run_id:
          type: string
    PrincipalWebhook:
      type: object
      required:
        - kind
        - delivery_id
      properties:
        kind:
          type: string
          enum:
            - webhook
        delivery_id:
          type: string
    PrincipalSlack:
      type: object
      required:
        - kind
        - team_id
        - user_id
      properties:
        kind:
          type: string
          enum:
            - slack
        team_id:
          type: string
        user_id:
          type: string
        user_name:
          type:
            - string
            - 'null'
    PrincipalAgent:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - agent
        session_id:
          type:
            - string
            - 'null'
        parent_session_id:
          type:
            - string
            - 'null'
        model:
          type:
            - string
            - 'null'
    PrincipalSystem:
      type: object
      required:
        - kind
        - system_kind
      properties:
        kind:
          type: string
          enum:
            - system
        system_kind:
          $ref: '#/components/schemas/SystemActorKind'
    IdpIdentity:
      type: object
      required:
        - issuer
        - subject
      properties:
        issuer:
          type: string
        subject:
          type: string
    AuthMethod:
      description: Runtime user authentication method.
      type: string
      enum:
        - github
        - dev_token
    SystemActorKind:
      type: string
      enum:
        - engine
        - watchdog
        - timeout
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