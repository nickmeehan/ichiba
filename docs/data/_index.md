# Data Documentation

Nimbus manages complex multi-tenant project data spanning tasks, milestones, comments, attachments, and user activity. The data layer handles validation, serialization, caching, event sourcing, and compliance across PostgreSQL, Redis, ClickHouse, and S3. All data operations enforce tenant isolation at every boundary.

## Guides

- **[Data Models](models.md)**
  Use when designing new domain entities, defining relationships between aggregates, or understanding the existing entity graph. Covers domain-driven design patterns, value objects, and domain events.

- **[Data Validation](validation.md)**
  Use when adding validation rules at API boundaries, creating custom validators, or formatting validation errors for API consumers. Covers Zod schema conventions and boundary validation strategy.

- **[Serialization](serialization.md)**
  Use when shaping API responses, handling date or BigInt serialization, or preventing circular reference issues. Covers JSON serialization patterns and response envelope conventions.

- **[Caching Strategies](caching-strategies.md)**
  Use when adding caching to a query path, tuning TTLs, or debugging stale data. Covers cache-aside patterns, write-through caching, invalidation events, and cache warming.

- **[Event Sourcing](event-sourcing.md)**
  Use when working with the event store, building projections, or understanding how eventual consistency affects feature design. Covers event replay, snapshots, and projection patterns.

- **[ETL Pipelines](etl-pipelines.md)**
  Use when building data warehouse sync jobs, adding transformation logic, or troubleshooting pipeline failures. Covers scheduling, error handling, and data quality checks.

- **[Reporting](reporting.md)**
  Use when building analytics dashboards, creating materialized views in ClickHouse, or scheduling report generation. Covers query patterns and data freshness guarantees.

- **[GDPR Compliance](gdpr.md)**
  Use when implementing data subject rights, handling erasure requests, or reviewing consent management. Covers right to erasure, data portability, and DPA requirements.

## See Also

- [Frontend Documentation](../frontend/_index.md)
- [Ops Documentation](../ops/_index.md)

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: new data guide is added or data architecture changes significantly -->
