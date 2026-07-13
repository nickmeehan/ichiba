> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Retrieve Run Checkpoint

> Returns the latest checkpoint data for a run, or null if no checkpoint has been recorded yet.



## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/runs/{id}/checkpoint
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
  /api/v1/runs/{id}/checkpoint:
    get:
      tags:
        - Run Internals
      summary: Retrieve Run Checkpoint
      description: >-
        Returns the latest checkpoint data for a run, or null if no checkpoint
        has been recorded yet.
      operationId: retrieveRunCheckpoint
      parameters:
        - $ref: '#/components/parameters/RunId'
      responses:
        '200':
          description: Checkpoint data (null if not yet available)
          content:
            application/json:
              schema:
                oneOf:
                  - $ref: '#/components/schemas/RunCheckpoint'
                  - type: 'null'
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
    RunCheckpoint:
      description: Serializable snapshot of execution state for crash recovery and resume.
      type: object
      required:
        - timestamp
        - current_node
        - completed_nodes
        - node_retries
        - context_values
      properties:
        timestamp:
          type: string
          format: date-time
          description: ISO 8601 timestamp when the checkpoint was created.
        current_node:
          type: string
          description: Identifier of the node being executed at checkpoint time.
        completed_nodes:
          type: array
          items:
            type: string
          description: Identifiers of nodes that have completed execution.
        node_retries:
          type: object
          additionalProperties:
            type: integer
          description: Map of node identifier to retry count.
        context_values:
          type: object
          additionalProperties: true
          description: Key-value context map accumulated during execution.
        node_outcomes:
          type: object
          additionalProperties: true
          description: >-
            Map of node identifier to outcome data for goal gate checks after
            resume.
        next_node_id:
          type: string
          description: The node to resume execution at after this checkpoint.
        git_commit_sha:
          type: string
          description: SHA of the git commit created at this checkpoint.
        loop_failure_signatures:
          type: object
          additionalProperties: true
          description: Failure signature counts within the main loop.
        restart_failure_signatures:
          type: object
          additionalProperties: true
          description: Failure signature counts across loop_restart edges.
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