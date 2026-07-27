## Slow Database Queries

### Check active queries
```bash
kubectl exec -it deployment/pgbouncer -n production -- psql -c "SELECT pid, state, query, query_start FROM pg_stat_activity WHERE state != 'idle' ORDER BY query_start;"
```

### Check slow queries
```bash
kubectl exec -it deployment/pgbouncer -n production -- psql -c "SELECT query, calls, total_exec_time, mean_exec_time, rows FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"
```
```

### Cost Breakdown

```markdown
# Cost Breakdown — Monthly Estimated



---

[← Previous](31-high-memory-usage.md) | [↑ Index](index.md) | [Next →](33-infrastructure-costs-aws-us-east-1.md)
