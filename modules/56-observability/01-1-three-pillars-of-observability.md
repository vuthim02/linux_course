## 1. Three Pillars of Observability

**Metrics (numbers):** CPU utilization, request latency p99, memory usage. Optimized for storage (~2 bytes/sample compressed) and fast querying. Tell you *what* is happening.

```
node_cpu_seconds_total{cpu="0",mode="idle"} 283741.92
```

**Logs (events):** Timestamped text records. Tell you *why* something is happening. High-cardinality, expensive to store at scale.

```json
{"level":"error","time":"2025-06-24T10:31:22Z","msg":"connection refused","host":"db-01"}
```

**Traces (request lifecycle):** End-to-end request path through distributed services. Composed of spans with timing. Tell you *where* latency lives.

```
TraceID: abc123
  ├── frontend: GET /api/users (150ms)
  │   ├── auth: verify_token (12ms)
  │   └── users: query_db (85ms)
```

**How they complement each other:** Metrics show *what* is wrong (p99 spike). Logs show *why* (5xx errors). Traces show *where* (which service call is slow).

**Cardinality:** Number of unique label combinations. `http_requests_total{method,path,status}` with 4 methods × 50 paths × 5 statuses = 1000 series. Add `user_id` (100K) = 100M series — destroys Prometheus. Never use user IDs, IPs, or request IDs as labels.

**vs Traditional Monitoring:** Nagios/Zabbix check-based (OK/WARN/CRIT, no history, no trends). Observability collects everything, stores it, queries ad-hoc. Question changes from "is it up?" to "how is it behaving?"

---



---

[↑ Index](index.md) | [Next →](02-2-prometheus-architecture.md)
