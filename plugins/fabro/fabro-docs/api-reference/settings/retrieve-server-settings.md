> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Retrieve Server Settings

> Returns the server's current in-memory settings view as the typed `ServerSettings` payload.




## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/settings
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
  /api/v1/settings:
    get:
      tags:
        - Settings
      summary: Retrieve Server Settings
      description: >
        Returns the server's current in-memory settings view as the typed
        `ServerSettings` payload.
      operationId: retrieveServerSettings
      responses:
        '200':
          description: Server settings
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ServerSettings'
components:
  schemas:
    ServerSettings:
      description: Current in-memory server settings view.
      type: object
      required:
        - server
      properties:
        server:
          $ref: '#/components/schemas/ServerNamespace'
    ServerNamespace:
      type: object
      required:
        - listen
        - api
        - web
        - auth
        - sandbox
        - storage
        - artifacts
        - slatedb
        - scheduler
        - logging
        - integrations
      properties:
        listen:
          $ref: '#/components/schemas/ServerListenSettings'
        api:
          $ref: '#/components/schemas/ServerApiSettings'
        web:
          $ref: '#/components/schemas/ServerWebSettings'
        auth:
          $ref: '#/components/schemas/ServerAuthSettings'
        sandbox:
          $ref: '#/components/schemas/ServerSandboxSettings'
        storage:
          $ref: '#/components/schemas/ServerStorageSettings'
        artifacts:
          $ref: '#/components/schemas/ServerArtifactsSettings'
        slatedb:
          $ref: '#/components/schemas/ServerSlateDbSettings'
        scheduler:
          $ref: '#/components/schemas/ServerSchedulerSettings'
        logging:
          $ref: '#/components/schemas/ServerLoggingSettings'
        integrations:
          $ref: '#/components/schemas/ServerIntegrationsSettings'
    ServerListenSettings:
      oneOf:
        - $ref: '#/components/schemas/ServerListenTcpSettings'
        - $ref: '#/components/schemas/ServerListenUnixSettings'
    ServerApiSettings:
      type: object
      required:
        - url
      properties:
        url:
          type:
            - string
            - 'null'
    ServerWebSettings:
      type: object
      required:
        - enabled
        - url
      properties:
        enabled:
          type: boolean
        url:
          type: string
    ServerAuthSettings:
      type: object
      required:
        - methods
        - github
      properties:
        methods:
          type: array
          items:
            $ref: '#/components/schemas/ServerAuthMethod'
        github:
          $ref: '#/components/schemas/ServerAuthGithubSettings'
    ServerSandboxSettings:
      type: object
      required:
        - providers
      properties:
        providers:
          $ref: '#/components/schemas/ServerSandboxProvidersSettings'
    ServerStorageSettings:
      type: object
      required:
        - root
      properties:
        root:
          type: string
    ServerArtifactsSettings:
      type: object
      required:
        - prefix
        - store
      properties:
        prefix:
          type: string
        store:
          $ref: '#/components/schemas/ObjectStoreSettings'
    ServerSlateDbSettings:
      type: object
      required:
        - prefix
        - store
        - flush_interval
        - disk_cache
      properties:
        prefix:
          type: string
        store:
          $ref: '#/components/schemas/ObjectStoreSettings'
        flush_interval:
          type: string
        disk_cache:
          type: boolean
    ServerSchedulerSettings:
      type: object
      required:
        - max_concurrent_runs
      properties:
        max_concurrent_runs:
          type: integer
    ServerLoggingSettings:
      type: object
      required:
        - level
        - destination
      properties:
        level:
          type:
            - string
            - 'null'
        destination:
          $ref: '#/components/schemas/LogDestination'
    ServerIntegrationsSettings:
      type: object
      required:
        - github
        - slack
      properties:
        github:
          $ref: '#/components/schemas/GithubIntegrationSettings'
        slack:
          $ref: '#/components/schemas/SlackIntegrationSettings'
    ServerListenTcpSettings:
      type: object
      required:
        - type
        - address
      properties:
        type:
          type: string
          enum:
            - tcp
        address:
          type: string
    ServerListenUnixSettings:
      type: object
      required:
        - type
        - path
      properties:
        type:
          type: string
          enum:
            - unix
        path:
          type: string
    ServerAuthMethod:
      type: string
      enum:
        - dev-token
        - github
    ServerAuthGithubSettings:
      type: object
      required:
        - allowed_usernames
      properties:
        allowed_usernames:
          type: array
          items:
            type: string
    ServerSandboxProvidersSettings:
      type: object
      required:
        - local
        - docker
        - daytona
      properties:
        local:
          $ref: '#/components/schemas/ServerSandboxProviderSettings'
        docker:
          $ref: '#/components/schemas/ServerSandboxProviderSettings'
        daytona:
          $ref: '#/components/schemas/ServerSandboxProviderSettings'
    ObjectStoreSettings:
      oneOf:
        - $ref: '#/components/schemas/ObjectStoreLocalSettings'
        - $ref: '#/components/schemas/ObjectStoreS3Settings'
    LogDestination:
      type: string
      enum:
        - file
        - stdout
    GithubIntegrationSettings:
      type: object
      required:
        - enabled
        - strategy
        - app_id
        - client_id
        - slug
        - webhooks
      properties:
        enabled:
          type: boolean
        strategy:
          $ref: '#/components/schemas/GithubIntegrationStrategy'
        app_id:
          type:
            - string
            - 'null'
        client_id:
          type:
            - string
            - 'null'
        slug:
          type:
            - string
            - 'null'
        webhooks:
          oneOf:
            - $ref: '#/components/schemas/IntegrationWebhooksSettings'
            - type: 'null'
    SlackIntegrationSettings:
      type: object
      required:
        - enabled
        - default_channel
      properties:
        enabled:
          type: boolean
        default_channel:
          type:
            - string
            - 'null'
    ServerSandboxProviderSettings:
      type: object
      required:
        - enabled
      properties:
        enabled:
          type: boolean
    ObjectStoreLocalSettings:
      type: object
      required:
        - type
        - root
      properties:
        type:
          type: string
          enum:
            - local
        root:
          type: string
    ObjectStoreS3Settings:
      type: object
      required:
        - type
        - bucket
        - region
        - endpoint
        - path_style
      properties:
        type:
          type: string
          enum:
            - s3
        bucket:
          type: string
        region:
          type: string
        endpoint:
          type:
            - string
            - 'null'
        path_style:
          type: boolean
    GithubIntegrationStrategy:
      type: string
      enum:
        - token
        - app
    IntegrationWebhooksSettings:
      type: object
      required:
        - strategy
      properties:
        strategy:
          oneOf:
            - $ref: '#/components/schemas/WebhookStrategy'
            - type: 'null'
    WebhookStrategy:
      type: string
      enum:
        - tailscale_funnel
        - server_url
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