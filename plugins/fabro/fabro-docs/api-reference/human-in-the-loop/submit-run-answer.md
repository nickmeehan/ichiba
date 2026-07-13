> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Submit Run Answer

> Submits an answer to a pending question. The answer can be freeform text or a selected option key, depending on the question type.



## OpenAPI

````yaml /api-reference/fabro-api.yaml post /api/v1/runs/{id}/questions/{qid}/answer
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
  /api/v1/runs/{id}/questions/{qid}/answer:
    post:
      tags:
        - Human-in-the-Loop
      summary: Submit Run Answer
      description: >-
        Submits an answer to a pending question. The answer can be freeform text
        or a selected option key, depending on the question type.
      operationId: submitRunAnswer
      parameters:
        - $ref: '#/components/parameters/RunId'
        - $ref: '#/components/parameters/QuestionId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SubmitAnswerRequest'
      responses:
        '204':
          description: Answer accepted
        '400':
          description: Invalid option key
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
          description: Question no longer exists or already answered
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
    QuestionId:
      name: qid
      in: path
      required: true
      description: Unique identifier of a pending question.
      schema:
        type: string
      example: q-001
  schemas:
    SubmitAnswerRequest:
      description: >
        Request body for submitting an answer to a pending question. The `kind`
        discriminator determines which answer shape is submitted.
      oneOf:
        - $ref: '#/components/schemas/SubmitAnswerYesRequest'
        - $ref: '#/components/schemas/SubmitAnswerNoRequest'
        - $ref: '#/components/schemas/SubmitAnswerSelectedRequest'
        - $ref: '#/components/schemas/SubmitAnswerMultiSelectedRequest'
        - $ref: '#/components/schemas/SubmitAnswerTextRequest'
      discriminator:
        propertyName: kind
        mapping:
          'yes':
            $ref: '#/components/schemas/SubmitAnswerYesRequest'
          'no':
            $ref: '#/components/schemas/SubmitAnswerNoRequest'
          selected:
            $ref: '#/components/schemas/SubmitAnswerSelectedRequest'
          multi_selected:
            $ref: '#/components/schemas/SubmitAnswerMultiSelectedRequest'
          text:
            $ref: '#/components/schemas/SubmitAnswerTextRequest'
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
    SubmitAnswerYesRequest:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - 'yes'
          description: Affirmative answer for yes/no and confirmation questions.
    SubmitAnswerNoRequest:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - 'no'
          description: Negative answer for yes/no questions.
    SubmitAnswerSelectedRequest:
      type: object
      required:
        - kind
        - option_key
      properties:
        kind:
          type: string
          enum:
            - selected
          description: Single selected option answer.
        option_key:
          type: string
          description: Key of the selected option.
          example: option_a
    SubmitAnswerMultiSelectedRequest:
      type: object
      required:
        - kind
        - option_keys
      properties:
        kind:
          type: string
          enum:
            - multi_selected
          description: Multiple selected option answer.
        option_keys:
          type: array
          items:
            type: string
          description: Keys of selected options.
          example:
            - option_a
            - option_b
    SubmitAnswerTextRequest:
      type: object
      required:
        - kind
        - text
      properties:
        kind:
          type: string
          enum:
            - text
          description: Freeform text answer.
        text:
          type: string
          description: Freeform answer text.
          example: Yes, proceed with the changes.
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