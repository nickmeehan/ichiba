# Jira Migration

The Jira integration provides a guided import wizard that helps teams migrate their existing Jira projects into Nimbus. It handles field mapping, status translation, attachment transfer, and relationship preservation.

## Import Wizard

The migration process is a multi-step wizard accessible from the workspace settings:

1. **Connect** - Authenticate with Jira Cloud or Server using an API token or OAuth.
2. **Select Projects** - Choose which Jira projects to import.
3. **Map Fields** - Configure how Jira fields translate to Nimbus fields.
4. **Map Statuses** - Map Jira workflow statuses to Nimbus board columns.
5. **Preview** - Review a sample of mapped data before committing.
6. **Import** - Execute the migration as a background job.

## Field Mapping

Standard Jira fields are mapped automatically:

| Jira Field       | Nimbus Field      | Notes                              |
|-----------------|-------------------|------------------------------------|
| Summary         | Title             | Direct mapping                     |
| Description     | Description       | Converted from Jira markup to Markdown |
| Assignee        | Assignee          | Matched by email address           |
| Priority        | Priority          | Mapped: Highest/High -> High, Medium -> Medium, Low/Lowest -> Low |
| Story Points    | Story Points      | Direct mapping                     |
| Sprint          | Sprint            | Sprints are created if they do not exist |
| Epic Link       | Epic              | Epics are created and linked       |
| Labels          | Labels            | Direct mapping                     |

Custom Jira fields can be mapped to Nimbus custom fields through the wizard. Unmapped fields are preserved in a `jira_metadata` JSON column for reference.

## Status Mapping

The wizard presents a drag-and-drop interface for mapping Jira statuses to Nimbus board columns. Common mappings are suggested automatically:

- To Do, Open, Backlog -> To Do
- In Progress, In Development -> In Progress
- In Review, In QA -> In Review
- Done, Closed, Resolved -> Done

## Attachment Migration

Attachments are downloaded from Jira and re-uploaded to Nimbus S3 storage. Large attachments (over 100 MB) are streamed to avoid memory issues. The migration job tracks attachment transfer progress and retries failed downloads up to 3 times.

## Relationship Preservation

Jira issue links (blocks, is blocked by, relates to, duplicates) are preserved as task relationships in Nimbus. Sub-tasks in Jira become subtasks in Nimbus, maintaining the parent-child hierarchy.

## Rollback Support

Each import generates a rollback manifest containing the IDs of all created entities. If the import produces unsatisfactory results, workspace admins can execute a rollback within 48 hours, which deletes all imported data and restores the workspace to its pre-import state.

## See Also

- [Database Migrations](../../database/migrations.md) - Schema changes supporting Jira import fields
- [File Storage](../file-storage.md) - Attachment storage during migration
- [Scheduler](../scheduler.md) - Import job execution

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: Jira API version changes or new field mappings are supported -->
