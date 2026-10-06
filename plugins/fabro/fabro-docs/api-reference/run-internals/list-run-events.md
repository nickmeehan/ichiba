> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# List Run Events

> Returns one page of the run's stream (`PaginatedRunStreamList`):
one ordered delivery of Petri's own `RunEvent`s and Fabro's platform
records in the `RunStreamItem` envelope, in `stream_seq` order. The
cursor is `after`: the last `stream_seq` the client saw, exclusive;
the first page is `after=0`. A client that reconnects resumes from
its last `stream_seq` and deduplicates by each item's `id`; every
item is delivered once, in order, with no gap.




## OpenAPI

````yaml /api-reference/fabro-api.yaml get /api/v1/runs/{id}/events
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
  - name: Usage
    description: Token counts and costs
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
      description: |
        Returns one page of the run's stream (`PaginatedRunStreamList`):
        one ordered delivery of Petri's own `RunEvent`s and Fabro's platform
        records in the `RunStreamItem` envelope, in `stream_seq` order. The
        cursor is `after`: the last `stream_seq` the client saw, exclusive;
        the first page is `after=0`. A client that reconnects resumes from
        its last `stream_seq` and deduplicates by each item's `id`; every
        item is delivered once, in order, with no gap.
      operationId: listRunEvents
      parameters:
        - $ref: '#/components/parameters/RunId'
        - $ref: '#/components/parameters/EventLimit'
        - $ref: '#/components/parameters/StreamAfter'
      responses:
        '200':
          description: One page of the run's stream
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PaginatedRunStreamList'
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
    StreamAfter:
      name: after
      in: query
      required: false
      description: |
        Run stream cursor for a Petri run: the last `stream_seq` the client
        saw, exclusive. `0` starts at the first item.
      schema:
        type: integer
        format: uint64
        minimum: 0
        default: 0
      example: 42
  schemas:
    PaginatedRunStreamList:
      description: |
        One page of a Petri run's stream, in `stream_seq` order.
        `event_contract_version` is Petri's `EVENT_CONTRACT_VERSION` the
        server was built against: the version of the event contract every
        `petri` item follows.
      type: object
      required:
        - data
        - meta
        - event_contract_version
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/RunStreamItem'
        meta:
          $ref: '#/components/schemas/PaginationMeta'
        event_contract_version:
          type: integer
          format: uint32
          minimum: 0
          example: 3
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
    RunStreamItem:
      description: |
        One item of a Petri run's stream: a Petri `RunEvent` or a Fabro
        platform record in Fabro's envelope.

        `stream_seq` is the durable per-run delivery sequence the projector
        assigned when the item's record was committed: dense, strictly
        increasing within the run, and the cursor for `after`. `id` is the
        item's own identity, kept beside the cursor so a client deduplicates
        by it: for a Petri event the `EventId` as `<log>/<seq>/<index>`
        (`coordinator/3/0`, `execution 1/23/0`); for a platform record its
        `seq`. Petri's `EventId` is per log and has no platform variant, so
        it is never the cursor.

        A `petri` item is a Petri `RunEvent` passed through unchanged:
        `{id: {log, execution?, seq, index}, origin, recorded_at,
        observed_at?, context: {invocation, execution, parent?}, subject?,
        record?, derived?}`. Its vocabulary is Petri's public event contract
        (`crates/core/execution/EVENTS.md` in the Petri repository), not
        Fabro's: the recorded event's name is `record.body.event`
        (`<subject>.<verb>`, e.g. `visit.started`, `step.finished`,
        `run.finished`), a derived view event's is `derived.event`, and the
        stage a subject names is `(context.execution, subject.firing)` with
        `subject.node.name` and `subject.visit` as its display label. The
        server reports the contract version it serves in
        `PaginatedRunStreamList.event_contract_version`.

        A `platform` item is a stored platform record: `{seq, recorded_at,
        record: {kind, ...}, position?: {execution, firing}}`. `record.kind`
        is one of `run.created`, `run.lifecycle`, `run.title`, `run.parent`,
        `run.archived`, `run.unarchived`, `run.superseded`, `run.notice`,
        `interview.answered`, `run.branch`, `git.identity`, `checkpoint`,
        `pull_request.created`, `notification.sent`, `run.paired`.
      type: object
      required:
        - run_id
        - stream_seq
        - kind
        - id
        - recorded_at
        - item
      properties:
        run_id:
          type: string
        stream_seq:
          type: integer
          format: uint64
          minimum: 0
          description: The delivery sequence; the cursor.
        kind:
          $ref: '#/components/schemas/RunStreamItemKind'
        id:
          type: string
          description: The item's own identity, for deduplication.
        recorded_at:
          type: integer
          format: uint64
          minimum: 0
          description: >-
            Milliseconds since the Unix epoch when the item's record was
            appended.
        item:
          type: object
          additionalProperties: true
          description: The Petri `RunEvent` or the stored platform record, unchanged.
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
        meta:
          type: object
          additionalProperties: true
          description: >-
            Optional structured details specific to the error `code`, for
            clients that act on them. Each code documents the members it sets.
    RunStreamItemKind:
      description: Which item shape a run stream item carries.
      type: string
      enum:
        - petri
        - platform
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

This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.