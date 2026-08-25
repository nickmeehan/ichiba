> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Create Run Pull Request

> Durably requests creation of a pull request for a completed run. The
server generates the pull request content and creates the GitHub pull
request after this request returns. Poll the URL in the Location
response header until the creation succeeds or fails.

If a creation is already pending for the run, the response returns
that creation unchanged; any different `model` or `force` values in
the new request are ignored.




## OpenAPI

````yaml /api-reference/fabro-api.yaml post /api/v1/runs/{id}/pull_request
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
  /api/v1/runs/{id}/pull_request:
    post:
      tags:
        - Runs
      summary: Create Run Pull Request
      description: |
        Durably requests creation of a pull request for a completed run. The
        server generates the pull request content and creates the GitHub pull
        request after this request returns. Poll the URL in the Location
        response header until the creation succeeds or fails.

        If a creation is already pending for the run, the response returns
        that creation unchanged; any different `model` or `force` values in
        the new request are ignored.
      operationId: createRunPullRequest
      parameters:
        - $ref: '#/components/parameters/RunId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateRunPullRequestRequest'
      responses:
        '202':
          description: Pull request creation was durably accepted
          headers:
            Location:
              description: URL for the latest pull request creation on this run.
              schema:
                type: string
                format: uri-reference
            Retry-After:
              description: Suggested number of seconds before polling the creation status.
              schema:
                type: integer
                minimum: 0
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PullRequestCreation'
        '400':
          description: Pull request creation does not apply to this run
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: Run not found
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '409':
          description: >-
            Pull request already exists for this run. Clients can GET
            /runs/{id}/pull_request to retrieve the stored record.
          headers:
            x-request-id:
              $ref: '#/components/headers/XRequestId'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '503':
          description: GitHub integration is unavailable on the server
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
    CreateRunPullRequestRequest:
      description: Request body for creating a run pull request.
      type: object
      required:
        - force
      properties:
        force:
          type: boolean
          description: >-
            Create the pull request even if the run did not finish with
            succeeded or partially_succeeded.
          example: false
        model:
          type:
            - string
            - 'null'
          description: Optional model override for generating the pull request description.
          example: claude-sonnet-4-6
    PullRequestCreation:
      description: >-
        Durable status for the latest explicit pull request creation requested
        for a run.
      type: object
      required:
        - id
        - status
        - model
        - force
        - requested_at
        - updated_at
      properties:
        id:
          $ref: '#/components/schemas/PullRequestCreationId'
        status:
          $ref: '#/components/schemas/PullRequestCreationStatus'
        model:
          type: string
          description: Resolved model identifier used to generate the pull request content.
        force:
          type: boolean
          description: >-
            Whether creation was allowed for a run without a successful
            conclusion.
        requested_at:
          type: string
          format: date-time
        updated_at:
          type: string
          format: date-time
        pull_request:
          oneOf:
            - $ref: '#/components/schemas/PullRequestLink'
            - type: 'null'
        error:
          type:
            - string
            - 'null'
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
    PullRequestCreationId:
      description: Stable identifier for one explicit pull request creation request.
      type: string
      example: 01KYYK70WTZT2E551P3H5P0059
    PullRequestCreationStatus:
      description: Durable state of a pull request creation request.
      type: string
      enum:
        - pending
        - succeeded
        - failed
    PullRequestLink:
      description: Minimal GitHub pull request link associated with a run.
      type: object
      required:
        - owner
        - repo
        - number
        - html_url
      properties:
        owner:
          type: string
          example: fabro-sh
        repo:
          type: string
          example: fabro
        number:
          type: integer
          example: 123
        html_url:
          type: string
          format: uri
          description: Computed GitHub web URL for the pull request.
          example: https://github.com/fabro-sh/fabro/pull/123
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