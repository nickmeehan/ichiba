> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Approve Run

> Approves a pending run that requires pre-execution approval and makes it runnable.



## OpenAPI

````yaml /api-reference/fabro-api.yaml post /api/v1/runs/{id}/approve
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
  /api/v1/runs/{id}/approve:
    post:
      tags:
        - Runs
      summary: Approve Run
      description: >-
        Approves a pending run that requires pre-execution approval and makes it
        runnable.
      operationId: approveRun
      parameters:
        - $ref: '#/components/parameters/RunId'
      responses:
        '200':
          description: Run approved
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Run'
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
          description: Run is not pending approval
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
    Run:
      description: Canonical public run shape.
      type: object
      required:
        - id
        - title
        - goal
        - workflow
        - automation
        - repository
        - created_by
        - origin
        - labels
        - lifecycle
        - sandbox
        - models
        - source_directory
        - timestamps
        - timing
        - billing
        - size
        - ask_fabro
        - diff
        - pull_request
        - current_question
        - superseded_by
        - retried_from
        - links
        - children_count
      properties:
        id:
          type: string
        parent_id:
          type:
            - string
            - 'null'
          description: Current orchestration parent run ID, if linked.
        children_count:
          type: integer
          format: uint64
          minimum: 0
          description: >-
            Number of runs currently linked to this run as their orchestration
            parent.
        title:
          type: string
        goal:
          type: string
        workflow:
          $ref: '#/components/schemas/WorkflowRef'
        automation:
          oneOf:
            - $ref: '#/components/schemas/AutomationRef'
            - type: 'null'
        repository:
          oneOf:
            - $ref: '#/components/schemas/RepositoryRef'
            - type: 'null'
        created_by:
          $ref: '#/components/schemas/Principal'
        origin:
          $ref: '#/components/schemas/RunOrigin'
        labels:
          type: object
          additionalProperties:
            type: string
        lifecycle:
          $ref: '#/components/schemas/RunLifecycle'
        sandbox:
          oneOf:
            - $ref: '#/components/schemas/RunSandbox'
            - type: 'null'
        models:
          type: array
          items:
            $ref: '#/components/schemas/RunModel'
        source_directory:
          type:
            - string
            - 'null'
        timestamps:
          $ref: '#/components/schemas/RunTimestamps'
        timing:
          oneOf:
            - $ref: '#/components/schemas/RunTiming'
            - type: 'null'
          description: |
            Run-level timing rollup. Wall time is the run's clock duration;
            active timing sums work across stage visits.
        billing:
          oneOf:
            - $ref: '#/components/schemas/RunBillingSummary'
            - type: 'null'
        size:
          $ref: '#/components/schemas/RunSize'
        ask_fabro:
          $ref: '#/components/schemas/AskFabro'
        diff:
          oneOf:
            - $ref: '#/components/schemas/DiffSummary'
            - type: 'null'
        pull_request:
          oneOf:
            - $ref: '#/components/schemas/PullRequestLink'
            - type: 'null'
        current_question:
          oneOf:
            - $ref: '#/components/schemas/RunQuestion'
            - type: 'null'
        superseded_by:
          type:
            - string
            - 'null'
          description: Run ID that superseded this run via rewind, if any.
        retried_from:
          type:
            - string
            - 'null'
          description: Source run ID when this run was created by manual retry.
        links:
          $ref: '#/components/schemas/RunLinks'
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
    WorkflowRef:
      type: object
      required:
        - slug
        - name
        - graph_name
        - node_count
        - edge_count
      properties:
        slug:
          type:
            - string
            - 'null'
        name:
          type:
            - string
            - 'null'
        graph_name:
          type:
            - string
            - 'null'
        node_count:
          type: integer
          format: int64
          description: Number of nodes in the workflow graph.
        edge_count:
          type: integer
          format: int64
          description: Number of edges in the workflow graph.
    AutomationRef:
      type: object
      required:
        - id
        - name
      properties:
        id:
          type: string
        name:
          type:
            - string
            - 'null'
        trigger_id:
          type:
            - string
            - 'null'
    RepositoryRef:
      description: Durable repository metadata for a run.
      type: object
      required:
        - name
        - origin_url
        - provider
      properties:
        name:
          type: string
          example: fabro-sh/fabro
        origin_url:
          type:
            - string
            - 'null'
          example: https://github.com/fabro-sh/fabro.git
        provider:
          type: string
          enum:
            - github
            - git
            - unknown
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
    RunOrigin:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - api
    RunLifecycle:
      type: object
      required:
        - status
        - approval
        - pending_control
        - queue_position
        - error
        - archived
        - archived_at
      properties:
        status:
          $ref: '#/components/schemas/RunStatus'
        approval:
          oneOf:
            - $ref: '#/components/schemas/RunApproval'
            - type: 'null'
        pending_control:
          oneOf:
            - $ref: '#/components/schemas/RunControlAction'
            - type: 'null'
        queue_position:
          type:
            - integer
            - 'null'
        error:
          oneOf:
            - $ref: '#/components/schemas/RunError'
            - type: 'null'
        archived:
          type: boolean
        archived_at:
          type:
            - string
            - 'null'
          format: date-time
    RunSandbox:
      description: >-
        Sandbox lifecycle record for a run. A run can have a requested sandbox
        plan before it has an initialized sandbox instance.
      type: object
      required:
        - kind
        - plan
      properties:
        kind:
          $ref: '#/components/schemas/RunSandboxKind'
        plan:
          $ref: '#/components/schemas/RunSandboxPlan'
        instance:
          oneOf:
            - $ref: '#/components/schemas/RunSandboxInstance'
            - type: 'null'
          description: Present only when `kind` is `ready`.
        failure:
          oneOf:
            - $ref: '#/components/schemas/RunSandboxFailure'
            - type: 'null'
          description: Present only when `kind` is `failed`.
    RunModel:
      type: object
      required:
        - provider
        - name
      properties:
        provider:
          type:
            - string
            - 'null'
        name:
          type: string
    RunTimestamps:
      type: object
      required:
        - created_at
        - started_at
        - last_event_at
        - completed_at
      properties:
        created_at:
          type: string
          format: date-time
        started_at:
          type:
            - string
            - 'null'
          format: date-time
        last_event_at:
          type:
            - string
            - 'null'
          format: date-time
        completed_at:
          type:
            - string
            - 'null'
          format: date-time
    RunTiming:
      description: |
        Timing rollup for an entire run. Active fields sum work across stage
        visits, so `active_time_ms` can exceed `wall_time_ms` when parallel
        branches run concurrently.
      type: object
      required:
        - wall_time_ms
        - active_time_ms
      properties:
        wall_time_ms:
          type: integer
          format: uint64
          minimum: 0
          example: 420000
        inference_time_ms:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          example: 120000
        tool_time_ms:
          type: integer
          format: uint64
          minimum: 0
          default: 0
          example: 60000
        active_time_ms:
          type: integer
          format: uint64
          minimum: 0
          description: Equals `inference_time_ms + tool_time_ms`.
          example: 180000
    RunBillingSummary:
      type: object
      required:
        - total_usd_micros
      properties:
        total_usd_micros:
          type:
            - integer
            - 'null'
          format: int64
    RunSize:
      type: string
      enum:
        - XS
        - S
        - M
        - L
        - XL
      description: Run size bucket derived from current best-effort billed usage.
    AskFabro:
      description: Readiness and defaults for starting an Ask Fabro session on this run.
      type: object
      required:
        - available
        - unavailable_reason
        - default_model
      properties:
        available:
          type: boolean
        unavailable_reason:
          type:
            - string
            - 'null'
          enum:
            - no_sandbox
            - sandbox_not_ready
            - llm_unconfigured
            - null
        default_model:
          type:
            - string
            - 'null'
    DiffSummary:
      description: Cheap aggregate file and line counts for a run diff.
      type: object
      required:
        - files_changed
        - additions
        - deletions
      properties:
        files_changed:
          type: integer
          description: Total number of changed files, including binary files.
          example: 42
        additions:
          type: integer
          description: Total lines added across text files.
          example: 567
        deletions:
          type: integer
          description: Total lines deleted across text files.
          example: 234
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
    RunQuestion:
      description: A pending human-in-the-loop question summary.
      type: object
      required:
        - text
      properties:
        text:
          type: string
          description: Question text.
          example: Accept or push for another round?
    RunLinks:
      type: object
      required:
        - web
      properties:
        web:
          type:
            - string
            - 'null'
          format: uri
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
    RunStatus:
      description: >
        Execution status of a run. Archive state is represented separately on
        `RunLifecycle.archived` so terminal status payloads remain intact.
      oneOf:
        - $ref: '#/components/schemas/RunStatusSubmitted'
        - $ref: '#/components/schemas/RunStatusPending'
        - $ref: '#/components/schemas/RunStatusRunnable'
        - $ref: '#/components/schemas/RunStatusStarting'
        - $ref: '#/components/schemas/RunStatusRunning'
        - $ref: '#/components/schemas/RunStatusBlocked'
        - $ref: '#/components/schemas/RunStatusPaused'
        - $ref: '#/components/schemas/RunStatusRemoving'
        - $ref: '#/components/schemas/RunStatusSucceeded'
        - $ref: '#/components/schemas/RunStatusFailed'
        - $ref: '#/components/schemas/RunStatusDead'
      discriminator:
        propertyName: kind
        mapping:
          submitted:
            $ref: '#/components/schemas/RunStatusSubmitted'
          pending:
            $ref: '#/components/schemas/RunStatusPending'
          runnable:
            $ref: '#/components/schemas/RunStatusRunnable'
          starting:
            $ref: '#/components/schemas/RunStatusStarting'
          running:
            $ref: '#/components/schemas/RunStatusRunning'
          blocked:
            $ref: '#/components/schemas/RunStatusBlocked'
          paused:
            $ref: '#/components/schemas/RunStatusPaused'
          removing:
            $ref: '#/components/schemas/RunStatusRemoving'
          succeeded:
            $ref: '#/components/schemas/RunStatusSucceeded'
          failed:
            $ref: '#/components/schemas/RunStatusFailed'
          dead:
            $ref: '#/components/schemas/RunStatusDead'
    RunApproval:
      description: >-
        Pre-execution approval state for runs that require one-time human
        approval.
      type: object
      required:
        - state
        - requested_at
        - decided_at
        - denial_reason
      properties:
        state:
          $ref: '#/components/schemas/RunApprovalState'
        requested_at:
          type: string
          format: date-time
        decided_at:
          type:
            - string
            - 'null'
          format: date-time
        denial_reason:
          type:
            - string
            - 'null'
    RunControlAction:
      description: Run control action requested by the API.
      type: string
      enum:
        - cancel
        - pause
        - unpause
    RunError:
      description: Error information for a failed run.
      type: object
      required:
        - message
      properties:
        message:
          type: string
          description: Error message.
          example: Stage 'apply-changes' exceeded maximum retries.
    RunSandboxKind:
      description: Lifecycle state for a run sandbox request.
      type: string
      enum:
        - planned
        - initializing
        - ready
        - failed
    RunSandboxPlan:
      description: Requested sandbox provider and base image/snapshot from run settings.
      type: object
      required:
        - provider
      properties:
        provider:
          $ref: '#/components/schemas/SandboxProviderKind'
        image:
          type:
            - string
            - 'null'
        snapshot:
          type:
            - string
            - 'null'
    RunSandboxInstance:
      description: Initialized sandbox provider and runtime metadata.
      type: object
      required:
        - provider
        - runtime
      properties:
        provider:
          $ref: '#/components/schemas/SandboxProviderKind'
        image:
          type:
            - string
            - 'null'
        snapshot:
          type:
            - string
            - 'null'
        runtime:
          $ref: '#/components/schemas/RunSandboxRuntime'
    RunSandboxFailure:
      description: Sandbox initialization failure details.
      type: object
      required:
        - provider
        - error
        - causes
        - duration_ms
      properties:
        provider:
          type: string
          description: Provider reported by the sandbox initialization event.
        error:
          type: string
        causes:
          type: array
          items:
            type: string
        duration_ms:
          type: integer
          format: uint64
          minimum: 0
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
    RunStatusSubmitted:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - submitted
    RunStatusPending:
      type: object
      required:
        - kind
        - reason
      properties:
        kind:
          type: string
          enum:
            - pending
        reason:
          $ref: '#/components/schemas/PendingReason'
    RunStatusRunnable:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - runnable
    RunStatusStarting:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - starting
    RunStatusRunning:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - running
    RunStatusBlocked:
      type: object
      required:
        - kind
        - blocked_reason
      properties:
        kind:
          type: string
          enum:
            - blocked
        blocked_reason:
          $ref: '#/components/schemas/BlockedReason'
    RunStatusPaused:
      type: object
      required:
        - kind
        - prior_block
      properties:
        kind:
          type: string
          enum:
            - paused
        prior_block:
          oneOf:
            - $ref: '#/components/schemas/BlockedReason'
            - type: 'null'
    RunStatusRemoving:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - removing
    RunStatusSucceeded:
      type: object
      required:
        - kind
        - reason
      properties:
        kind:
          type: string
          enum:
            - succeeded
        reason:
          $ref: '#/components/schemas/SuccessReason'
    RunStatusFailed:
      type: object
      required:
        - kind
        - reason
      properties:
        kind:
          type: string
          enum:
            - failed
        reason:
          $ref: '#/components/schemas/FailureReason'
    RunStatusDead:
      type: object
      required:
        - kind
      properties:
        kind:
          type: string
          enum:
            - dead
    RunApprovalState:
      description: State of a run's pre-execution approval request.
      type: string
      enum:
        - pending
        - approved
        - denied
    SandboxProviderKind:
      description: Sandbox provider discriminator.
      type: string
      enum:
        - local
        - docker
        - daytona
    RunSandboxRuntime:
      type: object
      required:
        - id
        - working_directory
        - repo_cloned
        - clone_origin_url
        - clone_branch
      properties:
        id:
          type: string
        working_directory:
          type: string
        repo_cloned:
          type:
            - boolean
            - 'null'
        clone_origin_url:
          type:
            - string
            - 'null'
        clone_branch:
          type:
            - string
            - 'null'
        workspace_root:
          type:
            - string
            - 'null'
        repos_root:
          type:
            - string
            - 'null'
        primary_repo_path:
          type:
            - string
            - 'null'
        primary_repo_link:
          type:
            - string
            - 'null'
    PendingReason:
      description: Reason a pre-execution run is pending instead of runnable.
      type: string
      enum:
        - approval_required
    BlockedReason:
      description: Specific reason a run is blocked on external intervention.
      type: string
      enum:
        - human_input_required
    SuccessReason:
      description: Reason attached to a successful terminal run status.
      type: string
      enum:
        - completed
        - partial_success
    FailureReason:
      description: Reason attached to a failed terminal run status.
      type: string
      enum:
        - workflow_error
        - cancelled
        - approval_denied
        - terminated
        - transient_infra
        - budget_exhausted
        - launch_failed
        - bootstrap_failed
        - sandbox_init_failed
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