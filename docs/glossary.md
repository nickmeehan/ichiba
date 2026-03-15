# Glossary

This document defines the core domain terms used throughout the Nimbus platform. Understanding these concepts is essential for working with the codebase and communicating with product stakeholders.

## Core Entities

### Workspace
A top-level organizational unit representing a single tenant. Each workspace has its own set of users, projects, and billing. All data is isolated by `tenant_id`, which maps to the workspace.

### Project
A collection of related work within a workspace. Projects contain boards, sprints, and a backlog. Each project has its own set of members, which may be a subset of the workspace membership.

### Board
A visual representation of a workflow within a project. Boards consist of configurable columns (e.g., To Do, In Progress, Done) and display tasks as cards. A project can have multiple boards for different views of the same data.

### Sprint
A time-boxed iteration, typically one or two weeks long. Sprints belong to a project and contain a selected subset of tasks from the backlog. Sprint velocity and burndown metrics are computed from completed story points.

### Epic
A large body of work that spans multiple sprints. Epics group related stories and provide high-level progress tracking. They have a start date, target date, and a progress percentage derived from child completion.

### Story
A user-facing requirement described from the perspective of an end user. Stories belong to an epic (optionally) and are estimated with story points. They represent deliverable increments of functionality.

### Task
The fundamental unit of work in Nimbus. Tasks have a title, description, assignee, status, priority, and optional story-point estimate. Tasks can be standalone or belong to a story.

### Subtask
A granular checklist item within a task. Subtasks have a title and a completion state. They are used to break a task into smaller actionable steps without creating separate task records.

## Configuration Entities

### Custom Field
A user-defined field that can be attached to tasks within a project. Supported types include text, number, date, single-select, multi-select, and user reference. Custom fields are scoped to a project.

### Automation Rule
A trigger-action pair that automates repetitive workflows. Triggers include status changes, field updates, and time-based conditions. Actions include assigning users, moving tasks, sending notifications, and calling webhooks.

## Integration and Access Entities

### Webhook
An HTTP callback registered by an external system. When a subscribed event occurs in Nimbus, the platform sends a signed JSON payload to the webhook URL. Delivery is retried with exponential backoff on failure.

### API Key
A long-lived credential used by external systems or scripts to authenticate with the Nimbus API. API keys are scoped to a workspace and can be restricted to specific permission sets.

### RBAC Role
A named set of permissions assigned to a user within a workspace. The built-in roles are Owner, Admin, Member, and Guest. Custom roles can be created by workspace administrators to fine-tune access control.

## See Also

- [Project Overview](./project-overview.md) - System architecture and technology stack
- [Database Schema](./architecture/database/schema.md) - How these entities map to database tables
- [Auth Service](./architecture/services/auth.md) - RBAC role implementation details

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: New domain entities are added or existing entity definitions change -->
