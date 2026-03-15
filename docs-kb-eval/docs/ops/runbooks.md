# Runbooks

Nimbus maintains runbooks for all production alert scenarios. Every alert links to a runbook that provides diagnosis steps, remediation actions, and escalation criteria. Runbooks are living documents updated after each incident.

## Runbook Format

Every runbook follows this structure:

1. **Alert**: Which alert triggers this runbook and what it means
2. **Impact**: What users experience when this condition is active
3. **Diagnosis**: Step-by-step commands to identify the root cause
4. **Remediation**: Actions to resolve the issue, ordered from least to most disruptive
5. **Escalation**: When to escalate and to whom
6. **Prevention**: Long-term fixes to prevent recurrence

## Common Scenarios

### High CPU Usage

**Alert**: `HighCPU` -- CPU usage > 85% for 10 minutes on any application pod.

**Diagnosis**:
```bash
# Check which pods are consuming CPU
kubectl top pods -n nimbus-prod --sort-by=cpu

# Check for runaway queries
kubectl exec -it <pod> -- psql -c "SELECT pid, query, state, wait_event FROM pg_stat_activity WHERE state = 'active' ORDER BY query_start LIMIT 20;"

# Check for recent deployments that may have introduced a regression
kubectl rollout history deployment/nimbus-api -n nimbus-prod
```

**Remediation**:
1. If a single pod is spiking, restart it: `kubectl delete pod <pod-name> -n nimbus-prod`
2. If all pods are high, scale horizontally: `kubectl scale deployment nimbus-api --replicas=8 -n nimbus-prod`
3. If caused by a database query, kill the query: `SELECT pg_cancel_backend(<pid>);`
4. If caused by a recent deploy, roll back: `kubectl rollout undo deployment/nimbus-api -n nimbus-prod`

### Disk Full

**Alert**: `DiskSpaceHigh` -- Disk usage > 85% on any persistent volume.

**Diagnosis**:
```bash
# Check disk usage
kubectl exec -it <pod> -- df -h

# Find large files
kubectl exec -it <pod> -- du -sh /data/* | sort -rh | head -20

# Check log rotation
kubectl exec -it <pod> -- ls -lah /var/log/
```

**Remediation**:
1. Clear application logs older than 7 days: `find /var/log -name "*.log" -mtime +7 -delete`
2. Compact PostgreSQL tables: `VACUUM FULL <table_name>;` (requires maintenance window)
3. Expand the PVC: update the `PersistentVolumeClaim` size in Terraform and apply
4. Archive old data to S3 using the `nimbus-archive` CLI tool

### Connection Pool Exhaustion

**Alert**: `ConnectionPoolExhausted` -- Available database connections < 5.

**Diagnosis**:
```bash
# Check current connections by application
psql -c "SELECT application_name, state, count(*) FROM pg_stat_activity GROUP BY application_name, state ORDER BY count DESC;"

# Check for long-running transactions
psql -c "SELECT pid, now() - xact_start AS duration, query FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC LIMIT 10;"
```

**Remediation**:
1. Kill idle-in-transaction connections older than 5 minutes: `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle in transaction' AND xact_start < now() - interval '5 minutes';`
2. Restart the connection pool (PgBouncer): `kubectl rollout restart deployment/pgbouncer -n nimbus-prod`
3. Increase pool size in PgBouncer config if the load is legitimate

## Automated Remediation

Some scenarios have automated remediation via Kubernetes operators and custom controllers:

| Scenario | Automation |
|----------|-----------|
| Pod OOMKilled | HPA automatically scales up; alert fires if it happens 3+ times in 1 hour |
| Certificate expiring | cert-manager auto-renews; alert fires only if renewal fails |
| Log volume spike | Fluentd rate-limits log shipping; alert fires if rate limit is sustained |
| ETL pipeline failure | Temporal auto-retries; alert fires only after retry exhaustion |

Automated remediation logs all actions to the #ops-automation Slack channel for visibility.

## See Also

- [Alerting](alerting.md) for alert definitions and routing
- [On-Call](on-call.md) for who responds to alerts
- [Postmortems](postmortems.md) for documenting incidents and updating runbooks

<!-- last-verified: 2026-03-15 -->
<!-- verify-when: new alert types are added or remediation procedures change -->
