## Steps

1. **ACK** — Acknowledge alert in PagerDuty/OpsGenie
2. **ASSESS** — Open Grafana and check:
   - App dashboard → Latency P50/P95/P99
   - Prometheus → CPU/Memory usage per pod
   - Loki → ERROR-level logs in last 15 minutes
3. **CHECK** database:
   ```
   kubectl exec -it deployment/pgbouncer -n production -- psql -c "SELECT * FROM pg_stat_activity;"
   kubectl exec -it deployment/pgbouncer -n production -- psql -c "SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"
   ```
4. **CHECK** Redis:
   ```
   kubectl exec -it deployment/capstone-api -n production -- redis-cli INFO stats
   ```
5. **SCALE** if needed:
   ```
   kubectl scale deployment/capstone-api -n production --replicas=20
   ```
6. If database is the bottleneck, check RDS metrics in CloudWatch
7. **RESOLVE** — Document root cause and remediation



---

[← Previous](14-symptoms-api-latency-500ms-p99.md) | [↑ Index](index.md) | [Next →](16-resolution-log.md)
