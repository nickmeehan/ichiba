> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# List variables

> Returns non-sensitive variables, including values.



## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/variables
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
  /api/v1/variables:
    get:
      tags:
        - Variables
      summary: List variables
      description: Returns non-sensitive variables, including values.
      operationId: listVariables
      responses:
        '200':
          description: Variable list
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/VariableListResponse'
components:
  schemas:
    VariableListResponse:
      description: List of stored variables.
      type: object
      required:
        - data
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/Variable'
    Variable:
      description: Non-sensitive variable available for run config interpolation.
      type: object
      required:
        - name
        - value
        - created_at
        - updated_at
      properties:
        name:
          type: string
          pattern: ^[A-Za-z_][A-Za-z0-9_]*$
          description: Env-style variable name.
          example: DEPLOY_ENV
        value:
          type: string
          description: Variable value.
          example: production
        description:
          type: string
          description: Optional operator-facing description of the variable.
        created_at:
          type: string
          format: date-time
          description: When the variable was first stored.
        updated_at:
          type: string
          format: date-time
          description: When the variable was last updated.
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