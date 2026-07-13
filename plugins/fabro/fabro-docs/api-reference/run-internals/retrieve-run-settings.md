> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Retrieve Run Settings

> Returns the persisted dense `WorkflowSettings` snapshot used to launch this run.



## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/runs/{id}/settings
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
  /api/v1/runs/{id}/settings:
    get:
      tags:
        - Run Internals
      summary: Retrieve Run Settings
      description: >-
        Returns the persisted dense `WorkflowSettings` snapshot used to launch
        this run.
      operationId: retrieveRunSettings
      parameters:
        - $ref: '#/components/parameters/RunId'
      responses:
        '200':
          description: Run settings
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/WorkflowSettings'
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
    WorkflowSettings:
      description: |
        The persisted dense `WorkflowSettings` snapshot used for a specific run.
        This matches the resolved run settings recorded at launch time.
      type: object
      required:
        - project
        - workflow
        - environments
        - run
      properties:
        project:
          $ref: '#/components/schemas/ProjectNamespace'
        workflow:
          $ref: '#/components/schemas/WorkflowNamespace'
        environments:
          type: object
          additionalProperties:
            $ref: '#/components/schemas/EnvironmentSettings'
        run:
          $ref: '#/components/schemas/RunNamespace'
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
    ProjectNamespace:
      type: object
      required:
        - name
        - description
        - metadata
      properties:
        name:
          type:
            - string
            - 'null'
        description:
          type:
            - string
            - 'null'
        metadata:
          $ref: '#/components/schemas/StringMap'
    WorkflowNamespace:
      type: object
      required:
        - name
        - description
        - graph
        - metadata
      properties:
        name:
          type:
            - string
            - 'null'
        description:
          type:
            - string
            - 'null'
        graph:
          type: string
        metadata:
          $ref: '#/components/schemas/StringMap'
    EnvironmentSettings:
      type: object
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
          $ref: '#/components/schemas/EnvironmentImageSettings'
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
    RunNamespace:
      type: object
      required:
        - goal
        - working_dir
        - metadata
        - inputs
        - model
        - git
        - prepare
        - execution
        - checkpoint
        - clone
        - run_branch
        - meta_branch
        - environment
        - notifications
        - interviews
        - agent
        - hooks
        - scm
        - pull_request
        - artifacts
        - integrations
      properties:
        goal:
          oneOf:
            - $ref: '#/components/schemas/RunGoal'
            - type: 'null'
        working_dir:
          oneOf:
            - $ref: '#/components/schemas/InterpString'
            - type: 'null'
        metadata:
          $ref: '#/components/schemas/StringMap'
        inputs:
          type: object
          additionalProperties:
            $ref: '#/components/schemas/TomlValue'
        model:
          $ref: '#/components/schemas/RunModelSettings'
        git:
          $ref: '#/components/schemas/RunGitSettings'
        prepare:
          $ref: '#/components/schemas/RunPrepareSettings'
        execution:
          $ref: '#/components/schemas/RunExecutionSettings'
        checkpoint:
          $ref: '#/components/schemas/RunCheckpointSettings'
        clone:
          $ref: '#/components/schemas/RunCloneSettings'
        run_branch:
          $ref: '#/components/schemas/RunBranchSettings'
        meta_branch:
          $ref: '#/components/schemas/RunMetaBranchSettings'
        environment:
          $ref: '#/components/schemas/RunEnvironmentSettings'
        notifications:
          type: object
          additionalProperties:
            $ref: '#/components/schemas/NotificationRouteSettings'
        interviews:
          $ref: '#/components/schemas/RunInterviewsSettings'
        agent:
          $ref: '#/components/schemas/RunAgentSettings'
        hooks:
          type: array
          items:
            $ref: '#/components/schemas/HookDefinition'
        scm:
          $ref: '#/components/schemas/RunScmSettings'
        pull_request:
          oneOf:
            - $ref: '#/components/schemas/PullRequestSettings'
            - type: 'null'
        artifacts:
          $ref: '#/components/schemas/ArtifactsSettings'
        integrations:
          $ref: '#/components/schemas/RunIntegrationsSettings'
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
    StringMap:
      type: object
      additionalProperties:
        type: string
    EnvironmentProvider:
      description: Desired environment provider.
      type: string
      enum:
        - local
        - docker
        - daytona
    EnvironmentImageSettings:
      type: object
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
            - $ref: '#/components/schemas/DockerfileSource'
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
    InterpString:
      description: Resolved config string that may contain env interpolation tokens.
      type: string
    RunGoal:
      oneOf:
        - $ref: '#/components/schemas/RunGoalInline'
        - $ref: '#/components/schemas/RunGoalFile'
    TomlValue:
      description: Arbitrary TOML-compatible value.
    RunModelSettings:
      type: object
      required:
        - provider
        - name
        - fallbacks
      properties:
        provider:
          type:
            - string
            - 'null'
        name:
          type:
            - string
            - 'null'
        fallbacks:
          type: array
          items:
            $ref: '#/components/schemas/ModelRef'
    RunGitSettings:
      type: object
      required:
        - author
      properties:
        author:
          oneOf:
            - $ref: '#/components/schemas/GitAuthorSettings'
            - type: 'null'
    RunPrepareSettings:
      type: object
      required:
        - steps
        - timeout_ms
      properties:
        steps:
          type: array
          items:
            $ref: '#/components/schemas/PreparedStep'
        timeout_ms:
          type: integer
          format: int64
    RunExecutionSettings:
      type: object
      required:
        - mode
        - approval
      properties:
        mode:
          $ref: '#/components/schemas/RunMode'
        approval:
          $ref: '#/components/schemas/ApprovalMode'
    RunCheckpointSettings:
      type: object
      required:
        - exclude_globs
        - skip_git_hooks
      properties:
        exclude_globs:
          type: array
          items:
            type: string
        skip_git_hooks:
          type: boolean
          default: false
          description: |
            When true, Fabro-managed run-branch checkpoint commits bypass
            local Git commit hooks. Does not affect Fabro `[[run.hooks]]`
            or metadata-branch snapshots. Defaults to false.
    RunCloneSettings:
      type: object
      required:
        - enabled
      properties:
        enabled:
          type: boolean
    RunBranchSettings:
      type: object
      required:
        - enabled
        - push
      properties:
        enabled:
          type: boolean
        push:
          type: boolean
    RunMetaBranchSettings:
      type: object
      required:
        - enabled
        - push
      properties:
        enabled:
          type: boolean
        push:
          type: boolean
    RunEnvironmentSettings:
      type: object
      required:
        - id
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
          $ref: '#/components/schemas/EnvironmentImageSettings'
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
    NotificationRouteSettings:
      type: object
      required:
        - enabled
        - provider
        - events
        - slack
      properties:
        enabled:
          type: boolean
        provider:
          type:
            - string
            - 'null'
        events:
          type: array
          items:
            type: string
        slack:
          oneOf:
            - $ref: '#/components/schemas/NotificationProviderSettings'
            - type: 'null'
    RunInterviewsSettings:
      type: object
      required:
        - provider
        - slack
      properties:
        provider:
          type:
            - string
            - 'null'
        slack:
          oneOf:
            - $ref: '#/components/schemas/InterviewProviderSettings'
            - type: 'null'
    RunAgentSettings:
      type: object
      required:
        - permissions
        - mcps
      properties:
        permissions:
          oneOf:
            - $ref: '#/components/schemas/AgentPermissions'
            - type: 'null'
        mcps:
          type: object
          additionalProperties:
            $ref: '#/components/schemas/McpServerSettings'
    HookDefinition:
      type: object
      required:
        - name
        - event
        - command
        - matcher
        - blocking
        - timeout_ms
        - sandbox
      properties:
        name:
          type:
            - string
            - 'null'
        event:
          $ref: '#/components/schemas/HookEvent'
        command:
          type:
            - string
            - 'null'
        type:
          type:
            - string
            - 'null'
          enum:
            - command
            - http
            - prompt
            - agent
            - null
        url:
          type:
            - string
            - 'null'
        headers:
          oneOf:
            - $ref: '#/components/schemas/StringMap'
            - type: 'null'
          description: >-
            Optional HTTP headers for an http hook. Values support `{{ env.NAME
            }}` interpolation, scoped to the names listed in `allowed_env_vars`;
            a token for any other env var fails to resolve and the hook blocks
            (fail-closed).
        allowed_env_vars:
          type: array
          items:
            type: string
          description: >-
            Allowlist of environment variable names that an http hook header may
            read via `{{ env.NAME }}`. An empty list (the default) permits no
            env vars in headers.
        tls:
          $ref: '#/components/schemas/TlsMode'
        prompt:
          type:
            - string
            - 'null'
        model:
          type:
            - string
            - 'null'
        max_tool_rounds:
          type:
            - integer
            - 'null'
          format: int32
        matcher:
          type:
            - string
            - 'null'
        blocking:
          type:
            - boolean
            - 'null'
        timeout_ms:
          type:
            - integer
            - 'null'
          format: int64
        sandbox:
          type:
            - boolean
            - 'null'
    RunScmSettings:
      type: object
      required:
        - provider
        - owner
        - repository
        - github
      properties:
        provider:
          type:
            - string
            - 'null'
        owner:
          type:
            - string
            - 'null'
        repository:
          type:
            - string
            - 'null'
        github:
          oneOf:
            - $ref: '#/components/schemas/ScmGitHubSettings'
            - type: 'null'
    PullRequestSettings:
      type: object
      required:
        - enabled
        - draft
        - auto_merge
        - merge_strategy
      properties:
        enabled:
          type: boolean
        draft:
          type: boolean
        auto_merge:
          type: boolean
        merge_strategy:
          $ref: '#/components/schemas/MergeMethod'
    ArtifactsSettings:
      type: object
      required:
        - include
      properties:
        include:
          type: array
          items:
            type: string
    RunIntegrationsSettings:
      type: object
      required:
        - github
      properties:
        github:
          $ref: '#/components/schemas/RunIntegrationsGithubSettings'
    DockerfileSource:
      oneOf:
        - $ref: '#/components/schemas/DockerfileSourceInline'
        - $ref: '#/components/schemas/DockerfileSourcePath'
    EnvironmentNetworkMode:
      type: string
      enum:
        - allow_all
        - block
        - cidr_allow_list
    RunGoalInline:
      type: object
      required:
        - type
        - value
      properties:
        type:
          type: string
          enum:
            - inline
        value:
          $ref: '#/components/schemas/InterpString'
    RunGoalFile:
      type: object
      required:
        - type
        - value
      properties:
        type:
          type: string
          enum:
            - file
        value:
          $ref: '#/components/schemas/InterpString'
    ModelRef:
      type: string
    GitAuthorSettings:
      type: object
      required:
        - name
        - email
      properties:
        name:
          type:
            - string
            - 'null'
        email:
          type:
            - string
            - 'null'
    PreparedStep:
      description: |
        A single resolved prepare step. The runnable part preserves the
        script-vs-argv distinction via the `type` discriminator: a `script`
        is a raw shell snippet kept verbatim, while a `command` is an argv
        whose elements are shell-quoted and joined at the run boundary (after
        `{{ env.* }}` resolution) so an interpolated value cannot inject shell
        syntax. Optional per-step `env` is shared by both shapes.
      type: object
      required:
        - type
      oneOf:
        - $ref: '#/components/schemas/PreparedScriptStep'
        - $ref: '#/components/schemas/PreparedCommandStep'
      discriminator:
        propertyName: type
        mapping:
          script:
            $ref: '#/components/schemas/PreparedScriptStep'
          command:
            $ref: '#/components/schemas/PreparedCommandStep'
    RunMode:
      type: string
      enum:
        - normal
        - dry_run
    ApprovalMode:
      type: string
      enum:
        - prompt
        - auto
    NotificationProviderSettings:
      type: object
      required:
        - channel
      properties:
        channel:
          type:
            - string
            - 'null'
    InterviewProviderSettings:
      type: object
      required:
        - channel
      properties:
        channel:
          type:
            - string
            - 'null'
    AgentPermissions:
      type: string
      enum:
        - read-only
        - read-write
        - full
    McpServerSettings:
      type: object
      required:
        - name
        - transport
        - startup_timeout_secs
        - tool_timeout_secs
      properties:
        name:
          type: string
        transport:
          $ref: '#/components/schemas/McpTransport'
        startup_timeout_secs:
          type: integer
          format: int64
        tool_timeout_secs:
          type: integer
          format: int64
    HookEvent:
      type: string
      enum:
        - run_start
        - run_complete
        - run_failed
        - stage_start
        - stage_complete
        - stage_failed
        - stage_retrying
        - edge_selected
        - parallel_start
        - parallel_complete
        - sandbox_ready
        - sandbox_cleanup
        - checkpoint_saved
        - pre_tool_use
        - post_tool_use
        - post_tool_use_failure
    TlsMode:
      type: string
      enum:
        - verify
        - no_verify
        - 'off'
    ScmGitHubSettings:
      type: object
    MergeMethod:
      description: GitHub merge method for a pull request.
      type: string
      enum:
        - merge
        - squash
        - rebase
    RunIntegrationsGithubSettings:
      type: object
      required:
        - permissions
      properties:
        permissions:
          type: object
          additionalProperties:
            type: string
    DockerfileSourceInline:
      type: object
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
    DockerfileSourcePath:
      type: object
      required:
        - type
        - path
      properties:
        type:
          type: string
          enum:
            - path
        path:
          type: string
    PreparedScriptStep:
      type: object
      required:
        - type
        - script
      properties:
        type:
          type: string
          enum:
            - script
        script:
          type: string
        env:
          $ref: '#/components/schemas/StringMap'
    PreparedCommandStep:
      type: object
      required:
        - type
        - command
      properties:
        type:
          type: string
          enum:
            - command
        command:
          type: array
          items:
            type: string
        env:
          $ref: '#/components/schemas/StringMap'
    McpTransport:
      description: |
        MCP server transport configuration. The `type` field selects stdio,
        HTTP, or sandbox transport. Unknown `type` discriminator values are
        reported as domain validation errors with HTTP 422.
      oneOf:
        - $ref: '#/components/schemas/McpTransportStdio'
        - $ref: '#/components/schemas/McpTransportHttp'
        - $ref: '#/components/schemas/McpTransportSandbox'
      discriminator:
        propertyName: type
        mapping:
          stdio:
            $ref: '#/components/schemas/McpTransportStdio'
          http:
            $ref: '#/components/schemas/McpTransportHttp'
          sandbox:
            $ref: '#/components/schemas/McpTransportSandbox'
    McpTransportStdio:
      description: Stdio transport that launches a local MCP server subprocess.
      type: object
      additionalProperties: false
      required:
        - type
        - command
        - env
      properties:
        type:
          type: string
          enum:
            - stdio
        command:
          type: array
          minItems: 1
          description: Command and arguments used to launch the MCP server.
          items:
            type: string
        env:
          $ref: '#/components/schemas/StringMap'
    McpTransportHttp:
      description: HTTP transport that connects to a remote MCP server URL.
      type: object
      additionalProperties: false
      required:
        - type
        - url
        - headers
      properties:
        type:
          type: string
          enum:
            - http
        protocol:
          $ref: '#/components/schemas/McpHttpProtocol'
        url:
          type: string
          format: uri
        headers:
          $ref: '#/components/schemas/StringMap'
    McpTransportSandbox:
      description: >-
        Sandbox transport that launches the MCP server inside the run sandbox
        and connects over HTTP.
      type: object
      additionalProperties: false
      required:
        - type
        - command
        - port
        - env
      properties:
        type:
          type: string
          enum:
            - sandbox
        protocol:
          $ref: '#/components/schemas/McpHttpProtocol'
        command:
          type: array
          minItems: 1
          description: Command and arguments used to launch the in-sandbox MCP server.
          items:
            type: string
        port:
          type: integer
          format: int32
          minimum: 1
          maximum: 65535
        env:
          $ref: '#/components/schemas/StringMap'
    McpHttpProtocol:
      description: Wire protocol used by HTTP and sandbox MCP transports.
      type: string
      enum:
        - streamable_http
        - sse
      default: streamable_http
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