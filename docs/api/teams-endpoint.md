# Teams Endpoint

The Teams API organizes users into groups for project assignment, permission management, and dashboard access. Teams are workspace-level entities.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/teams` | List teams in the workspace |
| POST | `/v1/teams` | Create a new team |
| GET | `/v1/teams/{id}` | Get team details |
| PATCH | `/v1/teams/{id}` | Update team settings |
| DELETE | `/v1/teams/{id}` | Delete a team |
| GET | `/v1/teams/{id}/members` | List team members |
| POST | `/v1/teams/{id}/members` | Add a member |
| DELETE | `/v1/teams/{id}/members/{user_id}` | Remove a member |

## Creating a Team

```json
POST /v1/teams
{
  "name": "Frontend Engineers",
  "description": "All frontend developers",
  "visibility": "workspace",
  "lead_id": "user_05"
}
```

## Member Management

Add or remove team members. Each member has a team-level role:

```json
POST /v1/teams/team_03/members
{
  "user_id": "user_12",
  "team_role": "member"
}
```

Team roles: `lead`, `member`. The lead can manage team membership and settings.

## Team-Level Permissions

Teams can be granted access to projects as a unit:

```json
POST /v1/projects/proj_01/members
{
  "team_id": "team_03",
  "role": "contributor"
}
```

All team members inherit the project role granted to the team. Individual overrides take precedence over team-level grants.

## Team Dashboards

Each team has an auto-generated dashboard showing:

- Tasks assigned to team members grouped by status
- Sprint progress for sprints the team participates in
- Team velocity and capacity metrics

Access the team dashboard data via:

```
GET /v1/teams/team_03/dashboard
```

## Team Workload

View the team's workload distribution:

```
GET /v1/teams/team_03/workload
```

Returns task counts and time estimates per team member, useful for capacity planning during sprint planning.

## Nested Teams

Teams can have sub-teams for hierarchical organization:

```json
POST /v1/teams
{
  "name": "React Team",
  "parent_team_id": "team_03"
}
```

Sub-teams inherit the parent team's project access by default.

## See Also

- [Users Endpoint](users-endpoint.md) — individual user management
- [Roles Endpoint](roles-endpoint.md) — role-based access
- [Projects Endpoint](projects-endpoint.md) — project membership
- [Sprints Endpoint](sprints-endpoint.md) — team sprint participation
- [Dashboards Endpoint](dashboards-endpoint.md) — custom dashboards

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: team membership model, nested teams, or dashboard features change -->
